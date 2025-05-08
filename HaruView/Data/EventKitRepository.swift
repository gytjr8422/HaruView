//
//  EventKitRepository.swift
//  HaruView
//
//  Created by 김효석 on 5/1/25.
//

import Foundation
import EventKit

final class EventKitRepository: EventRepositoryProtocol, ReminderRepositoryProtocol {
    
    private let service: EventKitService
    private let cal = Calendar.current
    
    init(service: EventKitService = EventKitService()) {
        self.service = service
    }
    
    // MARK: - 캘린더 Repository
    func fetchEvent() async -> Result<[Event], TodayBoardError> {
        let windowStart = cal.startOfDay(for: Date())
        let windowEnd = cal.date(byAdding: .day, value: 1, to: windowStart)!
        
        // 일주일 전 후 일정까지 가져오기 위함
        let wideStart = cal.date(byAdding: .day, value: -7, to: windowStart)!
        let wideEnd = cal.date(byAdding: .day, value: 7, to: windowEnd)!
        
        let ekResult = service.fetchEventsBetween(wideStart, wideEnd)
        dump(ekResult)
        return ekResult.map { events in
            events
                .filter { $0.endDate > windowStart && $0.startDate < windowEnd && $0.calendar.title != "대한민국 공휴일"}
                .map(Self.mapEvent)
                .sorted(by: eventSortRule)
        }
    }
    
    /// 종료된 일정은 뒤, 그 외는 시작 시각 오름차순
    private func eventSortRule(_ a: Event, _ b: Event) -> Bool {
        let now = Date()
        let aPast = a.end < now
        let bPast = b.end < now
        if aPast != bPast { return !aPast }          // 미종료 → 종료 순
        return a.start < b.start                     // 둘 다 동일 상태면 시작 시간
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
    
    // MARK: ReminderRepository
    func fetchReminder() async -> Result<[Reminder], TodayBoardError> {
        let todayStart = cal.startOfDay(for: Date())
        let todayEnd   = cal.date(byAdding: .day, value: 1, to: todayStart)!
        let ekRes = await service.fetchRemindersBetween(todayStart, todayEnd)
        dump(ekRes)
        return ekRes.map { rems in
            rems
                .filter { rem in        // dueDate가 없거나 오늘 범위면 포함
                    guard let due = rem.dueDateComponents?.date else { return true }
                    return due >= todayStart && due < todayEnd
                }
                .sorted(by: Self.sortRule)
                .map(Self.mapReminder)
        }
    }
    
    // 완료 ↘︎ 미완료 ↗︎ 정렬
    private static func sortRule(lhs: EKReminder, rhs: EKReminder) -> Bool {
        // 1. 완료 여부 기준 (미완료 먼저)
        if lhs.isCompleted != rhs.isCompleted {
            return !lhs.isCompleted
        }
        
        // 2. 우선순위 기준 (priority == 0 은 가장 낮은 순위로 처리)
        let lhsPriority = lhs.priority == 0 ? Int.max : lhs.priority
        let rhsPriority = rhs.priority == 0 ? Int.max : rhs.priority

        if lhsPriority != rhsPriority {
            return lhsPriority < rhsPriority // 숫자가 작을수록 앞에
        }
        
        // 3. 시간 설정 여부 (시간 설정된 항목을 먼저)
        let lhsHasTime = lhs.dueDateComponents?.hour != nil || lhs.dueDateComponents?.minute != nil
        let rhsHasTime = rhs.dueDateComponents?.hour != nil || rhs.dueDateComponents?.minute != nil
        
        if lhsHasTime != rhsHasTime {
            return lhsHasTime // 시간이 설정된 항목이 앞에
        }
        
        // 4. 마감일 기준 (빠른 순)
        let lDue = lhs.dueDateComponents?.date ?? .distantFuture
        let rDue = rhs.dueDateComponents?.date ?? .distantFuture
        if lDue != rDue {
            return lDue < rDue
        }

        // 5. 제목 기준 (알파벳 순)
        return lhs.title < rhs.title
    }
    
    func add(_ input: ReminderInput) async -> Result<Void, TodayBoardError> {
        service.addReminder(input)
    }
    
    func toggle(id: String) async -> Result<Void, TodayBoardError> {
        service.toggleReminder(id: id)
    }
    
    func deleteReminder(id: String) async -> Result<Void, TodayBoardError> {
        service.deleteReminder(id: id)
    }

    
    // MARK: Mapping Helpers
    private static func mapEvent(_ ek: EKEvent) -> Event {
        Event(id: ek.eventIdentifier,
              title: ek.title ?? "(제목 없음)",
              start: ek.startDate,
              end: ek.endDate,
              calendarTitle: ek.calendar.title,
              calendarColor: ek.calendar.cgColor,
              location: ek.location)
    }
    
    private static func mapReminder(_ rem: EKReminder) -> Reminder {
        let hasTime = rem.dueDateComponents?.hour != nil || rem.dueDateComponents?.minute != nil
        let due = hasTime ? rem.dueDateComponents?.date : nil
        return Reminder(id: rem.calendarItemIdentifier,
                        title: rem.title,
                        due: due,
                        isCompleted: rem.isCompleted,
                        priority: rem.priority)
    }
}
