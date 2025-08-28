//
//  LargeMonthlyCalendarWidget.swift
//  HaruViewWidget
//
//  Created by Claude on 8/28/25.
//

import SwiftUI
import Foundation

// MARK: - Display Item
struct DisplayItem: Identifiable {
    let id: String
    let title: String
    let color: CGColor
    let isCompleted: Bool
}

struct LargeMonthlyCalendarWidget: View {
    let entry: Provider.Entry
    
    private let calendar = Calendar.withUserWeekStartPreference()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 3) {
                // 월 헤더
                monthHeader
                
                // 요일 헤더  
                weekdayHeader
                
                // 달력 그리드
                calendarGrid
                
                Spacer(minLength: 0)
            }
            .padding(6)
        }
    }
    
    // MARK: - Month Header
    private var monthHeader: some View {
        Text(monthString)
            .font(.pretendardSemiBold(size: 16))
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity)
    }
    
    // MARK: - Weekday Header
    private var weekdayHeader: some View {
        HStack(spacing: 1) {
            ForEach(weekdaySymbols, id: \.self) { weekday in
                Text(weekday)
                    .font(.pretendardRegular(size: 10))
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 20)
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 1) {
            ForEach(monthDates, id: \.self) { date in
                CompactDayCell(
                    date: date,
                    events: eventsFor(date),
                    reminders: remindersFor(date),
                    isToday: calendar.isDateInToday(date),
                    isCurrentMonth: isCurrentMonth(date)
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// 월 표시 문자열
    private var monthString: String {
        let currentLanguage = SharedUserDefaults.selectedLanguage
        let formatter = DateFormatter()
        let today = Date()
        
        switch currentLanguage {
        case "ko":
            formatter.dateFormat = "yyyy년 M월"
            formatter.locale = Locale(identifier: "ko_KR")
        case "ja":
            formatter.dateFormat = "yyyy年M月"
            formatter.locale = Locale(identifier: "ja_JP")
        default:
            formatter.dateFormat = "MMMM yyyy"
            formatter.locale = Locale(identifier: "en_US")
        }
        
        return formatter.string(from: today)
    }
    
    /// 요일 심볼 배열
    private var weekdaySymbols: [String] {
        let currentLanguage = SharedUserDefaults.selectedLanguage
        let formatter = DateFormatter()
        
        switch currentLanguage {
        case "ko":
            formatter.locale = Locale(identifier: "ko_KR")
        case "ja":
            formatter.locale = Locale(identifier: "ja_JP")
        default:
            formatter.locale = Locale(identifier: "en_US")
        }
        
        // 사용자 설정 주 시작일 반영
        let calendar = Calendar.withUserWeekStartPreference()
        let firstWeekday = calendar.firstWeekday
        let symbols = formatter.veryShortWeekdaySymbols!
        
        // 배열 회전하여 firstWeekday부터 시작
        let rotatedSymbols = Array(symbols[firstWeekday-1..<symbols.count] + symbols[0..<firstWeekday-1])
        return rotatedSymbols
    }
    
    /// 월간 날짜 배열 (42개 - 6주 × 7일)
    private var monthDates: [Date] {
        let today = Date()
        let calendar = Calendar.withUserWeekStartPreference()
        
        // 현재 월의 첫 번째 날
        guard let monthStart = calendar.dateInterval(of: .month, for: today)?.start else {
            return []
        }
        
        // 첫 번째 날이 속한 주의 시작일
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: monthStart)?.start else {
            return []
        }
        
        // 42일 생성 (6주)
        var dates: [Date] = []
        for i in 0..<42 {
            if let date = calendar.date(byAdding: .day, value: i, to: weekStart) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    // MARK: - Helper Methods
    
    /// 특정 날짜의 일정 반환
    private func eventsFor(_ date: Date) -> [CalendarEvent] {
        let calendar = Calendar.withUserWeekStartPreference()
        let targetDay = calendar.startOfDay(for: date)
        
        return entry.events.filter { event in
            let eventDay = calendar.startOfDay(for: event.startDate)
            return calendar.isDate(eventDay, inSameDayAs: targetDay)
        }.sorted { event1, event2 in
            // 시간순 정렬
            event1.startDate < event2.startDate
        }.prefix(4).map { $0 }
    }
    
    /// 특정 날짜의 할일 반환
    private func remindersFor(_ date: Date) -> [ReminderItem] {
        let calendar = Calendar.withUserWeekStartPreference()
        let targetDay = calendar.startOfDay(for: date)
        
        return entry.reminders.filter { reminder in
            guard let dueDate = reminder.dueDate else { return false }
            let reminderDay = calendar.startOfDay(for: dueDate)
            
            // ReminderType에 따른 필터링
            switch reminder.reminderType {
            case .onDate:
                // 정확한 날짜 매칭
                return calendar.isDate(reminderDay, inSameDayAs: targetDay)
            case .untilDate:
                // 마감일까지 계속 표시
                return reminderDay >= targetDay && !reminder.isCompleted
            }
        }.sorted { reminder1, reminder2 in
            // 중요도순, 그 다음 시간순
            if reminder1.priority != reminder2.priority {
                return reminder1.priority > reminder2.priority
            }
            return (reminder1.dueDate ?? Date.distantFuture) < (reminder2.dueDate ?? Date.distantFuture)
        }.prefix(4).map { $0 }
    }
    
    /// 현재 월에 속하는 날짜인지 확인
    private func isCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.withUserWeekStartPreference()
        let today = Date()
        return calendar.isDate(date, equalTo: today, toGranularity: .month)
    }
}

// MARK: - Compact Day Cell
struct CompactDayCell: View {
    let date: Date
    let events: [CalendarEvent]
    let reminders: [ReminderItem]
    let isToday: Bool
    let isCurrentMonth: Bool
    
    private let calendar = Calendar.withUserWeekStartPreference()
    
    var body: some View {
        VStack(spacing: 1) {
            // 날짜 숫자
            Text(dayNumber)
                .font(.system(size: 11, weight: isToday ? .bold : .medium))
                .foregroundStyle(dayNumberColor)
                .frame(height: 14)
            
            // 일정/할일 리스트 영역
            itemsListView
            .frame(maxHeight: 30)
            
            Spacer(minLength: 0)
        }
        .frame(height: 51)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isToday ? .blue.opacity(0.1) : .clear)
        )
        .opacity(isCurrentMonth ? 1.0 : 0.5)
    }
    
    // MARK: - Computed Properties
    
    private var dayNumber: String {
        String(calendar.component(.day, from: date))
    }
    
    private var itemsListView: some View {
        VStack(spacing: 1) {
            // 실제 일정/할일 표시
            ForEach(Array(displayItems.prefix(3).enumerated()), id: \.element.id) { index, item in
                itemRowView(item: item)
            }
            
            // 빈 슬롯 채우기 (일관된 높이 유지)  
            ForEach(displayItems.prefix(3).count..<3, id: \.self) { _ in
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 8)
            }
            
            // +N개 더 표시
            extraCountView
        }
    }
    
    private func itemRowView(item: DisplayItem) -> some View {
        HStack(spacing: 1) {
            // 색상 인디케이터
            Rectangle()
                .fill(Color(item.color))
                .frame(width: 2, height: 8)
            
            // 일정/할일 제목
            Text(item.title)
                .font(.system(size: 7))
                .foregroundStyle(item.isCompleted ? Color.secondary.opacity(0.6) : Color.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer(minLength: 0)
        }
        .frame(height: 8)
    }
    
    private var extraCountView: some View {
        Group {
            if displayItems.count > 3 {
                Text("+\(displayItems.count - 3)")
                    .font(.system(size: 6))
                    .foregroundStyle(Color.secondary)
                    .frame(height: 6)
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 6)
            }
        }
    }
    
    private var dayNumberColor: Color {
        if isToday {
            return .blue
        } else if !isCurrentMonth {
            return Color.secondary.opacity(0.4)
        } else {
            return weekdayColor
        }
    }
    
    private var weekdayColor: Color {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        switch weekday {
        case 1: return .red               // 일요일
        case 7: return .blue              // 토요일
        default: return Color.primary     // 평일
        }
    }
    
    /// 표시할 아이템들 (일정 + 할일 통합)
    private var displayItems: [DisplayItem] {
        var items: [DisplayItem] = []
        
        // 일정 추가
        for (index, event) in events.enumerated() {
            items.append(DisplayItem(
                id: "event_\(index)",
                title: event.title,
                color: event.calendarColor,
                isCompleted: false
            ))
        }
        
        // 할일 추가
        for reminder in reminders {
            items.append(DisplayItem(
                id: reminder.id,
                title: reminder.title,
                color: CGColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1.0), // 할일 기본 색상
                isCompleted: reminder.isCompleted
            ))
        }
        
        // 최대 4개로 제한
        return Array(items.prefix(4))
    }
}

#Preview {
    LargeMonthlyCalendarWidget(
        entry: SimpleEntry(
            date: .now,
            configuration: ConfigurationAppIntent(),
            events: [],
            reminders: []
        )
    )
    .frame(width: 364, height: 379)
    .background(.haruWidgetBackground)
}