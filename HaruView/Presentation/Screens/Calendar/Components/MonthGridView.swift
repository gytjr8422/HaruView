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
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
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
                .padding(.horizontal, 2)
                .transition(.opacity)
                
                Spacer(minLength: 20)
            }
        }
        .refreshable {
            // 부모 뷰에서 전체 새로고침 처리
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
