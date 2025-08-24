//
//  WeekdayHeaderView.swift
//  HaruView
//
//  Created by 김효석 on 7/8/25.
//

import SwiftUI

struct WeekdayHeaderView: View {
    @StateObject private var settings = AppSettings.shared
    @EnvironmentObject private var languageManager: LanguageManager
    
    private var weekdays: [String] {
        // languageManager의 refreshTrigger 의존성 생성
        let _ = languageManager.refreshTrigger
        return getLocalizedWeekdaySymbols(startingOnMonday: settings.weekStartsOnMonday)
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
    
    // MARK: - Helper Methods
    
    /// 언어별로 현지화된 요일 기호를 반환
    private func getLocalizedWeekdaySymbols(startingOnMonday: Bool) -> [String] {
        let formatter = DateFormatter()
        // LanguageManager의 현재 언어에 맞는 로케일 사용
        formatter.locale = languageManager.getCachedLocale(for: languageManager.currentLanguage)
        
        // 시스템 제공 단축 요일명 사용
        let symbols = formatter.shortWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        if startingOnMonday {
            // 월요일부터 시작: [월, 화, 수, 목, 금, 토, 일]
            return Array(symbols[1...]) + [symbols[0]]
        } else {
            // 일요일부터 시작: [일, 월, 화, 수, 목, 금, 토]
            return symbols
        }
    }
}

#Preview {
    WeekdayHeaderView()
}
