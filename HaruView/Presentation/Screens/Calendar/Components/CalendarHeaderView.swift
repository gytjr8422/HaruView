//
//  CalendarHeaderView.swift
//  HaruView
//
//  Created by 김효석 on 7/8/25.
//

import SwiftUI

struct CalendarHeaderView: View {
    let monthDisplayText: String
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void
    let onToday: () -> Void
    
    var body: some View {
        HStack {
            // 이전 달 버튼
            Button(action: onPreviousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hexCode: "A76545"))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color(hexCode: "A76545").opacity(0.1))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // 월/년 표시
            VStack(spacing: 2) {
                Text(monthDisplayText)
                    .font(.museumMedium(size: 19))
                    .foregroundStyle(Color(hexCode: "40392B"))
                
                // 오늘로 이동 버튼 (작은 텍스트)
                Button(action: onToday) {
                    Text("오늘")
                        .font(.pretendardRegular(size: 12))
                        .foregroundStyle(Color(hexCode: "A76545"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(hexCode: "A76545").opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
            
            // 다음 달 버튼
            Button(action: onNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hexCode: "A76545"))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color(hexCode: "A76545").opacity(0.1))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

#Preview {
    CalendarHeaderView(
        monthDisplayText: "2024년 1월",
        onPreviousMonth: {},
        onNextMonth: {},
        onToday: {}
    )
}
