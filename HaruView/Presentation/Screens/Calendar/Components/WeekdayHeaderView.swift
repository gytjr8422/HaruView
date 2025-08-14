//
//  WeekdayHeaderView.swift
//  HaruView
//
//  Created by 김효석 on 7/8/25.
//

import SwiftUI

struct WeekdayHeaderView: View {
    private let weekdays: [String] = {
        if Locale.current.language.languageCode?.identifier == "ko" {
            return ["일", "월", "화", "수", "목", "금", "토"]
        } else {
            return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        }
    }()
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekdays.enumerated()), id: \.offset) { index, weekday in
                Text(weekday)
                    .font(.pretendardRegular(size: 14))
                    .foregroundStyle(
                        index == 0 ? .haruPriorityHigh : // 일요일 빨간색
                        index == 6 ? .haruSaturday : // 토요일 파란색
                        .haruSecondary.opacity(0.7)   // 평일 회색
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
}

#Preview {
    WeekdayHeaderView()
}
