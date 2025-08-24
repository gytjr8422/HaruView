//
//  WeekStartSelectionView.swift
//  HaruView
//
//  Created by 김효석 on 8/18/25.
//

import SwiftUI

struct WeekStartSelectionView: View {
    @StateObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    
    private var weekStartOptions: [WeekStartOption] {
        // languageManager의 refreshTrigger 의존성 생성
        let _ = languageManager.refreshTrigger
        
        return [
            WeekStartOption(
                id: false, 
                title: "일요일부터 시작".localized(), 
                subtitle: getLocalizedWeekdaySymbols(startingOnMonday: false).joined(separator: " "), 
                emoji: "☀️"
            ),
            WeekStartOption(
                id: true, 
                title: "월요일부터 시작".localized(), 
                subtitle: getLocalizedWeekdaySymbols(startingOnMonday: true).joined(separator: " "), 
                emoji: "💼"
            )
        ]
    }
    
    var body: some View {
        ZStack {
            Color.haruBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(weekStartOptions, id: \.id) { option in
                        weekStartOptionCard(option)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 70)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                LocalizedText(key: "주 시작일")
                    .font(.pretendardSemiBold(size: 18))
                    .foregroundStyle(.haruTextPrimary)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        
                        LocalizedText(key: "뒤로")
                            .font(.pretendardRegular(size: 16))
                    }
                    .foregroundStyle(.haruPrimary)
                }
            }
        }
        .improvedSwipeBack {
            dismiss()
        }
    }
    
    // MARK: - Helper Methods
    
    /// 언어별로 현지화된 요일 기호를 반환
    private func getLocalizedWeekdaySymbols(startingOnMonday: Bool) -> [String] {
        let symbols: [String]
        
        switch languageManager.currentLanguage {
        case .korean:
            symbols = ["일", "월", "화", "수", "목", "금", "토"]
        case .english:
            symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        case .japanese:
            symbols = ["日", "月", "火", "水", "木", "金", "土"]
        }
        
        if startingOnMonday {
            // 월요일부터 시작: [월, 화, 수, 목, 금, 토, 일]
            return Array(symbols[1...]) + [symbols[0]]
        } else {
            // 일요일부터 시작: [일, 월, 화, 수, 목, 금, 토]
            return symbols
        }
    }
    
    @ViewBuilder
    private func weekStartOptionCard(_ option: WeekStartOption) -> some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            settings.weekStartsOnMonday = option.id
        }) {
            HStack(spacing: 16) {
                // 이모지 아이콘
                Text(option.emoji)
                    .font(.system(size: 24))
                    .frame(width: 32, height: 32)
                
                // 텍스트 영역
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.pretendardRegular(size: 16))
                        .foregroundStyle(.haruTextPrimary)
                    
                    Text(option.subtitle)
                        .font(.pretendardRegular(size: 12))
                        .foregroundStyle(.haruSecondary)
                }
                
                Spacer()
                
                // 선택 상태 표시
                ZStack {
                    Circle()
                        .fill(settings.weekStartsOnMonday == option.id ? .haruPrimary : .clear)
                        .frame(width: 20, height: 20)
                    
                    Circle()
                        .stroke(
                            settings.weekStartsOnMonday == option.id ? .haruPrimary : .haruSecondary.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 20, height: 20)
                    
                    if settings.weekStartsOnMonday == option.id {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.haruBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        settings.weekStartsOnMonday == option.id ? .haruPrimary : .haruSecondary.opacity(0.2),
                        lineWidth: settings.weekStartsOnMonday == option.id ? 2 : 1
                    )
            )
            .scaleEffect(settings.weekStartsOnMonday == option.id ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: settings.weekStartsOnMonday)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Models
private struct WeekStartOption {
    let id: Bool
    let title: String
    let subtitle: String
    let emoji: String
}

#Preview {
    WeekStartSelectionView()
}