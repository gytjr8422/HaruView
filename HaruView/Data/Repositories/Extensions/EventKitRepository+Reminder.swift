//
//  EventKitRepository+Reminder.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import EventKit

// MARK: - 할 일 관련
extension EventKitRepository {
    // MARK: - ReminderRepository (기존과 동일)
    func fetchReminder() async -> Result<[Reminder], TodayBoardError> {
        let todayStart = cal.startOfDay(for: Date())
        let todayEnd   = cal.date(byAdding: .day, value: 1, to: todayStart)!
        let ekRes = await service.fetchRemindersBetween(todayStart, todayEnd)
        return ekRes.map { rems in
            rems
                .filter { rem in
                    guard let due = rem.dueDateComponents?.date else { return true }
                    return due >= todayStart && due < todayEnd
                }
                .sorted(by: Self.sortRule)
                .map(Self.mapReminder)
        }
    }
    
    func add(_ input: ReminderInput) async -> Result<Void, TodayBoardError> {
        service.addReminder(input)
    }

    func update(_ edit: ReminderEdit) async -> Result<Void, TodayBoardError> {
        service.updateReminder(edit)
    }
    
    func toggle(id: String) async -> Result<Void, TodayBoardError> {
        service.toggleReminder(id: id)
    }
    
    func deleteReminder(id: String) async -> Result<Void, TodayBoardError> {
        service.deleteReminder(id: id)
    }
    
    // MARK: - 사용 가능한 리마인더 캘린더 조회
    func getAvailableReminderCalendars() -> [ReminderCalendar] {
        let calendars = service.getAvailableReminderCalendars()
        return calendars
            .filter { $0.allowsContentModifications } // 편집 가능한 캘린더만
            .map(Self.mapReminderCalendar)
    }
    
    static func sortRule(lhs: EKReminder, rhs: EKReminder) -> Bool {
        if lhs.isCompleted != rhs.isCompleted {
            return !lhs.isCompleted
        }
        
        let lhsPriority = lhs.priority == 0 ? Int.max : lhs.priority
        let rhsPriority = rhs.priority == 0 ? Int.max : rhs.priority

        if lhsPriority != rhsPriority {
            return lhsPriority < rhsPriority
        }
        
        let lhsHasTime = lhs.dueDateComponents?.hour != nil || lhs.dueDateComponents?.minute != nil
        let rhsHasTime = rhs.dueDateComponents?.hour != nil || rhs.dueDateComponents?.minute != nil
        
        if lhsHasTime != rhsHasTime {
            return lhsHasTime
        }
        
        let lDue = lhs.dueDateComponents?.date ?? .distantFuture
        let rDue = rhs.dueDateComponents?.date ?? .distantFuture
        if lDue != rDue {
            return lDue < rDue
        }

        return lhs.title < rhs.title
    }
}

extension EventKitRepository {
    // MARK: - Reminder 매핑 함수
    static func mapReminder(_ rem: EKReminder) -> Reminder {
        let hasTime = rem.dueDateComponents?.hour != nil || rem.dueDateComponents?.minute != nil
        let due = hasTime ? rem.dueDateComponents?.date : nil
        
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
     private static func mapReminderCalendar(_ ekCalendar: EKCalendar) -> ReminderCalendar {
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
