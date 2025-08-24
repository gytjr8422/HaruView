//
//  CalendarEntities.swift
//  HaruView
//
//  Created by 김효석 on 7/8/25.
//

import SwiftUI

// MARK: - 달력용 간소화된 이벤트 모델
struct CalendarEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let startTime: Date?  // nil이면 종일 일정
    let endTime: Date?
    let calendarColor: CGColor
    let isAllDay: Bool
    let hasAlarms: Bool
    let originalStart: Date  // 원본 시작일
    let originalEnd: Date    // 원본 종료일
    
    init(from event: Event) {
        self.id = event.id
        self.title = event.title
        self.calendarColor = event.calendarColor
        self.hasAlarms = event.hasAlarms
        self.originalStart = event.start
        self.originalEnd = event.end
        
        // 하루 종일 일정 판별
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: event.start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: event.end)
        
        self.isAllDay = calendar.isDate(event.start, inSameDayAs: event.end) &&
                       startComponents.hour == 0 && startComponents.minute == 0 &&
                       endComponents.hour == 23 && endComponents.minute == 59
        
        if isAllDay {
            self.startTime = nil
            self.endTime = nil
        } else {
            self.startTime = event.start
            self.endTime = event.end
        }
    }
    
    /// 달력 셀에 표시할 제목 (원본 그대로)
    var displayTitle: String {
        return title
    }
    
    /// 시간 표시 텍스트
    var timeDisplayText: String? {
        guard let startTime = startTime else { return nil }
        
        let formatter = DateFormatterFactory.formatter(for: .shortTime)
        
        if let endTime = endTime {
            // 시작시간과 끝시간이 같은 경우에도 한 번만 표시
            if Calendar.current.isDate(startTime, equalTo: endTime, toGranularity: .minute) {
                return formatter.string(from: startTime)
            } else {
                return "\(formatter.string(from: startTime))-\(formatter.string(from: endTime))"
            }
        } else {
            return formatter.string(from: startTime)
        }
    }
}

// MARK: - 달력용 공휴일 모델
struct CalendarHoliday: Identifiable, Hashable {
    let id: String
    let title: String
    let date: Date
    let calendarColor: CGColor?
    
    init(title: String, date: Date, calendarColor: CGColor? = nil) {
        self.id = "holiday_\(ISO8601DateFormatter().string(from: date))_\(title)"
        self.title = title
        self.date = date
        self.calendarColor = calendarColor
    }
    
    /// 달력 셀에 표시할 제목
    var displayTitle: String {
        return title
    }
}

// MARK: - 달력용 간소화된 할일 모델
struct CalendarReminder: Identifiable, Hashable {
    let id: String
    let title: String
    let dueTime: Date?
    let isCompleted: Bool
    let priority: Int
    let calendarColor: CGColor
    let reminderType: ReminderType
    let includeTime: Bool
    
    init(from reminder: Reminder) {
        self.id = reminder.id
        self.title = reminder.title
        self.dueTime = reminder.due
        self.isCompleted = reminder.isCompleted
        self.priority = reminder.priority
        self.calendarColor = reminder.calendar.color
        self.reminderType = reminder.reminderType
        self.includeTime = reminder.includeTime
    }
    
    /// 달력 셀에 표시할 제목 (원본 그대로 + 상태 아이콘)
    var displayTitle: String {
        let icon = isCompleted ? "✓ " : "○ "
        return icon + title
    }
    
    /// 시간 표시 텍스트 ("특정 날짜에" 설정되고 "날짜+시간"인 할일만 시간 표시) - HomeView용
    var timeDisplayText: String? {
        guard let dueTime = dueTime, reminderType == .onDate, includeTime else { return nil }
        
        let formatter = DateFormatterFactory.formatter(for: .shortTime)
        
        return formatter.string(from: dueTime)
    }
    
    /// 시간 표시 텍스트 (모든 타입에서 "날짜+시간"이면 시간 표시) - DayDetailSheet용
    var detailTimeDisplayText: String? {
        guard let dueTime = dueTime, includeTime else { return nil }
        
        let formatter = DateFormatterFactory.formatter(for: .shortTime)
        
        return formatter.string(from: dueTime)
    }
    
    /// 우선순위 색상
    var priorityColor: CGColor? {
        switch priority {
        case 1: return CGColor(red: 1.0, green: 0.34, blue: 0.13, alpha: 1.0) // 높음
        case 5: return CGColor(red: 1.0, green: 0.76, blue: 0.03, alpha: 1.0) // 보통
        case 9: return CGColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1.0) // 낮음
        default: return nil
        }
    }
}

// MARK: - 하루의 일정 데이터
struct CalendarDay: Identifiable, Hashable {
    let id: String
    let date: Date
    let events: [CalendarEvent]
    let reminders: [CalendarReminder]
    let holidays: [CalendarHoliday]
    
    init(date: Date, events: [Event] = [], reminders: [Reminder] = [], holidays: [CalendarHoliday] = []) {
        self.id = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: date))
        self.date = Calendar.current.startOfDay(for: date)
        self.events = events.map(CalendarEvent.init)
        self.reminders = reminders.map(CalendarReminder.init)
        self.holidays = holidays
    }
    
    /// 오늘인지 확인
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// 이번 달인지 확인
    func isInMonth(_ monthDate: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: monthDate, toGranularity: .month)
    }
    
    /// 공휴일인지 확인
    var isHoliday: Bool {
        !holidays.isEmpty
    }
    
    /// 일정이 있는지 확인
    var hasItems: Bool {
        !events.isEmpty || !reminders.isEmpty || !holidays.isEmpty
    }
    
    /// 총 아이템 개수
    var totalItemCount: Int {
        events.count + reminders.count + holidays.count
    }
    
    /// 표시할 아이템들 (캐시된 계산 결과 사용)
    var displayItems: [CalendarDisplayItem] {
        return CalendarCacheManager.shared.getOrComputeDisplayItems(for: self)
    }
    
    /// 연속 이벤트 정보 생성
    private func createContinuousEventInfo(for event: CalendarEvent, on targetDate: Date) -> ContinuousEventInfo? {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: targetDate)
        let eventStartDay = calendar.startOfDay(for: event.originalStart)
        let eventEndDay = calendar.startOfDay(for: event.originalEnd)
        
        // 해당 날짜가 이벤트 기간에 포함되지 않으면 nil 반환
        guard targetDay >= eventStartDay && targetDay <= eventEndDay else {
            return nil
        }
        
        // 단일 날짜 이벤트는 연속 이벤트 처리하지 않음
        guard eventStartDay != eventEndDay else {
            return nil
        }
        
        let userCalendar = Calendar.withUserWeekStartPreference()
        let weekPosition = userCalendar.startingWeekdayIndex(for: targetDate)
        
        let isStart = targetDay == eventStartDay
        let isEnd = targetDay == eventEndDay
        
        // 제목 표시 여부 결정: 시작일이거나 주의 시작일
        let showTitle = isStart || weekPosition == 0
        
        return ContinuousEventInfo(
            event: event,
            showTitle: showTitle,
            isStart: isStart,
            isEnd: isEnd,
            weekPosition: weekPosition
        )
    }

    /// 4개 초과시 추가 개수 (이제 동적으로 계산)
    var extraItemCount: Int {
        if totalItemCount <= 4 {
            return 0  // 4개 이하면 "+N" 표시 안함
        } else {
            return totalItemCount - 3  // 5개 이상이면 (전체 - 3)개 표시
        }
    }
}

// MARK: - 연속 이벤트 표시 정보
struct ContinuousEventInfo: Hashable {
    let event: CalendarEvent
    let showTitle: Bool  // 해당 날짜에 제목을 표시할지
    let isStart: Bool    // 연속 바의 시작점인지
    let isEnd: Bool      // 연속 바의 끝점인지
    let weekPosition: Int // 해당 주에서의 위치 (0-6)
}

// MARK: - 달력 표시 아이템 (이벤트 or 할일 or 공휴일)
enum CalendarDisplayItem: Identifiable, Hashable {
    case event(CalendarEvent)
    case reminder(CalendarReminder)
    case holiday(CalendarHoliday)
    case continuousEvent(ContinuousEventInfo)
    
    var id: String {
        switch self {
        case .event(let event): return "event_\(event.id)"
        case .reminder(let reminder): return "reminder_\(reminder.id)"
        case .holiday(let holiday): return "holiday_\(holiday.id)"
        case .continuousEvent(let info): return "continuous_\(info.event.id)_\(info.weekPosition)"
        }
    }
    
    var title: String {
        switch self {
        case .event(let event): return event.displayTitle
        case .reminder(let reminder): return reminder.displayTitle
        case .holiday(let holiday): return holiday.displayTitle
        case .continuousEvent(let info): return info.showTitle ? info.event.displayTitle : ""
        }
    }
    
    var timeText: String? {
        switch self {
        case .event(let event): return event.timeDisplayText
        case .reminder(let reminder): return reminder.timeDisplayText
        case .holiday: return nil // 공휴일은 시간 표시 없음
        case .continuousEvent(let info): return info.showTitle ? info.event.timeDisplayText : nil
        }
    }
    
    var color: CGColor {
        switch self {
        case .event(let event): return event.calendarColor
        case .reminder(let reminder):
            return reminder.priorityColor ?? reminder.calendarColor
        case .holiday: 
            return CGColor(red: 0.61, green: 0.15, blue: 0.69, alpha: 1.0) // 공휴일은 보라색 (#9C27B0)
        case .continuousEvent(let info): return info.event.calendarColor
        }
    }
    
    var isCompleted: Bool {
        switch self {
        case .event: return false
        case .reminder(let reminder): return reminder.isCompleted
        case .holiday: return false
        case .continuousEvent: return false
        }
    }
    
    var continuousInfo: ContinuousEventInfo? {
        switch self {
        case .continuousEvent(let info): return info
        default: return nil
        }
    }
}

// MARK: - 월간 달력 데이터
struct CalendarMonth: Identifiable, Hashable {
    let id: String
    let year: Int
    let month: Int
    let days: [CalendarDay]
    
    init(year: Int, month: Int, days: [CalendarDay] = []) {
        self.year = year
        self.month = month
        self.id = "\(year)-\(String(format: "%02d", month))"
        self.days = days
    }
    
    /// 월의 첫 번째 날
    var firstDay: Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: 1))!
    }
    
    /// 월의 마지막 날
    var lastDay: Date {
        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: firstDay)!
        return Calendar.current.date(byAdding: .day, value: -1, to: nextMonth)!
    }
    
    /// 달력 그리드용 날짜들 (이전/다음 달 포함 6주)
    var calendarDates: [Date] {
        let calendar = Calendar.withUserWeekStartPreference()
        let startingIndex = calendar.startingWeekdayIndex(for: firstDay)
        
        // 첫 주의 시작일 (사용자 설정에 따라)
        let startDate = calendar.date(byAdding: .day, value: -startingIndex, to: firstDay)!
        
        // 6주 * 7일 = 42일
        return (0..<42).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startDate)
        }
    }
    
    /// 특정 날짜의 CalendarDay 찾기
    func day(for date: Date) -> CalendarDay? {
        let targetDate = Calendar.current.startOfDay(for: date)
        return days.first { Calendar.current.isDate($0.date, inSameDayAs: targetDate) }
    }
}
