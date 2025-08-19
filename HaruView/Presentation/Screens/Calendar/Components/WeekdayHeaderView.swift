//
//  WeekdayHeaderView.swift
//  HaruView
//
//  Created by 김효석 on 7/8/25.
//

import SwiftUI

struct WeekdayHeaderView: View {
    @StateObject private var settings = AppSettings.shared
    
    private var weekdays: [String] {
        if Locale.current.language.languageCode?.identifier == "ko" {
            return Calendar.weekdaySymbolsKorean()
        } else {
            return Calendar.weekdaySymbolsEnglish()
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekdays.enumerated()), id: \.offset) { index, weekday in
                Text(weekday)
                    .font(.pretendardRegular(size: 14))
                    .foregroundStyle(
                        weekdayColor(for: index)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 0)
            }
        }
        .background(
            .haruBackground
        )
    }
    
    private func weekdayColor(for index: Int) -> Color {
        if settings.weekStartsOnMonday {
            // 월요일 시작: 월 화 수 목 금 토 일
            switch index {
            case 5: return .haruSaturday      // 토요일 파란색
            case 6: return .haruPriorityHigh  // 일요일 빨간색
            default: return .haruSecondary.opacity(0.7) // 평일 회색
            }
        } else {
            // 일요일 시작: 일 월 화 수 목 금 토
            switch index {
            case 0: return .haruPriorityHigh  // 일요일 빨간색
            case 6: return .haruSaturday      // 토요일 파란색
            default: return .haruSecondary.opacity(0.7) // 평일 회색
            }
        }
    }
}

#Preview {
    WeekdayHeaderView()
}
