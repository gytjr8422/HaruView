//
//  CalendarGridView.swift
//  HaruView
//
//  Created by 김효석 on 7/8/25.
//

import SwiftUI

import SwiftUI

struct CalendarGridView: View {
    let monthData: CalendarMonth
    let selectedDate: Date?
    let onDateTap: (Date) -> Void
    let onDateLongPress: (Date) -> Void
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(monthData.calendarDates, id: \.self) { date in
                CalendarDayCell(
                    date: date,
                    calendarDay: monthData.day(for: date),
                    isSelected: isDateSelected(date),
                    isToday: Calendar.current.isDateInToday(date),
                    isCurrentMonth: isDateInCurrentMonth(date),
                    onTap: {
                        onDateTap(date)
                    },
                    onLongPress: {
                        onDateLongPress(date)
                    }
                )
            }
        }
    }
    
    private func isDateSelected(_ date: Date) -> Bool {
        guard let selectedDate = selectedDate else { return false }
        return Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    private func isDateInCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month], from: date)
        return dateComponents.year == monthData.year && dateComponents.month == monthData.month
    }
}

#Preview {
    // 테스트용 더미 데이터
    let testCalendar = EventCalendar(
        id: "test",
        title: "테스트",
        color: CGColor(red: 0.2, green: 0.6, blue: 0.8, alpha: 1.0),
        type: .local,
        isReadOnly: false,
        allowsContentModifications: true,
        source: EventCalendar.CalendarSource(title: "로컬", type: .local)
    )
    
    let today = Date()
    let calendar = Calendar.current
    let year = calendar.component(.year, from: today)
    let month = calendar.component(.month, from: today)
    
    // 몇 개 날짜에 더미 일정 추가
    let days = (1...31).compactMap { day -> CalendarDay? in
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return nil
        }
        
        // 랜덤하게 일정 추가
        let events: [Event] = day % 3 == 0 ? [
            Event(
                id: "test-\(day)",
                title: day % 2 == 0 ? "회의" : "개인 일정이 좀 길어서 잘려야 함",
                start: date,
                end: calendar.date(byAdding: .hour, value: 1, to: date)!,
                calendarTitle: "테스트",
                calendarColor: testCalendar.color,
                location: nil,
                notes: nil,
                url: nil,
                hasAlarms: false,
                alarms: [],
                hasRecurrence: false,
                recurrenceRule: nil,
                calendar: testCalendar,
                structuredLocation: nil
            )
        ] : []
        
        return CalendarDay(date: date, events: events, reminders: [])
    }
    
    let monthData = CalendarMonth(year: year, month: month, days: days)
    
    CalendarGridView(
        monthData: monthData,
        selectedDate: today,
        onDateTap: { _ in },
        onDateLongPress: { _ in }
    )
}
