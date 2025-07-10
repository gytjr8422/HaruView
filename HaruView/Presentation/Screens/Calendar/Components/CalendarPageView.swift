//
//  CalendarPageView.swift
//  HaruView
//
//  Created by 김효석 on 7/11/25.
//

import SwiftUI

struct CalendarPageView: View {
    let monthData: CalendarMonth?
    let pageIndex: Int
    let selectedDate: Date?
    let onDateTap: (Date, Int) -> Void
    let onDateLongPress: (Date) -> Void
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                if let monthData = monthData {
                    // 데이터가 있는 경우 (즉시 표시)
                    CalendarGridView(
                        monthData: monthData,
                        selectedDate: selectedDate,
                        onDateTap: { date in
                            onDateTap(date, pageIndex)
                        },
                        onDateLongPress: onDateLongPress
                    )
                    .id("\(monthData.year)-\(monthData.month)")
                    .padding(.horizontal, 20)
                } else {
                    // 로딩 상태 (최소화된 플레이스홀더)
                    CalendarGridPlaceholder()
                        .padding(.horizontal, 20)
                }
                
                // 하단 여백 추가 (탭바와 겹치지 않도록)
                Spacer(minLength: 100)
            }
        }
    }
}

// MARK: - 가벼운 플레이스홀더 (ProgressView 대신)
struct CalendarGridPlaceholder: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            // 6주 × 7일 = 42개 셀의 플레이스홀더
            ForEach(0..<42, id: \.self) { index in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 108) // CalendarDayCell과 동일한 높이
                    .overlay {
                        if index == 21 { // 중앙에만 작은 인디케이터
                            ProgressView()
                                .scaleEffect(0.6)
                                .opacity(0.5)
                        }
                    }
            }
        }
    }
}
