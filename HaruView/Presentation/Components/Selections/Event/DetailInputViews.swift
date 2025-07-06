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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("메모")
                .font(.pretendardSemiBold(size: 16))
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $notes)
                    .focused($isFocused)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .background(Color(hexCode: "FFFCF5"))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isFocused ? Color(hexCode: "A76545") : Color.gray, lineWidth: 1)
                    )
                    .font(.pretendardRegular(size: 16))
                
                if notes.isEmpty && !isFocused {
                    Text("메모를 입력하세요")
                        .foregroundStyle(.secondary)
                        .font(.pretendardRegular(size: 16))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}
