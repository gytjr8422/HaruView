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
    
    // MARK: - 캘린더 CRUD
    func save(_ input: EventInput) -> Result<Void, TodayBoardError> {
        let event = EKEvent(eventStore: store)
        event.title = input.title
        event.startDate = input.start
        event.endDate = input.end
        event.calendar = store.defaultCalendarForNewEvents
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
        guard let event = store.event(withIdentifier: edit.id) else { return .failure(.notFound) }
        event.title = edit.title
        event.startDate = edit.start
        event.endDate = edit.end
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
    
    func deleteEvent(id: String) -> Result<Void, TodayBoardError> {
        guard let event = store.event(withIdentifier: id) else { return .failure(.notFound) }
        do {
            try store.remove(event, span: .thisEvent, commit: true)
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
        reminder.title = input.title
        if let due = input.due {
            if input.includesTime {
                reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
            } else {
                reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: due)
            }
        }
        reminder.calendar = store.defaultCalendarForNewReminders()
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

    func updateReminder(_ edit: ReminderEdit) -> Result<Void, TodayBoardError> {
        guard let reminder = store.calendarItem(withIdentifier: edit.id) as? EKReminder else {
            return .failure(.notFound)
        }
        reminder.title = edit.title
        reminder.dueDateComponents = nil
        if let due = edit.due {
            if edit.includesTime {
                reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
            } else {
                reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: due)
            }
        }
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
