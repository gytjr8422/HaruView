//
//  CalendarUseCases.swift
//  HaruView
//
//  Created by 김효석 on 7/8/25.
//

import Foundation

// MARK: - 달력 월 데이터 조회 Use Case
struct FetchCalendarMonthUseCase {
    private let eventRepo: EventRepositoryProtocol
    private let reminderRepo: ReminderRepositoryProtocol
    
    init(eventRepo: EventRepositoryProtocol, reminderRepo: ReminderRepositoryProtocol) {
        self.eventRepo = eventRepo
        self.reminderRepo = reminderRepo
    }
    
    func callAsFunction(year: Int, month: Int) async -> Result<CalendarMonth, TodayBoardError> {
        // EventKitRepository에서 확장된 메서드 사용
        if let repo = eventRepo as? EventKitRepository {
            return await repo.fetchCalendarMonth(year: year, month: month)
        }
        
        // Fallback: 기본 구현
        return await fetchMonthDataFallback(year: year, month: month)
    }
    
    private func fetchMonthDataFallback(year: Int, month: Int) async -> Result<CalendarMonth, TodayBoardError> {
        let calendar = Calendar.current
        guard let firstDay = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return .failure(.invalidInput)
        }
        
        let lastDay = calendar.date(byAdding: .month, value: 1, to: firstDay)!
        
        // 기본 이벤트 조회 사용
        async let eventsResult = eventRepo.fetchEvent()
        async let remindersResult = reminderRepo.fetchReminder()
        
        switch (await eventsResult, await remindersResult) {
        case (.success(let allEvents), .success(let allReminders)):
            // 해당 월의 날짜들만 필터링
            let calendarMonth = CalendarMonth(year: year, month: month)
            let days = calendarMonth.calendarDates.map { date -> CalendarDay in
                let dayStart = calendar.startOfDay(for: date)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                
                let dayEvents = allEvents.filter { event in
                    event.start < dayEnd && event.end > dayStart
                }
                
                let dayReminders = allReminders.filter { reminder in
                    guard let due = reminder.due else { return false }
                    return calendar.isDate(due, inSameDayAs: date)
                }
                
                return CalendarDay(date: date, events: dayEvents, reminders: dayReminders)
            }
            
            return .success(CalendarMonth(year: year, month: month, days: days))
            
        case (.failure(let error), _), (_, .failure(let error)):
            return .failure(error)
        }
    }
}

// MARK: - 달력 특정 날짜 상세 조회 Use Case
struct FetchCalendarDayUseCase {
    private let eventRepo: EventRepositoryProtocol
    private let reminderRepo: ReminderRepositoryProtocol
    
    init(eventRepo: EventRepositoryProtocol, reminderRepo: ReminderRepositoryProtocol) {
        self.eventRepo = eventRepo
        self.reminderRepo = reminderRepo
    }
    
    func callAsFunction(for date: Date) async -> Result<CalendarDay, TodayBoardError> {
        // EventKitRepository에서 확장된 메서드 사용
        if let repo = eventRepo as? EventKitRepository {
            return await repo.fetchCalendarDay(for: date)
        }
        
        // Fallback: 기본 구현
        return await fetchDayDataFallback(for: date)
    }
    
    private func fetchDayDataFallback(for date: Date) async -> Result<CalendarDay, TodayBoardError> {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        async let eventsResult = eventRepo.fetchEvent()
        async let remindersResult = reminderRepo.fetchReminder()
        
        switch (await eventsResult, await remindersResult) {
        case (.success(let allEvents), .success(let allReminders)):
            let dayEvents = allEvents.filter { event in
                event.start < dayEnd && event.end > dayStart
            }
            
            let dayReminders = allReminders.filter { reminder in
                guard let due = reminder.due else { return false }
                return calendar.isDate(due, inSameDayAs: date)
            }
            
            return .success(CalendarDay(date: date, events: dayEvents, reminders: dayReminders))
            
        case (.failure(let error), _), (_, .failure(let error)):
            return .failure(error)
        }
    }
}

// MARK: - 달력 날짜 범위 조회 Use Case
struct FetchEventsByDateRangeUseCase {
    private let eventRepo: EventRepositoryProtocol
    private let reminderRepo: ReminderRepositoryProtocol
    
    init(eventRepo: EventRepositoryProtocol, reminderRepo: ReminderRepositoryProtocol) {
        self.eventRepo = eventRepo
        self.reminderRepo = reminderRepo
    }
    
    func callAsFunction(from startDate: Date, to endDate: Date) async -> Result<(events: [Event], reminders: [Reminder]), TodayBoardError> {
        // EventKitRepository에서 확장된 메서드 사용
        if let repo = eventRepo as? EventKitRepository {
            async let eventsResult = repo.fetchEvents(from: startDate, to: endDate)
            async let remindersResult = repo.fetchReminders(from: startDate, to: endDate)
            
            switch (await eventsResult, await remindersResult) {
            case (.success(let events), .success(let reminders)):
                return .success((events: events, reminders: reminders))
            case (.failure(let error), _), (_, .failure(let error)):
                return .failure(error)
            }
        }
        
        // Fallback: 기본 구현
        return await fetchRangeDataFallback(from: startDate, to: endDate)
    }
    
    private func fetchRangeDataFallback(from startDate: Date, to endDate: Date) async -> Result<(events: [Event], reminders: [Reminder]), TodayBoardError> {
        async let eventsResult = eventRepo.fetchEvent()
        async let remindersResult = reminderRepo.fetchReminder()
        
        switch (await eventsResult, await remindersResult) {
        case (.success(let allEvents), .success(let allReminders)):
            let filteredEvents = allEvents.filter { event in
                event.start < endDate && event.end > startDate
            }
            
            let filteredReminders = allReminders.filter { reminder in
                guard let due = reminder.due else { return false }
                return due >= startDate && due < endDate
            }
            
            return .success((events: filteredEvents, reminders: filteredReminders))
            
        case (.failure(let error), _), (_, .failure(let error)):
            return .failure(error)
        }
    }
}

// MARK: - 달력 3개월 윈도우 조회 Use Case (성능 최적화용)
struct FetchCalendarWindowUseCase {
    private let eventRepo: EventRepositoryProtocol
    private let reminderRepo: ReminderRepositoryProtocol
    
    init(eventRepo: EventRepositoryProtocol, reminderRepo: ReminderRepositoryProtocol) {
        self.eventRepo = eventRepo
        self.reminderRepo = reminderRepo
    }
    
    func callAsFunction(centerMonth: Date) async -> Result<[CalendarMonth], TodayBoardError> {
        // EventKitRepository에서 확장된 메서드 사용
        if let repo = eventRepo as? EventKitRepository {
            return await repo.fetchCalendarWindow(centerMonth: centerMonth)
        }
        
        // Fallback: 개별 월 조회
        return await fetchWindowFallback(centerMonth: centerMonth)
    }
    
    private func fetchWindowFallback(centerMonth: Date) async -> Result<[CalendarMonth], TodayBoardError> {
        let calendar = Calendar.current
        let centerComponents = calendar.dateComponents([.year, .month], from: centerMonth)
        
        guard let centerYear = centerComponents.year,
              let centerMonthNumber = centerComponents.month else {
            return .failure(.invalidInput)
        }
        
        // 이전, 현재, 다음 달 계산
        let months: [(Int, Int)] = [
            centerMonthNumber == 1 ? (centerYear - 1, 12) : (centerYear, centerMonthNumber - 1),
            (centerYear, centerMonthNumber),
            centerMonthNumber == 12 ? (centerYear + 1, 1) : (centerYear, centerMonthNumber + 1)
        ]
        
        let fetchMonth = FetchCalendarMonthUseCase(eventRepo: eventRepo, reminderRepo: reminderRepo)
        
        // 순차적으로 3개월 데이터 조회
        var calendarMonths: [CalendarMonth] = []
        for (year, month) in months {
            let result = await fetchMonth(year: year, month: month)
            switch result {
            case .success(let monthData):
                calendarMonths.append(monthData)
            case .failure(let error):
                return .failure(error)
            }
        }
        
        return .success(calendarMonths)
    }
}

// MARK: - 달력 데이터 캐시 관리 Use Case
struct CalendarCacheUseCase {
    private let eventRepo: EventRepositoryProtocol
    
    init(eventRepo: EventRepositoryProtocol) {
        self.eventRepo = eventRepo
    }
    
    /// 캐시된 월 데이터 조회
    func getCachedMonth(year: Int, month: Int) -> CalendarMonth? {
        guard let repo = eventRepo as? EventKitRepository else { return nil }
        return repo.getCachedMonth(year: year, month: month)
    }
    
    /// 월 데이터 캐시에 저장
    func setCachedMonth(_ month: CalendarMonth) {
        guard let repo = eventRepo as? EventKitRepository else { return }
        repo.setCachedMonth(month)
    }
    
    /// 오래된 캐시 정리
    func clearOldCache() {
        guard let repo = eventRepo as? EventKitRepository else { return }
        repo.clearOldCache()
    }
    
    /// 특정 월이 캐시되어 있는지 확인
    func isCached(year: Int, month: Int) -> Bool {
        return getCachedMonth(year: year, month: month) != nil
    }
    
    /// 미리 로딩 (백그라운드에서 다음/이전 달 캐시)
    func preloadAdjacentMonths(currentYear: Int, currentMonth: Int) async {
        let fetchMonth = FetchCalendarMonthUseCase(
            eventRepo: eventRepo,
            reminderRepo: eventRepo as? ReminderRepositoryProtocol ?? MockReminderRepository()
        )
        
        // 이전 달과 다음 달 계산
        let prevMonth = currentMonth == 1 ? 12 : currentMonth - 1
        let prevYear = currentMonth == 1 ? currentYear - 1 : currentYear
        let nextMonth = currentMonth == 12 ? 1 : currentMonth + 1
        let nextYear = currentMonth == 12 ? currentYear + 1 : currentYear
        
        // 캐시되지 않은 달들만 로딩
        await withTaskGroup(of: Void.self) { group in
            if !isCached(year: prevYear, month: prevMonth) {
                group.addTask {
                    let result = await fetchMonth(year: prevYear, month: prevMonth)
                    if case .success(let monthData) = result {
                        self.setCachedMonth(monthData)
                    }
                }
            }
            
            if !isCached(year: nextYear, month: nextMonth) {
                group.addTask {
                    let result = await fetchMonth(year: nextYear, month: nextMonth)
                    if case .success(let monthData) = result {
                        self.setCachedMonth(monthData)
                    }
                }
            }
        }
    }
}

// MARK: - Mock Repository (테스트용)
private struct MockReminderRepository: ReminderRepositoryProtocol {
    func fetchReminder() async -> Result<[Reminder], TodayBoardError> {
        return .success([])
    }
    
    func add(_ input: ReminderInput) async -> Result<Void, TodayBoardError> {
        return .success(())
    }
    
    func update(_ edit: ReminderEdit) async -> Result<Void, TodayBoardError> {
        return .success(())
    }
    
    func toggle(id: String) async -> Result<Void, TodayBoardError> {
        return .success(())
    }
    
    func deleteReminder(id: String) async -> Result<Void, TodayBoardError> {
        return .success(())
    }
}
