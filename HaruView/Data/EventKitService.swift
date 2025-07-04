//
//  EventKitService.swift
//  HaruView
//
//  Created by 김효석 on 5/1/25.
//

import Foundation
import EventKit
import Combine
import WidgetKit

final class EventKitService {
    private let store = EKEventStore()
    
    // MARK: - 캘린더, 미리알림 권한 요청
    enum AccessMode { case writeOnly, full }
    
    func requestAccess(_ mode: AccessMode) async -> Result<Void, TodayBoardError> {
        do {
            switch mode {
            case .writeOnly:
                try await store.requestWriteOnlyAccessToEvents()
                try await store.requestFullAccessToReminders()
            case .full:
                try await store.requestFullAccessToEvents()
                try await store.requestFullAccessToReminders()
            }
            return .success(())
        } catch {
            print("Permission request failed: \(error)")
            return .failure(.accessDenied)
        }
    }
    
    // MARK: - 데이터 fetch
    func fetchEventsBetween(_ start: Date, _ end: Date) -> Result<[EKEvent], TodayBoardError> {
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return .success(store.events(matching: predicate))
    }
    
    // MARK: 리마인더 조회 (완료+미완료 모두)
    func fetchRemindersBetween(_ start: Date, _ end: Date) async -> Result<[EKReminder], TodayBoardError> {
        // Apple API: dueDateStarting=nil, ending=nil ⇒ 모든 dueDate & dueDate nil 포함
        let incPred = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        let cmpPred = store.predicateForCompletedReminders(withCompletionDateStarting: nil, ending: nil, calendars: nil)

        return await withCheckedContinuation { cont in
            var bucket: [EKReminder] = []
            store.fetchReminders(matching: incPred) { inc in
                bucket.append(contentsOf: inc ?? [])
                self.store.fetchReminders(matching: cmpPred) { comp in
                    bucket.append(contentsOf: comp ?? [])
                    // 오늘과 겹치는지 after‑filter
                    let filtered = bucket.filter { rem in
                        guard let due = rem.dueDateComponents?.date else { return true }
                        return due >= start && due < end
                    }
                    cont.resume(returning: .success(filtered))
                }
            }
        }
    }
    
    func deleteEvent(id: String) -> Result<Void, TodayBoardError> {
        return deleteEvent(id: id, span: .thisEventOnly)
    }
    
    /// 반복 일정 삭제 옵션을 포함한 이벤트 삭제
    func deleteEvent(id: String, span: EventDeletionSpan) -> Result<Void, TodayBoardError> {
        guard let event = store.event(withIdentifier: id) else {
            return .failure(.notFound)
        }
        
        do {
            try store.remove(event, span: span.ekSpan, commit: true)
            Task { @MainActor in
                WidgetRefreshService.shared.forceRefresh()
            }
            return .success(())
        } catch {
            return .failure(.saveFailed)
        }
    }
    
    // MARK: - 미리알림 CRUD
    func addReminder(_ input: ReminderInput) -> Result<Void, TodayBoardError> {
        let reminder = EKReminder(eventStore: store)
        applyReminderInput(input, to: reminder)
        
        do {
            try store.save(reminder, commit: true)
            Task { @MainActor in
                WidgetRefreshService.shared.refreshWithDebounce()
            }
            return .success(())
        } catch {
            return .failure(.saveFailed)
        }
    }
    
    func updateReminder(_ edit: ReminderEdit) -> Result<Void, TodayBoardError> {
        guard let reminder = store.calendarItem(withIdentifier: edit.id) as? EKReminder else {
            return .failure(.notFound)
        }
        
        applyReminderEdit(edit, to: reminder)
        
        do {
            try store.save(reminder, commit: true)
            Task { @MainActor in
                WidgetRefreshService.shared.refreshWithDebounce()
            }
            return .success(())
        } catch {
            return .failure(.saveFailed)
        }
    }
    
    // MARK: - 사용 가능한 리마인더 캘린더 조회
    func getAvailableReminderCalendars() -> [EKCalendar] {
        return store.calendars(for: .reminder)
    }
    
    private func applyReminderInput(_ input: ReminderInput, to reminder: EKReminder) {
        reminder.title = input.title
        reminder.notes = input.notes
        reminder.url = input.url
        reminder.location = input.location
        reminder.priority = input.priority
        
        // 마감일 설정
        reminder.dueDateComponents = nil
        if let due = input.due {
            if input.includesTime {
                reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
            } else {
                reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: due)
            }
        }
        
        // 캘린더 설정
        if let calendarId = input.calendarId,
           let calendar = store.calendar(withIdentifier: calendarId) {
            reminder.calendar = calendar
        } else {
            reminder.calendar = store.defaultCalendarForNewReminders()
        }
        
        // 알람 설정
        applyAlarmsToReminder(input.alarms, to: reminder)
    }
    
    private func applyReminderEdit(_ edit: ReminderEdit, to reminder: EKReminder) {
        reminder.title = edit.title
        reminder.notes = edit.notes
        reminder.url = edit.url
        reminder.location = edit.location
        reminder.priority = edit.priority
        
        // 마감일 설정
        reminder.dueDateComponents = nil
        if let due = edit.due {
            if edit.includesTime {
                reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
            } else {
                reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: due)
            }
        }
        
        // 알람 설정 (기존 알람 제거 후 새로 추가)
        applyAlarmsToReminder(edit.alarms, to: reminder)
    }
    
    private func applyAlarmsToReminder(_ alarms: [AlarmInput], to reminder: EKReminder) {
        // 기존 알람 제거
        if let existingAlarms = reminder.alarms {
            for alarm in existingAlarms {
                reminder.removeAlarm(alarm)
            }
        }
        
        // 새 알람 추가
        for alarmInput in alarms {
            let alarm = EKAlarm()
            
            switch alarmInput.trigger {
            case .relative(let interval):
                alarm.relativeOffset = interval
            case .absolute(let date):
                alarm.absoluteDate = date
            }
            
            reminder.addAlarm(alarm)
        }
    }
    
    func toggleReminder(id: String) -> Result<Void, TodayBoardError> {
        guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
            return .failure(.notFound)
        }
        reminder.isCompleted.toggle()
        do {
            try store.save(reminder, commit: true)
            // 위젯 새로고침
            Task { @MainActor in
                WidgetRefreshService.shared.refreshWithDebounce()
            }
            return .success(())
        } catch {
            return .failure(.saveFailed)
        }
    }
    
    func deleteReminder(id: String) -> Result<Void, TodayBoardError> {
        guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
            return .failure(.notFound)
        }
        do {
            try store.remove(reminder, commit: true)
            // 위젯 새로고침
            Task { @MainActor in
                WidgetRefreshService.shared.refreshWithDebounce()
            }
            return .success(())
        } catch {
            return .failure(.saveFailed)
        }
    }
}

extension EventKitService {
    /// 시스템 EventKit 변경 알림을 Combine 스트림으로 노출
    var changePublisher: AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: .EKEventStoreChanged)   // Reminders 변경도 포함
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}


extension EventKitService {
    
    // MARK: - 캘린더 관련 메서드
    func getAvailableCalendars() -> [EKCalendar] {
        return store.calendars(for: .event)
    }
    
    // 기존 확장된 저장/업데이트 메서드들...
    func save(_ input: EventInput) -> Result<Void, TodayBoardError> {
        let event = EKEvent(eventStore: store)
        applyEventInput(input, to: event)
        
        do {
            try store.save(event, span: .thisEvent)
            Task { @MainActor in
                WidgetRefreshService.shared.forceRefresh()
            }
            return .success(())
        } catch {
            return .failure(.saveFailed)
        }
    }
    
    func update(_ edit: EventEdit) -> Result<Void, TodayBoardError> {
        guard let event = store.event(withIdentifier: edit.id) else {
            return .failure(.notFound)
        }
        
        applyEventEdit(edit, to: event)
        
        do {
            try store.save(event, span: .thisEvent)
            Task { @MainActor in
                WidgetRefreshService.shared.forceRefresh()
            }
            return .success(())
        } catch {
            return .failure(.saveFailed)
        }
    }
    
    // MARK: - Helper 메서드들
    private func applyEventInput(_ input: EventInput, to event: EKEvent) {
        event.title = input.title
        event.startDate = input.start
        event.endDate = input.end
        event.location = input.location
        event.notes = input.notes
        event.url = input.url
        
        // 캘린더 설정
        if let calendarId = input.calendarId,
           let calendar = store.calendar(withIdentifier: calendarId) {
            event.calendar = calendar
        } else {
            event.calendar = store.defaultCalendarForNewEvents
        }
        
        // 알람 설정
        applyAlarms(input.alarms, to: event)
        
        // 반복 규칙 설정
        if let recurrenceRule = input.recurrenceRule {
            applyRecurrenceRule(recurrenceRule, to: event)
        }
    }
    
    private func applyEventEdit(_ edit: EventEdit, to event: EKEvent) {
        event.title = edit.title
        event.startDate = edit.start
        event.endDate = edit.end
        event.location = edit.location
        event.notes = edit.notes
        event.url = edit.url
        
        // 알람 설정 (기존 알람 제거 후 새로 추가)
        applyAlarms(edit.alarms, to: event)
        
        // 반복 규칙 설정 (기존 규칙 제거 후 새로 추가)
        if let recurrenceRule = edit.recurrenceRule {
            applyRecurrenceRule(recurrenceRule, to: event)
        } else {
            // 반복 규칙 제거
            if let existingRules = event.recurrenceRules {
                for rule in existingRules {
                    event.removeRecurrenceRule(rule)
                }
            }
        }
    }
    
    private func applyAlarms(_ alarms: [AlarmInput], to event: EKEvent) {
        // 기존 알람 제거
        if let existingAlarms = event.alarms {
            for alarm in existingAlarms {
                event.removeAlarm(alarm)
            }
        }
        
        // 새 알람 추가
        for alarmInput in alarms {
            let alarm = EKAlarm()
            
            switch alarmInput.trigger {
            case .relative(let interval):
                alarm.relativeOffset = interval
            case .absolute(let date):
                alarm.absoluteDate = date
            }
            
            event.addAlarm(alarm)
        }
    }
    
    private func applyRecurrenceRule(_ recurrenceInput: RecurrenceRuleInput, to event: EKEvent) {
        // 기존 반복 규칙 제거
        if let existingRules = event.recurrenceRules {
            for rule in existingRules {
                event.removeRecurrenceRule(rule)
            }
        }
        
        // 새 반복 규칙 추가
        let ekRule = recurrenceInput.toEKRecurrenceRule()
        event.addRecurrenceRule(ekRule)
    }
}
