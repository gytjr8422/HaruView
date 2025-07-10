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
    
    private let years = Array(2020...2030)
    private let months = Array(1...12)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("이동할 월을 선택하세요")
                    .font(.pretendardSemiBold(size: 18))
                    .foregroundStyle(Color(hexCode: "40392B"))
                    .padding(.top, 20)
                
                HStack(spacing: 20) {
                    // 년도 선택
                    VStack(spacing: 8) {
                        Picker("년", selection: $selectedYear) {
                            ForEach(years, id: \.self) { year in
                                Text(String(year) + "년").tag(year)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                    
                    // 월 선택
                    VStack(spacing: 8) {
                        Picker("월", selection: $selectedMonth) {
                            ForEach(months, id: \.self) { month in
                                Text(String(month) + "월").tag(month)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color(hexCode: "FFFCF5"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(Color(hexCode: "A76545"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("이동") {
                        onDateSelected(selectedYear, selectedMonth)
                        dismiss()
                    }
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundStyle(Color(hexCode: "A76545"))
                }
                
                ToolbarItem(placement: .principal) {
                    Text("년/월 선택")
                        .font(.pretendardSemiBold(size: 17))
                        .foregroundStyle(Color(hexCode: "40392B"))
                }
            }
        }
        .presentationDetents([.fraction(0.35)])
        .presentationDragIndicator(.visible)
    }
}
