//
//  EventKitService+Event.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import EventKit

extension EventKitService {
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
