//
//  LanguageSelectionView.swift
//  HaruView
//
//  Created by 김효석 on 8/22/25.
//

import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.haruBackground
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 30) {
                currentLanguageView
                divideView
                selectionView
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        
                        LocalizedText(key: "back")
                            .font(.pretendardRegular(size: 16))
                    }
                    .foregroundStyle(.haruPrimary)
                }
            }
            
            ToolbarItem(placement: .principal) {
                LocalizedText(key: "language_settings")
                    .font(.pretendardSemiBold(size: 18))
                    .foregroundStyle(.haruTextPrimary)
            }
        }
        .navigationBarBackButtonHidden(true)
        .improvedSwipeBack {
            dismiss()
        }
    }
    
    // MARK: - 현재 설정된 언어 표시
    @ViewBuilder
    private var currentLanguageView: some View {
        VStack(alignment: .leading, spacing: 10) {
            LocalizedText(key: "current_language")
                .font(.pretendardMedium(size: 14))
                .foregroundStyle(.haruSecondary)
            
            Text(languageManager.currentLanguage.displayName)
                .font(.pretendardBold(size: 16))
                .foregroundStyle(.haruTextPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - 구분선
    private var divideView: some View {
        Rectangle()
            .frame(height: 8)
            .foregroundStyle(Color.gray.opacity(0.1))
    }
    
    // MARK: - 언어 선택 영역
    private var selectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            LocalizedText(key: "change_language")
                .font(.pretendardBold(size: 16))
                .foregroundStyle(.haruTextPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                ForEach(Array(Language.allCases.enumerated()), id: \.element) { index, language in
                    languageSelectionButton(for: language)
                    
                    if index < Language.allCases.count - 1 {
                        Divider()
                            .padding(.horizontal, 20)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.haruBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.haruSecondary.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - 언어 선택 버튼
    private func languageSelectionButton(for language: Language) -> some View {
        Button(action: {
            selectLanguage(language)
        }) {
            HStack {
                Text(language.displayName)
                    .font(.pretendardMedium(size: 16))
                    .foregroundStyle(.haruTextPrimary)
                
                Spacer()
                
                if languageManager.selectedLanguage == language.title {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.haruPrimary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 메서드들
    private func selectLanguage(_ language: Language) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        languageManager.updateLanguage(language.title)
    }
}

#Preview {
    NavigationView {
        LanguageSelectionView()
    }
}
