//
//  EventKitRepository+Calendar.swift
//  HaruView
//
//  Created by 김효석 on 7/8/25.
//

import EventKit

// MARK: - 달력 전용 Repository 확장
extension EventKitRepository {
    
    /// 특정 날짜 범위의 이벤트 조회
    func fetchEvents(from startDate: Date, to endDate: Date) async -> Result<[Event], TodayBoardError> {
        
        let ekResult = service.fetchEventsBetween(startDate, endDate)
        
        return ekResult.map { events in
            
            let filtered = events
                .filter { event in
                    let isNotHoliday = event.calendar.title != "대한민국 공휴일"
                    
                    // 하루 종일 이벤트와 일반 이벤트를 다르게 처리
                    let isInRange: Bool
                    if event.isAllDay {
                        // 하루 종일 이벤트: 날짜만 비교 (시간 무시)
                        let calendar = Calendar.current
                        let eventStartDay = calendar.startOfDay(for: event.startDate)
                        let eventEndDay = calendar.startOfDay(for: event.endDate)
                        let rangeStartDay = calendar.startOfDay(for: startDate)
                        let rangeEndDay = calendar.startOfDay(for: endDate)
                        
                        // 하루 종일 이벤트는 종료일이 다음날 00:00일 수 있으므로 하루 빼서 확인
                        let actualEventEndDay = eventEndDay > eventStartDay ?
                            calendar.date(byAdding: .day, value: -1, to: eventEndDay) ?? eventEndDay :
                            eventEndDay
                        
                        isInRange = actualEventEndDay >= rangeStartDay && eventStartDay < rangeEndDay
                    } else {
                        // 일반 이벤트: 기존 로직
                        isInRange = event.endDate > startDate && event.startDate < endDate
                    }
                    
                    let include = isNotHoliday && isInRange
                    
                    return include
                }
                .map(Self.mapEvent)
                .sorted { $0.start < $1.start }
            
            return filtered
        }
    }
    
    /// 특정 날짜 범위의 할일 조회
    func fetchReminders(from startDate: Date, to endDate: Date) async -> Result<[Reminder], TodayBoardError> {
        
        let ekRes = await service.fetchRemindersBetween(startDate, endDate)
        return ekRes.map { rems in
            
            let filtered = rems.filter { rem in
                guard let due = rem.dueDateComponents?.date else {
                    // 마감일이 없는 할일은 오늘에만 표시
                    let isToday = Calendar.current.isDateInToday(startDate)
                    return isToday
                }
                
                // 마감일이 조회 범위에 포함되는지 확인
                let calendar = Calendar.current
                let dueDate = calendar.startOfDay(for: due)
                let rangeStart = calendar.startOfDay(for: startDate)
                let rangeEnd = calendar.startOfDay(for: endDate)
                
                let isInRange = dueDate >= rangeStart && dueDate < rangeEnd
                
                return isInRange
            }
            
            return filtered
                .sorted(by: Self.sortRule)
                .map(Self.mapReminder)
        }
    }
    
    /// 특정 월의 모든 데이터 조회 (달력용)
    func fetchCalendarMonth(year: Int, month: Int) async -> Result<CalendarMonth, TodayBoardError> {
        
        let calendar = Calendar.current
        guard let firstDay = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return .failure(.invalidInput)
        }
        
        // 월의 첫날부터 마지막날까지
        let lastDay = calendar.date(byAdding: .month, value: 1, to: firstDay)!
        
        // 달력 그리드에 필요한 범위 (이전/다음 달 일부 포함)
        let gridStartDate = calendar.date(byAdding: .day, value: -7, to: firstDay)!
        let gridEndDate = calendar.date(byAdding: .day, value: 7, to: lastDay)!
        
        // 이벤트와 할일을 병렬로 조회
        async let eventsResult = fetchEvents(from: gridStartDate, to: gridEndDate)
        async let remindersResult = fetchReminders(from: gridStartDate, to: gridEndDate)
        
        let events: [Event]
        let reminders: [Reminder]
        
        switch await eventsResult {
        case .success(let eventList):
            events = eventList
        case .failure(let error):
            return .failure(error)
        }
        
        switch await remindersResult {
        case .success(let reminderList):
            reminders = reminderList
        case .failure(let error):
            return .failure(error)
        }
        
        // 날짜별로 그룹화
        let calendarMonth = CalendarMonth(year: year, month: month)
        let days = calendarMonth.calendarDates.map { date -> CalendarDay in
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            // 해당 날짜의 이벤트 필터링
            let dayEvents = events.filter { event in
                // 하루 종일 이벤트와 일반 이벤트를 다르게 처리
                let overlaps: Bool
                
                // Event 구조체에서 하루 종일 여부 판단
                let isAllDay = calendar.isDate(event.start, inSameDayAs: event.end) &&
                             calendar.dateComponents([.hour, .minute], from: event.start) == DateComponents(hour: 0, minute: 0) &&
                             (calendar.dateComponents([.hour, .minute], from: event.end) == DateComponents(hour: 23, minute: 59) ||
                              calendar.dateComponents([.hour, .minute], from: event.end) == DateComponents(hour: 0, minute: 0))
                
                if isAllDay {
                    // 하루 종일 이벤트: 날짜만 비교
                    let eventStartDay = calendar.startOfDay(for: event.start)
                    let eventEndDay = calendar.startOfDay(for: event.end)
                    let targetDay = calendar.startOfDay(for: date)
                    
                    // 하루 종일 이벤트가 여러 날에 걸칠 수 있으므로
                    let actualEventEndDay = eventEndDay > eventStartDay ?
                        calendar.date(byAdding: .day, value: -1, to: eventEndDay) ?? eventEndDay :
                        eventStartDay
                    
                    overlaps = targetDay >= eventStartDay && targetDay <= actualEventEndDay
                    
                } else {
                    // 일반 이벤트: 시간 포함 비교
                    overlaps = event.start < dayEnd && event.end > dayStart
                }
                
                return overlaps
            }
            
            // 해당 날짜의 할일 필터링
            let dayReminders = reminders.filter { reminder in
                guard let due = reminder.due else {
                    // 마감일이 없는 할일은 오늘에만 표시
                    return calendar.isDateInToday(date)
                }
                
                // 마감일이 해당 날짜와 같은 날인지 확인 (시간 무시)
                let reminderDate = calendar.startOfDay(for: due)
                let targetDate = calendar.startOfDay(for: date)
                return calendar.isDate(reminderDate, inSameDayAs: targetDate)
            }
            
            return CalendarDay(date: date, events: dayEvents, reminders: dayReminders)
        }
        
        let monthWithDays = CalendarMonth(year: year, month: month, days: days)
        
        return .success(monthWithDays)
    }
    
    /// 특정 날짜의 상세 데이터 조회
    func fetchCalendarDay(for date: Date) async -> Result<CalendarDay, TodayBoardError> {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        async let eventsResult = fetchEvents(from: dayStart, to: dayEnd)
        async let remindersResult = fetchReminders(from: dayStart, to: dayEnd)
        
        switch (await eventsResult, await remindersResult) {
        case (.success(let events), .success(let reminders)):
            let calendarDay = CalendarDay(date: date, events: events, reminders: reminders)
            return .success(calendarDay)
            
        case (.failure(let error), _), (_, .failure(let error)):
            return .failure(error)
        }
    }
    
    /// 달력용 3개월 데이터 조회 (이전/현재/다음 달)
    func fetchCalendarWindow(centerMonth: Date) async -> Result<[CalendarMonth], TodayBoardError> {
        let calendar = Calendar.current
        let centerComponents = calendar.dateComponents([.year, .month], from: centerMonth)
        
        guard let centerYear = centerComponents.year,
              let centerMonthNumber = centerComponents.month else {
            return .failure(.invalidInput)
        }
        
        // 이전, 현재, 다음 달 계산
        let months: [(Int, Int)] = [
            // 이전 달
            centerMonthNumber == 1 ? (centerYear - 1, 12) : (centerYear, centerMonthNumber - 1),
            // 현재 달
            (centerYear, centerMonthNumber),
            // 다음 달
            centerMonthNumber == 12 ? (centerYear + 1, 1) : (centerYear, centerMonthNumber + 1)
        ]
        
        // 병렬로 3개월 데이터 조회
        async let prevMonth = fetchCalendarMonth(year: months[0].0, month: months[0].1)
        async let currentMonth = fetchCalendarMonth(year: months[1].0, month: months[1].1)
        async let nextMonth = fetchCalendarMonth(year: months[2].0, month: months[2].1)
        
        let results = await [prevMonth, currentMonth, nextMonth]
        
        var calendarMonths: [CalendarMonth] = []
        for result in results {
            switch result {
            case .success(let month):
                calendarMonths.append(month)
            case .failure(let error):
                return .failure(error)
            }
        }
        
        return .success(calendarMonths)
    }
}

// MARK: - 캐싱을 위한 헬퍼
extension EventKitRepository {
    
    /// 달력 데이터 캐시 키 생성
    private func cacheKey(for year: Int, month: Int) -> String {
        return "calendar_\(year)_\(String(format: "%02d", month))"
    }
    
    /// 간단한 메모리 캐시 (나중에 필요시 확장)
    private static var monthCache: [String: CalendarMonth] = [:]
    private static let cacheQueue = DispatchQueue(label: "calendar.cache", attributes: .concurrent)
    
    /// 캐시에서 월 데이터 조회
    func getCachedMonth(year: Int, month: Int) -> CalendarMonth? {
        let key = cacheKey(for: year, month: month)
        return Self.cacheQueue.sync {
            Self.monthCache[key]
        }
    }
    
    /// 월 데이터 캐시에 저장
    func setCachedMonth(_ month: CalendarMonth) {
        let key = cacheKey(for: month.year, month: month.month)
        Self.cacheQueue.async(flags: .barrier) {
            Self.monthCache[key] = month
        }
    }
    
    /// 캐시 정리 (메모리 절약)
    func clearOldCache() {
        let calendar = Calendar.current
        let now = Date()
        let currentComponents = calendar.dateComponents([.year, .month], from: now)
        
        guard let currentYear = currentComponents.year,
              let currentMonth = currentComponents.month else { return }
        
        Self.cacheQueue.async(flags: .barrier) {
            Self.monthCache = Self.monthCache.filter { key, month in
                // 현재 월 기준 ±2개월 데이터만 유지
                let monthDiff = (month.year - currentYear) * 12 + (month.month - currentMonth)
                return abs(monthDiff) <= 2
            }
        }
    }
}
