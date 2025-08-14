//
//  HaruTextField.swift
//  HaruView
//
//  Created by 김효석 on 5/9/25.
//

import SwiftUI

struct HaruTextField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @State private var showClearButton: Bool = false
    
    var placeholder: String = "입력해주세요."
    
    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                TextField("", text: $text)
                    .focused($isFocused)
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(.haruSecondary)
                    .padding(.leading, 10)
                    .padding(.trailing, showClearButton ? 30 : 10)
                    .frame(height: 50)
                    .onChange(of: text) { _, newValue in
                        showClearButton = !newValue.isEmpty
                    }
                
                // 커스텀 placeholder
                if text.isEmpty {
                    HStack {
                        Text(placeholder)
                            .font(.pretendardRegular(size: 16))
                            .foregroundStyle(.haruSecondary.opacity(0.5))
                            .padding(.leading, 10)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }
            }

            
            if showClearButton {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.haruPrimary)
                }
                .padding(.trailing, 10)
                .transition(.scale)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFocused ? .haruPrimary : .gray, lineWidth: 1)
        )
        .onChange(of: isFocused) { _, newValue in
            withAnimation {
                showClearButton = newValue && !text.isEmpty
            }
        }
    }
}

#Preview {
    HaruTextField(text: .constant("하루"), placeholder: "입력")
}
