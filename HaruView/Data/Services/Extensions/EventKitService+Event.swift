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
    
    /// 특정 날짜의 반복 일정 인스턴스 삭제 (새로운 메서드)
    func deleteRecurringEventInstance(
        eventId: String,
        targetDate: Date,
        span: EventDeletionSpan
    ) -> Result<Void, TodayBoardError> {
        
        // 1. 먼저 원본 이벤트 조회
        guard let originalEvent = store.event(withIdentifier: eventId) else {
            return .failure(.notFound)
        }
        
        // 2. 반복 일정이 아닌 경우 기본 삭제
        guard originalEvent.hasRecurrenceRules else {
            return deleteEvent(id: eventId, span: span)
        }
        
        // 3. 특정 날짜 범위에서 이벤트 검색
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: targetDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        let predicate = store.predicateForEvents(
            withStart: dayStart,
            end: dayEnd,
            calendars: nil
        )
        
        let eventsOnDate = store.events(matching: predicate)
        
        // 4. 동일한 eventIdentifier와 시작 시간이 일치하는 이벤트 찾기
        let targetEvent = eventsOnDate.first { event in
            event.eventIdentifier == eventId &&
            calendar.isDate(event.startDate, inSameDayAs: targetDate)
        }
        
        guard let eventToDelete = targetEvent else {
            return .failure(.notFound)
        }
        
        do {
            try store.remove(eventToDelete, span: span.ekSpan, commit: true)
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
        
        // 반복 일정 편집 시 특별 처리
        if event.hasRecurrenceRules {
            return updateRecurringEvent(edit, originalEvent: event)
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
    
    private func updateRecurringEvent(_ edit: EventEdit, originalEvent: EKEvent) -> Result<Void, TodayBoardError> {
        let span: EKSpan = edit.editSpan.ekSpan
        
        do {
            if span == .thisEvent {
                // 이 이벤트만 편집: 단순히 thisEvent span 사용
                // EventKit이 자동으로 예외 처리를 해줌
                applyEventEditForRecurring(edit, to: originalEvent)
                try store.save(originalEvent, span: .thisEvent)
                
            } else {
                // 이후 모든 이벤트 편집: futureEvents span 사용
                applyEventEditForRecurring(edit, to: originalEvent)
                try store.save(originalEvent, span: .futureEvents)
            }
            
            Task { @MainActor in
                WidgetRefreshService.shared.forceRefresh()
            }
            return .success(())
            
        } catch {
            print("DEBUG: 반복 일정 편집 오류: \(error)")
            return .failure(.saveFailed)
        }
    }
    
    private func applyEventEditForRecurring(_ edit: EventEdit, to event: EKEvent) {
        event.title = edit.title
        event.startDate = edit.start
        event.endDate = edit.end
        event.location = edit.location
        event.notes = edit.notes
        event.url = edit.url
        
        // 캘린더 설정
        if let calendarId = edit.calendarId,
           let calendar = store.calendar(withIdentifier: calendarId) {
            event.calendar = calendar
        }
        
        // 알람 설정 (기존 알람 제거 후 새로 추가)
        applyAlarms(edit.alarms, to: event)
        
        // 반복 규칙은 편집하지 않음 (EventKit 제한 때문)
        // 반복 규칙 변경이 필요한 경우 별도 처리 필요
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
        
        // 캘린더 설정
        if let calendarId = edit.calendarId,
           let calendar = store.calendar(withIdentifier: calendarId) {
            event.calendar = calendar
        }
        
        // 알람 설정 (기존 알람 제거 후 새로 추가)
        applyAlarms(edit.alarms, to: event)
        
        // 반복 규칙 설정 - 기존 반복 일정의 경우 조건부 처리
        let hasExistingRecurrence = event.hasRecurrenceRules
        let newRecurrenceRule = edit.recurrenceRule
        
        if hasExistingRecurrence && newRecurrenceRule != nil {
            // 기존 반복 일정에 새 반복 규칙 적용 시도
            // 일부 변경은 허용되지 않을 수 있으므로 조건부 처리
            if let existingRules = event.recurrenceRules {
                for rule in existingRules {
                    event.removeRecurrenceRule(rule)
                }
            }
            applyRecurrenceRule(newRecurrenceRule!, to: event)
        } else if !hasExistingRecurrence && newRecurrenceRule != nil {
            // 새로운 반복 규칙 추가
            applyRecurrenceRule(newRecurrenceRule!, to: event)
        } else if hasExistingRecurrence && newRecurrenceRule == nil {
            // 기존 반복 규칙 제거
            if let existingRules = event.recurrenceRules {
                for rule in existingRules {
                    event.removeRecurrenceRule(rule)
                }
            }
        }
        // hasExistingRecurrence가 false이고 newRecurrenceRule이 nil인 경우는 아무것도 하지 않음
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
