//
//  MonthYearPickerSheet.swift
//  HaruView
//
//  Created by 김효석 on 7/11/25.
//

import SwiftUI

struct MonthYearPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let currentYear: Int
    let currentMonth: Int
    let onDateSelected: (Int, Int) -> Void
    
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    
    init(currentYear: Int, currentMonth: Int, onDateSelected: @escaping (Int, Int) -> Void) {
        self.currentYear = currentYear
        self.currentMonth = currentMonth
        self.onDateSelected = onDateSelected
        _selectedYear = State(initialValue: currentYear)
        _selectedMonth = State(initialValue: currentMonth)
    }
    
    private var years: [Int] {
        let now = Calendar.current.component(.year, from: Date())
        return Array((now - 50)...(now + 50))
    }
    
    private let months = Array(1...12)
    
    private var languageManager: LanguageManager {
        LanguageManager.shared
    }
    
    private func monthDisplayText(for month: Int) -> String {
        switch languageManager.currentLanguage {
        case .english:
            let formatter = DateFormatter()
            formatter.locale = languageManager.currentLanguage.locale
            formatter.dateFormat = "MMMM"
            let date = Calendar.current.date(from: DateComponents(month: month))!
            return formatter.string(from: date)
        case .japanese:
            return "\(month)" + "月".localized()
        case .korean:
            return "\(month)" + "월".localized()
        }
    }
    
    private func yearDisplayText(for year: Int) -> String {
        switch languageManager.currentLanguage {
        case .english:
            return String(year)
        case .japanese:
            return "\(year)" + "년".localized()
        case .korean:
            return "\(year)" + "년".localized()
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                LocalizedText(key: "이동할 월을 선택하세요")
                    .font(.pretendardSemiBold(size: 18))
                    .foregroundStyle(.haruTextPrimary)
                    .padding(.top, 20)
                
                HStack(spacing: 20) {
                    // 년도 선택
                    VStack(spacing: 8) {
                        Picker("년".localized(), selection: $selectedYear) {
                            ForEach(years, id: \.self) { year in
                                Text(yearDisplayText(for: year)).tag(year)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                    
                    // 월 선택
                    VStack(spacing: 8) {
                        Picker("월".localized(), selection: $selectedMonth) {
                            ForEach(months, id: \.self) { month in
                                Text(monthDisplayText(for: month)).tag(month)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(.haruBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소".localized()) {
                        dismiss()
                    }
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(.haruPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("이동".localized()) {
                        onDateSelected(selectedYear, selectedMonth)
                        dismiss()
                    }
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundStyle(.haruPrimary)
                }
                
                ToolbarItem(placement: .principal) {
                    LocalizedText(key: "년/월 선택")
                        .font(.pretendardSemiBold(size: 17))
                        .foregroundStyle(.haruTextPrimary)
                }
            }
        }
        .presentationDetents([.fraction(0.35)])
        .presentationDragIndicator(.visible)
    }
}
