//
//  EventKitRepository+Reminder.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import EventKit

// MARK: - 할 일 관련
extension EventKitRepository {
    
    // MARK: - ReminderRepository Protocol 구현
    func fetchReminder() async -> Result<[Reminder], TodayBoardError> {
        
        let todayStart = cal.startOfDay(for: Date())
        let todayEnd = cal.date(byAdding: .day, value: 1, to: todayStart)!
        // service에서 모든 리마인더를 반환하므로 범위는 의미없지만 API 호환성을 위해 유지
        let ekRes = await service.fetchRemindersBetween(todayStart, todayEnd)
        return ekRes.map { rems in
            
            let mappedReminders = rems
                .sorted(by: Self.sortRule)
                .map(Self.mapReminder)
            
            // 새로운 필터링 로직: ReminderType에 따른 표시 여부 결정
            let filtered = mappedReminders.filter { reminder in
                // 마감일이 없으면 항상 표시 (기존 동작 유지)
                guard reminder.due != nil else { return true }
                
                // shouldDisplay 메서드를 사용하여 오늘 표시 여부 결정
                return reminder.shouldDisplay(on: Date())
            }
            
            return filtered
        }
    }
    
    func add(_ input: ReminderInput) async -> Result<Void, TodayBoardError> {
        return service.addReminder(input)
    }

    func update(_ edit: ReminderEdit) async -> Result<Void, TodayBoardError> {
        return service.updateReminder(edit)
    }
    
    func toggle(id: String) async -> Result<Void, TodayBoardError> {
        return service.toggleReminder(id: id)
    }
    
    func deleteReminder(id: String) async -> Result<Void, TodayBoardError> {
        return service.deleteReminder(id: id)
    }
    
    // MARK: - 사용 가능한 리마인더 캘린더 조회
    func getAvailableReminderCalendars() -> [ReminderCalendar] {
        let calendars = service.getAvailableReminderCalendars()
        return calendars
            .filter { $0.allowsContentModifications } // 편집 가능한 캘린더만
            .map(Self.mapReminderCalendar)
    }
    
    // MARK: - 정렬 규칙
    static func sortRule(lhs: EKReminder, rhs: EKReminder) -> Bool {
        // 1. 완료 상태: 미완료가 먼저
        if lhs.isCompleted != rhs.isCompleted {
            return !lhs.isCompleted
        }
        
        // 2. 우선순위: 낮은 숫자(높은 우선순위)가 먼저
        let lhsPriority = lhs.priority == 0 ? Int.max : lhs.priority
        let rhsPriority = rhs.priority == 0 ? Int.max : rhs.priority

        if lhsPriority != rhsPriority {
            return lhsPriority < rhsPriority
        }
        
        // 3. 시간 설정 여부: 시간이 설정된 것이 먼저
        let lhsHasTime = lhs.dueDateComponents?.hour != nil || lhs.dueDateComponents?.minute != nil
        let rhsHasTime = rhs.dueDateComponents?.hour != nil || rhs.dueDateComponents?.minute != nil
        
        if lhsHasTime != rhsHasTime {
            return lhsHasTime
        }
        
        // 4. 마감일: 빠른 마감일이 먼저
        let lDue = lhs.dueDateComponents?.date ?? .distantFuture
        let rDue = rhs.dueDateComponents?.date ?? .distantFuture
        if lDue != rDue {
            return lDue < rDue
        }

        // 5. 제목: 알파벳 순
        return lhs.title < rhs.title
    }
}

// MARK: - 미리알림 매핑 관련
extension EventKitRepository {
    
    // MARK: - Reminder 매핑 함수
    static func mapReminder(_ rem: EKReminder) -> Reminder {
        // 마감일 처리 로직 개선
        let due: Date?
        
        if let dueDateComponents = rem.dueDateComponents {
            // 시간이 설정된 경우와 날짜만 설정된 경우 구분
            let hasTime = dueDateComponents.hour != nil || dueDateComponents.minute != nil
            
            if hasTime {
                // 시간이 있는 경우 그대로 사용
                due = dueDateComponents.date
            } else {
                // 날짜만 있는 경우 해당 날짜의 시작 시간으로 설정
                if let originalDate = dueDateComponents.date {
                    due = Calendar.current.startOfDay(for: originalDate)
                } else {
                    due = nil
                }
            }
        } else {
            due = nil
        }
        
        return Reminder(
            id: rem.calendarItemIdentifier,
            title: rem.title ?? "(제목 없음)",
            due: due,
            isCompleted: rem.isCompleted,
            priority: rem.priority,
            notes: rem.notes,
            url: rem.url,
            location: rem.location,
            hasAlarms: !(rem.alarms?.isEmpty ?? true),
            alarms: mapReminderAlarms(rem.alarms ?? []),
            calendar: mapReminderCalendar(rem.calendar)
        )
    }
    
    // MARK: - 리마인더 알람 매핑
    private static func mapReminderAlarms(_ ekAlarms: [EKAlarm]) -> [ReminderAlarm] {
        return ekAlarms.map { alarm in
            let type: ReminderAlarm.AlarmType = .display // EKAlarm 타입이 직접 노출되지 않으므로 기본값
            
            return ReminderAlarm(
                relativeOffset: alarm.relativeOffset,
                absoluteDate: alarm.absoluteDate,
                type: type
            )
        }
    }
    
    // MARK: - 리마인더 캘린더 매핑
    static func mapReminderCalendar(_ ekCalendar: EKCalendar) -> ReminderCalendar {
        let calendarType: ReminderCalendar.CalendarType
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
        
        let sourceType: ReminderCalendar.CalendarSource.SourceType
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
        
        return ReminderCalendar(
            id: ekCalendar.calendarIdentifier,
            title: ekCalendar.title,
            color: ekCalendar.cgColor,
            type: calendarType,
            isReadOnly: !ekCalendar.allowsContentModifications,
            allowsContentModifications: ekCalendar.allowsContentModifications,
            source: ReminderCalendar.CalendarSource(
                title: ekCalendar.source.title,
                type: sourceType
            )
        )
    }
}
