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
    internal let store = EKEventStore()
    
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
        let events = store.events(matching: predicate)
        
        return .success(events)
    }
    
    // MARK: - 공휴일 fetch
    func fetchHolidaysBetween(_ start: Date, _ end: Date) -> Result<[CalendarHoliday], TodayBoardError> {
        // iOS에서 제공하는 Holiday calendar 찾기
        let holidayCalendars = store.calendars(for: .event).filter { calendar in
            calendar.title.lowercased().contains("holiday") || 
            calendar.title.lowercased().contains("휴일") ||
            calendar.title.lowercased().contains("공휴일") ||
            calendar.calendarIdentifier.contains("holiday")
        }
        
        guard !holidayCalendars.isEmpty else {
            // Holiday calendar가 없으면 빈 배열 반환
            return .success([])
        }
        
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: holidayCalendars)
        let holidayEvents = store.events(matching: predicate)
        
        let holidays = holidayEvents.map { event in
            CalendarHoliday(title: event.title ?? "공휴일", date: event.startDate)
        }
        
        return .success(holidays)
    }
    
    // MARK: 리마인더 조회 (완료+미완료 모두)
    func fetchRemindersBetween(_ start: Date, _ end: Date) async -> Result<[EKReminder], TodayBoardError> {
        
        // Apple API: dueDateStarting=nil, ending=nil ⇒ 모든 dueDate & dueDate nil 포함
        let incPred = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        let cmpPred = store.predicateForCompletedReminders(withCompletionDateStarting: nil, ending: nil, calendars: nil)

        return await withCheckedContinuation { cont in
            var bucket: [EKReminder] = []
            
            store.fetchReminders(matching: incPred) { incompleteReminders in
                bucket.append(contentsOf: incompleteReminders ?? [])
                
                self.store.fetchReminders(matching: cmpPred) { completedReminders in
                    bucket.append(contentsOf: completedReminders ?? [])
                    // 조회 범위와 겹치는지 필터링
                    let filtered = bucket.filter { rem in
                        guard let due = rem.dueDateComponents?.date else { return true }
                        
                        let isInRange = due >= start && due < end
                        return isInRange
                    }
                    
                    cont.resume(returning: .success(filtered))
                }
            }
        }
    }

    // MARK: - 캘린더 관련 메서드
    func getAvailableCalendars() -> [EKCalendar] {
        return store.calendars(for: .event)
    }
    
    // MARK: - 사용 가능한 리마인더 캘린더 조회
    func getAvailableReminderCalendars() -> [EKCalendar] {
        return store.calendars(for: .reminder)
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
