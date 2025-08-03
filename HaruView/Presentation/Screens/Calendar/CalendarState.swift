//
//  CalendarState.swift
//  HaruView
//
//  Created by 김효석 on 7/8/25.
//

import Foundation

// MARK: - 달력 UI 상태
struct CalendarState: Equatable {
    // 현재 표시 중인 월
    var currentYear: Int
    var currentMonth: Int
    
    // 데이터 상태
    var currentMonthData: CalendarMonth?
    var isLoading: Bool = false
    var error: TodayBoardError? = nil
    
    // UI 상태
    var selectedDate: Date? = nil
    var viewMode: CalendarViewMode = .month
    
    // 캐시 매니저는 직접 접근하지 않고 메서드에서 사용
    
    // 초기화
    init(date: Date = Date()) {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        self.currentYear = components.year ?? Calendar.current.component(.year, from: Date())
        self.currentMonth = components.month ?? Calendar.current.component(.month, from: Date())
        self.selectedDate = Calendar.current.startOfDay(for: date)
    }
    
    // 현재 월의 첫째 날
    var currentMonthFirstDay: Date {
        Calendar.current.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1)) ?? Date()
    }
    
    // 캐시 키 생성
    func cacheKey(year: Int, month: Int) -> String {
        return "calendar_\(year)_\(String(format: "%02d", month))"
    }
    
    // 현재 월 캐시 키
    var currentCacheKey: String {
        cacheKey(year: currentYear, month: currentMonth)
    }
    
    // 캐시에서 월 데이터 조회
    func getCachedMonth(year: Int, month: Int) -> CalendarMonth? {
        return CalendarCacheManager.shared.getCachedMonth(for: cacheKey(year: year, month: month))
    }
    
    // 월 데이터 캐시에 저장
    func setCachedMonth(_ month: CalendarMonth) {
        CalendarCacheManager.shared.setCachedMonth(month, for: cacheKey(year: month.year, month: month.month))
    }
    
    // 오래된 캐시 정리
    func clearOldCache() {
        CalendarCacheManager.shared.clearExpiredCache()
    }
}

// MARK: - 달력 뷰 모드
enum CalendarViewMode: String, CaseIterable {
    case month = "월간"
    case week = "주간"  // 추후 구현
    
    var localizedDescription: String {
        return NSLocalizedString(rawValue, comment: "")
    }
}

// MARK: - 달력 액션
enum CalendarAction {
    case loadCurrentMonth
    case moveToMonth(year: Int, month: Int)
    case moveToPreviousMonth
    case moveToNextMonth
    case selectDate(Date)
    case changeViewMode(CalendarViewMode)
    case refresh
    case clearError
}

// MARK: - 달력 월 이동 헬퍼
extension CalendarState {
    
    // 이전 달로 이동
    mutating func moveToPreviousMonth() {
        if currentMonth == 1 {
            currentYear -= 1
            currentMonth = 12
        } else {
            currentMonth -= 1
        }
    }
    
    // 다음 달로 이동
    mutating func moveToNextMonth() {
        if currentMonth == 12 {
            currentYear += 1
            currentMonth = 1
        } else {
            currentMonth += 1
        }
    }
    
    // 특정 월로 이동
    mutating func moveToMonth(year: Int, month: Int) {
        guard month >= 1 && month <= 12 else { return }
        self.currentYear = year
        self.currentMonth = month
    }
    
    // 오늘로 이동
    mutating func moveToToday() {
        let today = Date()
        let components = Calendar.current.dateComponents([.year, .month], from: today)
        self.currentYear = components.year ?? currentYear
        self.currentMonth = components.month ?? currentMonth
        self.selectedDate = Calendar.current.startOfDay(for: today)
    }
    
    // 월 표시 텍스트
    var monthDisplayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        if Locale.current.language.languageCode?.identifier == "ko" {
            return "\(currentYear)년 \(currentMonth)월"
        } else {
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: currentMonthFirstDay)
        }
    }
    
    // 이전/다음 달 정보
    var previousMonthInfo: (year: Int, month: Int) {
        if currentMonth == 1 {
            return (currentYear - 1, 12)
        } else {
            return (currentYear, currentMonth - 1)
        }
    }
    
    var nextMonthInfo: (year: Int, month: Int) {
        if currentMonth == 12 {
            return (currentYear + 1, 1)
        } else {
            return (currentYear, currentMonth + 1)
        }
    }
}

// MARK: - 날짜 선택 헬퍼
extension CalendarState {
    
    // 날짜 선택
    mutating func selectDate(_ date: Date) {
        self.selectedDate = Calendar.current.startOfDay(for: date)
        
        // 선택한 날짜가 현재 표시 월이 아니면 해당 월로 이동
        let dateComponents = Calendar.current.dateComponents([.year, .month], from: date)
        if let year = dateComponents.year, let month = dateComponents.month,
           year != currentYear || month != currentMonth {
            moveToMonth(year: year, month: month)
        }
    }
    
    // 선택된 날짜가 오늘인지
    var isSelectedDateToday: Bool {
        guard let selectedDate = selectedDate else { return false }
        return Calendar.current.isDateInToday(selectedDate)
    }
    
    // 선택된 날짜가 현재 월인지
    var isSelectedDateInCurrentMonth: Bool {
        guard let selectedDate = selectedDate else { return false }
        let components = Calendar.current.dateComponents([.year, .month], from: selectedDate)
        return components.year == currentYear && components.month == currentMonth
    }
    
    // 특정 날짜가 선택된 날짜인지
    func isDateSelected(_ date: Date) -> Bool {
        guard let selectedDate = selectedDate else { return false }
        return Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    // 특정 날짜가 오늘인지
    func isDateToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
    
    // 특정 날짜가 현재 월인지
    func isDateInCurrentMonth(_ date: Date) -> Bool {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        return components.year == currentYear && components.month == currentMonth
    }
}
