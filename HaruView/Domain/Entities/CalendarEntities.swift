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
    
    init(from event: Event) {
        self.id = event.id
        self.title = event.title
        self.calendarColor = event.calendarColor
        self.hasAlarms = event.hasAlarms
        
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
    
    /// 달력 셀에 표시할 짧은 제목 (최대 8자)
    var displayTitle: String {
        if title.count <= 8 {
            return title
        }
        return String(title.prefix(6)) + "..."
    }
    
    /// 시간 표시 텍스트
    var timeDisplayText: String? {
        guard let startTime = startTime else { return nil }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        
        if let endTime = endTime,
           !Calendar.current.isDate(startTime, equalTo: endTime, toGranularity: .minute) {
            return "\(formatter.string(from: startTime))-\(formatter.string(from: endTime))"
        } else {
            return formatter.string(from: startTime)
        }
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
    
    init(from reminder: Reminder) {
        self.id = reminder.id
        self.title = reminder.title
        self.dueTime = reminder.due
        self.isCompleted = reminder.isCompleted
        self.priority = reminder.priority
        self.calendarColor = reminder.calendar.color
    }
    
    /// 달력 셀에 표시할 짧은 제목 (최대 6자 + 상태 아이콘)
    var displayTitle: String {
        let icon = isCompleted ? "✓ " : "○ "
        let maxLength = 6
        
        if title.count <= maxLength {
            return icon + title
        }
        return icon + String(title.prefix(maxLength - 1)) + "..."
    }
    
    /// 시간 표시 텍스트
    var timeDisplayText: String? {
        guard let dueTime = dueTime else { return nil }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        
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
    
    init(date: Date, events: [Event] = [], reminders: [Reminder] = []) {
        self.id = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: date))
        self.date = Calendar.current.startOfDay(for: date)
        self.events = events.map(CalendarEvent.init)
        self.reminders = reminders.map(CalendarReminder.init)
    }
    
    /// 오늘인지 확인
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// 이번 달인지 확인
    func isInMonth(_ monthDate: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: monthDate, toGranularity: .month)
    }
    
    /// 일정이 있는지 확인
    var hasItems: Bool {
        !events.isEmpty || !reminders.isEmpty
    }
    
    /// 총 아이템 개수
    var totalItemCount: Int {
        events.count + reminders.count
    }
    
    /// 표시할 아이템들 (최대 4개, 우선순위 정렬)
    var displayItems: [CalendarDisplayItem] {
        var items: [CalendarDisplayItem] = []
        
        // 이벤트를 시간순으로 정렬
        let sortedEvents = events.sorted { event1, event2 in
            // 하루 종일 일정은 뒤로
            if event1.isAllDay != event2.isAllDay {
                return !event1.isAllDay
            }
            
            // 시간이 있는 경우 시간순
            if let time1 = event1.startTime, let time2 = event2.startTime {
                return time1 < time2
            }
            
            // 제목순
            return event1.title < event2.title
        }
        
        // 할일을 우선순위순으로 정렬
        let sortedReminders = reminders.sorted { reminder1, reminder2 in
            // 완료된 할일은 뒤로
            if reminder1.isCompleted != reminder2.isCompleted {
                return !reminder1.isCompleted
            }
            
            // 우선순위 (낮은 숫자가 높은 우선순위)
            let priority1 = reminder1.priority == 0 ? Int.max : reminder1.priority
            let priority2 = reminder2.priority == 0 ? Int.max : reminder2.priority
            
            if priority1 != priority2 {
                return priority1 < priority2
            }
            
            // 시간이 있는 할일 우선
            let hasTime1 = reminder1.dueTime != nil
            let hasTime2 = reminder2.dueTime != nil
            
            if hasTime1 != hasTime2 {
                return hasTime1
            }
            
            // 시간순
            if let time1 = reminder1.dueTime, let time2 = reminder2.dueTime {
                return time1 < time2
            }
            
            return reminder1.title < reminder2.title
        }
        
        // 이벤트 먼저, 그 다음 할일
        for event in sortedEvents {
            if items.count >= 4 { break }
            items.append(.event(event))
        }
        
        for reminder in sortedReminders {
            if items.count >= 4 { break }
            items.append(.reminder(reminder))
        }
        
        return items
    }
    
    /// 4개 초과시 추가 개수
    var extraItemCount: Int {
        max(0, totalItemCount - 4)
    }
}

// MARK: - 달력 표시 아이템 (이벤트 or 할일)
enum CalendarDisplayItem: Identifiable, Hashable {
    case event(CalendarEvent)
    case reminder(CalendarReminder)
    
    var id: String {
        switch self {
        case .event(let event): return "event_\(event.id)"
        case .reminder(let reminder): return "reminder_\(reminder.id)"
        }
    }
    
    var title: String {
        switch self {
        case .event(let event): return event.displayTitle
        case .reminder(let reminder): return reminder.displayTitle
        }
    }
    
    var timeText: String? {
        switch self {
        case .event(let event): return event.timeDisplayText
        case .reminder(let reminder): return reminder.timeDisplayText
        }
    }
    
    var color: CGColor {
        switch self {
        case .event(let event): return event.calendarColor
        case .reminder(let reminder):
            return reminder.priorityColor ?? reminder.calendarColor
        }
    }
    
    var isCompleted: Bool {
        switch self {
        case .event: return false
        case .reminder(let reminder): return reminder.isCompleted
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
        let calendar = Calendar.current
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        
        // 첫 주의 시작일 (일요일 기준)
        let startDate = calendar.date(byAdding: .day, value: -(firstWeekday - 1), to: firstDay)!
        
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
