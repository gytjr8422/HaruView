//
//  EventKitRepository+Event.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import EventKit

// MARK: - 일정 관련
extension EventKitRepository {
    // MARK: - 캘린더 Repository
    func fetchEvent() async -> Result<[Event], TodayBoardError> {
        let windowStart = cal.startOfDay(for: Date())
        let windowEnd = cal.date(byAdding: .day, value: 1, to: windowStart)!
        
        let wideStart = cal.date(byAdding: .day, value: -7, to: windowStart)!
        let wideEnd = cal.date(byAdding: .day, value: 7, to: windowEnd)!
        
        let ekResult = service.fetchEventsBetween(wideStart, wideEnd)
        return ekResult.map { events in
            events
                .filter { $0.endDate > windowStart && $0.startDate < windowEnd && $0.calendar.title != "대한민국 공휴일"}
                .map(Self.mapEvent) // 확장된 매핑 함수 사용
                .sorted(by: eventSortRule)
        }
    }

    func add(_ input: EventInput) async -> Result<Void, TodayBoardError> {
        service.save(input)
    }
    
    func update(_ edit: EventEdit) async -> Result<Void, TodayBoardError> {
        service.update(edit)
    }
    
    func deleteEvent(id: String) async -> Result<Void, TodayBoardError> {
        service.deleteEvent(id: id)
    }
    
    func deleteEvent(id: String, span: EventDeletionSpan) async -> Result<Void, TodayBoardError> {
        return service.deleteEvent(id: id, span: span)
    }
    
    /// 종료된 일정은 뒤, 그 외는 시작 시각 오름차순
    private func eventSortRule(_ a: Event, _ b: Event) -> Bool {
        let now = Date()
        let aPast = a.end < now
        let bPast = b.end < now
        if aPast != bPast { return !aPast }
        return a.start < b.start
    }
    
    
    // MARK: - 사용 가능한 캘린더 조회
    func getAvailableCalendars() -> [EventCalendar] {
        let calendars = service.getAvailableCalendars()
        return calendars
            .filter { $0.allowsContentModifications } // 편집 가능한 캘린더만
            .map(Self.mapCalendar)
    }
}

// MARK: - 일정 매핑 관련
extension EventKitRepository {
    // MARK: - 확장된 Event 매핑 함수
    private static func mapEvent(_ ek: EKEvent) -> Event {
        Event(
            id: ek.eventIdentifier,
            title: ek.title ?? "(제목 없음)",
            start: ek.startDate,
            end: ek.endDate,
            calendarTitle: ek.calendar.title,
            calendarColor: ek.calendar.cgColor,
            location: ek.location,
            notes: ek.notes,
            
            // 새로 추가된 필드들
            url: ek.url,
            hasAlarms: !(ek.alarms?.isEmpty ?? true),
            alarms: mapAlarms(ek.alarms ?? []),
            hasRecurrence: ek.hasRecurrenceRules,
            recurrenceRule: mapRecurrenceRule(ek.recurrenceRules?.first),
            calendar: mapCalendar(ek.calendar),
            structuredLocation: mapStructuredLocation(ek.structuredLocation)
        )
    }
    
    // MARK: - 알람 매핑
    private static func mapAlarms(_ ekAlarms: [EKAlarm]) -> [EventAlarm] {
        return ekAlarms.map { alarm in
            let type: EventAlarm.AlarmType = .display // EKAlarm 타입이 직접 노출되지 않으므로 기본값
            
            return EventAlarm(
                relativeOffset: alarm.relativeOffset,
                absoluteDate: alarm.absoluteDate,
                type: type
            )
        }
    }
    
    // MARK: - 반복 규칙 매핑
    private static func mapRecurrenceRule(_ ekRule: EKRecurrenceRule?) -> EventRecurrenceRule? {
        guard let ekRule = ekRule else { return nil }
        
        let frequency: EventRecurrenceRule.RecurrenceFrequency
        switch ekRule.frequency {
        case .daily:
            frequency = .daily
        case .weekly:
            frequency = .weekly
        case .monthly:
            frequency = .monthly
        case .yearly:
            frequency = .yearly
        @unknown default:
            frequency = .daily
        }
        
        let endDate = ekRule.recurrenceEnd?.endDate
        let occurrenceCount = ekRule.recurrenceEnd?.occurrenceCount
        
        let daysOfWeek = ekRule.daysOfTheWeek?.map { ekDay in
            // EKWeekday를 Int로 안전하게 변환
            let dayNumber: Int
            switch ekDay.dayOfTheWeek {
            case .sunday: dayNumber = 1
            case .monday: dayNumber = 2
            case .tuesday: dayNumber = 3
            case .wednesday: dayNumber = 4
            case .thursday: dayNumber = 5
            case .friday: dayNumber = 6
            case .saturday: dayNumber = 7
            @unknown default: dayNumber = 1
            }
            
            return EventRecurrenceRule.RecurrenceWeekday(
                dayOfWeek: dayNumber,
                weekNumber: ekDay.weekNumber == 0 ? nil : ekDay.weekNumber
            )
        }
        
        let daysOfMonth = ekRule.daysOfTheMonth?.map { $0.intValue }
        let weeksOfYear = ekRule.weeksOfTheYear?.map { $0.intValue }
        let monthsOfYear = ekRule.monthsOfTheYear?.map { $0.intValue }
        let setPositions = ekRule.setPositions?.map { $0.intValue }
        
        return EventRecurrenceRule(
            frequency: frequency,
            interval: ekRule.interval,
            endDate: endDate,
            occurrenceCount: occurrenceCount == 0 ? nil : occurrenceCount,
            daysOfWeek: daysOfWeek,
            daysOfMonth: daysOfMonth,
            weeksOfYear: weeksOfYear,
            monthsOfYear: monthsOfYear,
            setPositions: setPositions
        )
    }
    
    // MARK: - 캘린더 매핑
    private static func mapCalendar(_ ekCalendar: EKCalendar) -> EventCalendar {
        let calendarType: EventCalendar.CalendarType
        switch ekCalendar.type {
        case .local:
            calendarType = .local
        case .calDAV:
            calendarType = .calDAV
        case .exchange:
            calendarType = .exchange
        case .subscription:
            calendarType = .subscription
        case .birthday:
            calendarType = .birthday
        @unknown default:
            calendarType = .local
        }
        
        let sourceType: EventCalendar.CalendarSource.SourceType
        switch ekCalendar.source.sourceType {
        case .local:
            sourceType = .local
        case .exchange:
            sourceType = .exchange
        case .calDAV:
            sourceType = .calDAV
        case .mobileMe:
            sourceType = .mobileMe
        case .subscribed:
            sourceType = .subscribed
        case .birthdays:
            sourceType = .birthdays
        @unknown default:
            sourceType = .local
        }
        
        return EventCalendar(
            id: ekCalendar.calendarIdentifier,
            title: ekCalendar.title,
            color: ekCalendar.cgColor,
            type: calendarType,
            isReadOnly: !ekCalendar.allowsContentModifications,
            allowsContentModifications: ekCalendar.allowsContentModifications,
            source: EventCalendar.CalendarSource(
                title: ekCalendar.source.title,
                type: sourceType
            )
        )
    }
    
    // MARK: - 구조화된 위치 매핑
    private static func mapStructuredLocation(_ ekLocation: EKStructuredLocation?) -> EventStructuredLocation? {
        guard let ekLocation = ekLocation else { return nil }
        
        let geoLocation: EventStructuredLocation.GeoLocation?
        if let location = ekLocation.geoLocation {
            geoLocation = EventStructuredLocation.GeoLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        } else {
            geoLocation = nil
        }
        
        return EventStructuredLocation(
            title: ekLocation.title,
            geoLocation: geoLocation,
            radius: ekLocation.radius
        )
    }
}
