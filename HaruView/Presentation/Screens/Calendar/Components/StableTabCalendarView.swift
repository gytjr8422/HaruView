//
//  StableTabCalendarView.swift
//  HaruView
//
//  Created by Claude Code on 7/20/25.
//

import SwiftUI

struct StableTabCalendarView: View {
    @Binding var currentIndex: Int
    let monthWindow: [CalendarMonth]
    let selectedDate: Date?
    let onPageChange: (Int) -> Void
    let onDateTap: (Date) -> Void
    let onDateLongPress: (Date) -> Void
    let onRefresh: () async -> Void
    
    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(monthWindow.enumerated()), id: \.offset) { index, monthData in
                MonthGridView(
                    monthData: monthData,
                    selectedDate: selectedDate,
                    isCurrentDisplayedMonth: index == currentIndex,
                    onDateTap: onDateTap,
                    onDateLongPress: onDateLongPress,
                    onRefresh: onRefresh
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .indexViewStyle(.page(backgroundDisplayMode: .never))
        .clipped()
        .onChange(of: currentIndex) { _, newIndex in
            onPageChange(newIndex)
        }
    }
}

#Preview("Stable Tab Calendar") {
    @Previewable @State var currentIndex = 3
    
    let dummyMonths = (1...7).map { month in
        CalendarMonth(year: 2025, month: month, days: [])
    }
    
    return StableTabCalendarView(
        currentIndex: $currentIndex,
        monthWindow: dummyMonths,
        selectedDate: Date(),
        onPageChange: { _ in },
        onDateTap: { _ in },
        onDateLongPress: { _ in },
        onRefresh: { }
    )
}
