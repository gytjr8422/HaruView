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
        // 사용자가 선택한 공휴일 지역 가져오기
        let selectedRegion = AppSettings.shared.getCurrentHolidayRegion()
        
        // iOS에서 제공하는 Holiday calendar 찾기
        let holidayCalendars = store.calendars(for: .event).filter { calendar in
            let titleLower = calendar.title.lowercased()
            
            // 기본 공휴일 키워드 검사
            let hasHolidayKeyword = titleLower.contains("holiday") || 
                                   titleLower.contains("휴일") ||
                                   titleLower.contains("공휴일") ||
                                   calendar.calendarIdentifier.contains("holiday")
            
            if !hasHolidayKeyword {
                return false
            }
            
            // "자동" 모드인 경우 모든 공휴일 캘린더 포함
            if selectedRegion.localeIdentifier == "auto" {
                return true
            }
            
            // 특정 지역이 선택된 경우 해당 지역과 매칭
            return matchesRegion(calendar: calendar, localeIdentifier: selectedRegion.localeIdentifier)
        }
        
        guard !holidayCalendars.isEmpty else {
            return .success([])
        }
        
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: holidayCalendars)
        let holidayEvents = store.events(matching: predicate)
        
        let holidays = holidayEvents.map { event in
            CalendarHoliday(title: event.title ?? "공휴일", date: event.startDate)
        }
        
        return .success(holidays)
    }
    
    // MARK: - 지역별 공휴일 캘린더 매칭
    private func matchesRegion(calendar: EKCalendar, localeIdentifier: String) -> Bool {
        let titleLower = calendar.title.lowercased()
        let countryCode = String(localeIdentifier.suffix(2)).lowercased()
        
        // 주요 국가별 매칭 로직
        let countryKeywords: [String: [String]] = [
            "kr": ["korea", "한국", "대한민국"],
            "us": ["united states", "us", "america", "미국"],
            "jp": ["japan", "일본", "jpn"],
            "cn": ["china", "중국", "中国"],
            "hk": ["hong kong", "홍콩"],
            "gb": ["united kingdom", "uk", "britain", "영국"],
            "de": ["germany", "deutschland", "독일"],
            "fr": ["france", "프랑스"],
            "ca": ["canada", "캐나다"],
            "au": ["australia", "호주"],
            "it": ["italy", "italia", "이탈리아"],
            "es": ["spain", "españa", "스페인"],
            "mx": ["mexico", "méxico", "멕시코"],
            "br": ["brazil", "brasil", "브라질"],
            "in": ["india", "인도"],
            "se": ["sweden", "sverige", "스웨덴"]
        ]
        
        // 선택된 국가의 키워드들과 매칭
        if let keywords = countryKeywords[countryCode] {
            return keywords.contains { keyword in
                titleLower.contains(keyword)
            }
        }
        
        // 기본적으로 국가 코드가 포함되어 있는지 확인
        return titleLower.contains(countryCode)
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
    
    // MARK: - 공휴일 캘린더 디버깅용 메서드
    func debugHolidayCalendars() {
        let allCalendars = store.calendars(for: .event)
        print("\n🔍 [HOLIDAY DEBUG] EventKit 캘린더 전체 분석:")
        print("총 \(allCalendars.count)개 캘린더 발견\n")
        
        for (index, calendar) in allCalendars.enumerated() {
            let isSubscription = calendar.type == .subscription
            let isHoliday = calendar.title.lowercased().contains("holiday") || 
                           calendar.title.lowercased().contains("휴일") ||
                           calendar.title.lowercased().contains("공휴일")
            
            print("[\(index + 1)] \(calendar.title)")
            print("  - ID: \(calendar.calendarIdentifier)")
            print("  - 타입: \(typeDescription(calendar.type))")
            print("  - 소스: \(calendar.source.title)")
            print("  - 구독 캘린더: \(isSubscription ? "예" : "아니오")")
            print("  - 공휴일 캘린더: \(isHoliday ? "예" : "아니오")")
            print("  - 편집 가능: \(calendar.allowsContentModifications ? "예" : "아니오")")
            print("")
        }
        
        let holidayCalendars = allCalendars.filter { calendar in
            calendar.title.lowercased().contains("holiday") || 
            calendar.title.lowercased().contains("휴일") ||
            calendar.title.lowercased().contains("공휴일")
        }
        
        print("🎉 공휴일 캘린더: \(holidayCalendars.count)개")
        for calendar in holidayCalendars {
            print("  - \(calendar.title) (타입: \(typeDescription(calendar.type)))")
        }
        
        if holidayCalendars.isEmpty {
            print("❗ 공휴일 캘린더가 없습니다.")
            print("iOS 캘린더 앱에서 '캘린더 > 캘린더 추가 > 공휴일 캘린더 추가'를 통해 추가해야 합니다.")
        }
    }
    
    // MARK: - 사용 가능한 공휴일 캘린더 목록 조회
    func getAvailableHolidayRegions() -> [String] {
        let allCalendars = store.calendars(for: .event)
        let holidayCalendars = allCalendars.filter { calendar in
            calendar.title.lowercased().contains("holiday") || 
            calendar.title.lowercased().contains("휴일") ||
            calendar.title.lowercased().contains("공휴일")
        }
        
        return holidayCalendars.map { $0.title }
    }
    
    // MARK: - 특정 지역의 공휴일 캘린더 존재 여부 확인
    func hasHolidayCalendarFor(region: HolidayRegion) -> Bool {
        if region.localeIdentifier == "auto" {
            return !getAvailableHolidayRegions().isEmpty
        }
        
        let allCalendars = store.calendars(for: .event)
        let holidayCalendars = allCalendars.filter { calendar in
            let titleLower = calendar.title.lowercased()
            let hasHolidayKeyword = titleLower.contains("holiday") || 
                                   titleLower.contains("휴일") ||
                                   titleLower.contains("공휴일")
            
            return hasHolidayKeyword && matchesRegion(calendar: calendar, localeIdentifier: region.localeIdentifier)
        }
        
        return !holidayCalendars.isEmpty
    }
    
    private func typeDescription(_ type: EKCalendarType) -> String {
        switch type {
        case .local: return "로컬"
        case .calDAV: return "CalDAV"
        case .exchange: return "Exchange"
        case .subscription: return "구독"
        case .birthday: return "생일"
        @unknown default: return "알 수 없음"
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
