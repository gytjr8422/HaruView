//
//  LocationInputView.swift
//  HaruView
//
//  Created by 김효석 on 6/30/25.
//

import SwiftUI

// MARK: - 위치 입력 컴포넌트
struct LocationInputView: View {
    @Binding var location: String
    @State private var showLocationPicker = false
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                LocalizedText(key: "위치")
                    .font(.pretendardSemiBold(size: 16))
//                Spacer()
//                Button("빠른 선택") {
//                    showLocationPicker = true
//                }
//                .font(.pretendardRegular(size: 14))
//                .foregroundStyle(.haruPrimary)
            }
            
            HaruTextField(text: $location, placeholder: getLocalizedPlaceholder())
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet(selectedLocation: $location)
        }
    }
    
    // MARK: - Helper Methods
    
    /// 위치 입력 플레이스홀더를 현지화하여 반환
    private func getLocalizedPlaceholder() -> String {
        let _ = languageManager.refreshTrigger
        return "위치 입력".localized()
    }
}

// MARK: - 위치 선택 시트
struct LocationPickerSheet: View {
    @Binding var selectedLocation: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private let commonLocations = ["집", "회사", "카페", "헬스장", "도서관", "병원", "마트", "학교"]
    
    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(text: $searchText, placeholder: "위치 검색")
                    .padding()
                
                List {
                    Section("자주 사용하는 위치") {
                        ForEach(commonLocations, id: \.self) { place in
                            Button(place) {
                                selectedLocation = place
                                dismiss()
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                    
                    if !searchText.isEmpty {
                        Section("검색 결과") {
                            Button(searchText) {
                                selectedLocation = searchText
                                dismiss()
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle("위치 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 검색바 컴포넌트
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "검색"
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
