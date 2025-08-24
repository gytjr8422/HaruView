//
//  DetailInputViews.swift
//  HaruView
//
//  Created by 김효석 on 6/30/25.
//

import SwiftUI

// MARK: - URL 입력 컴포넌트
struct URLInputView: View {
    @Binding var url: String
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("URL")
                .font(.pretendardSemiBold(size: 16))
            
            HaruTextField(text: $url, placeholder: "https://example.com")
                .keyboardType(.URL)
                .autocapitalization(.none)
        }
    }
}

// MARK: - 메모 입력 컴포넌트
struct NotesInputView: View {
    @Binding var notes: String
    @FocusState private var isFocused: Bool
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LocalizedText(key: "메모")
                .font(.pretendardSemiBold(size: 16))
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $notes)
                    .focused($isFocused)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .background(.haruBackground)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isFocused ? .haruPrimary : Color.gray, lineWidth: 1)
                    )
                    .font(.pretendardRegular(size: 16))
                
                if notes.isEmpty && !isFocused {
                    Text(getLocalizedPlaceholder())
                        .foregroundStyle(.secondary)
                        .font(.pretendardRegular(size: 16))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// 메모 플레이스홀더를 현지화하여 반환
    private func getLocalizedPlaceholder() -> String {
        let _ = languageManager.refreshTrigger
        return "메모를 입력하세요".localized()
    }
}
