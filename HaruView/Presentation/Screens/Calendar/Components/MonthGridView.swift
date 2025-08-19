//
//  MonthGridView.swift
//  HaruView
//
//  Created by 김효석 on 7/11/25.
//

import SwiftUI

struct MonthGridView: View {
    let monthData: CalendarMonth
    let selectedDate: Date?
    let isCurrentDisplayedMonth: Bool
    let onDateTap: (Date) -> Void
    let onDateLongPress: (Date) -> Void
    let onRefresh: () async -> Void
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(monthData.calendarDates, id: \.self) { date in
                    CalendarDayCell(
                        date: date,
                        calendarDay: monthData.day(for: date),
                        isSelected: isDateSelected(date),
                        isToday: Calendar.withUserWeekStartPreference().isDateInToday(date),
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
            .padding(.horizontal, 2)
            .transition(.opacity)
            
            Spacer(minLength: 20)
        }
        .refreshable {
            await onRefresh()
        }
    }
    
    private func isDateSelected(_ date: Date) -> Bool {
        guard let selectedDate = selectedDate else { return false }
        return Calendar.withUserWeekStartPreference().isDate(date, inSameDayAs: selectedDate)
    }
    
    private func isDateInCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.withUserWeekStartPreference()
        let dateComponents = calendar.dateComponents([.year, .month], from: date)
        return dateComponents.year == monthData.year && dateComponents.month == monthData.month
    }
}
