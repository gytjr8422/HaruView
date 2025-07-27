//
//  RecurrenceSelectionView.swift
//  HaruView
//
//  Created by 김효석 on 6/30/25.
//

import SwiftUI

// MARK: - 반복 설정 컴포넌트
struct RecurrenceSelectionView: View {
    @Binding var recurrenceRule: RecurrenceRuleInput?
    @State private var showCustomRecurrence = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
//            HStack {
//                Spacer()
//                Button(recurrenceRule == nil ? "설정" : "편집") {
//                    showCustomRecurrence = true
//                }
//                .font(.pretendardRegular(size: 14))
//                .foregroundStyle(Color(hexCode: "A76545"))
//            }
            
            if let rule = recurrenceRule {
                HStack {
                    Text(rule.description)
                        .font(.pretendardRegular(size: 14))
                    
                    Spacer()
                    
                    Button {
                        recurrenceRule = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal,12)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hexCode: "A76545"))
                )
            } else {
                Text("반복하지 않음")
                    .font(.pretendardRegular(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
            
            // 빠른 설정 버튼들
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(Array(RecurrenceRuleInput.presets.enumerated()), id: \.offset) { index, preset in
                    Button {
                        recurrenceRule = preset
                    } label: {
                        Text(preset.description)
                            .font(.pretendardRegular(size: 14))
                            .foregroundStyle(Color(hexCode: "A76545"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hexCode: "A76545").opacity(0.1))
                            )
                    }
                }
                
                // 커스텀 설정 버튼
                Button {
                    showCustomRecurrence = true
                } label: {
                    Text("사용자 설정")
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(Color(hexCode: "A76545"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hexCode: "A76545"), lineWidth: 1)
                        )
                }
            }
        }
        .sheet(isPresented: $showCustomRecurrence) {
            CustomRecurrenceSheet(recurrenceRule: $recurrenceRule)
        }
    }
}

// MARK: - 커스텀 반복 설정 시트
struct CustomRecurrenceSheet: View {
    @Binding var recurrenceRule: RecurrenceRuleInput?
    @Environment(\.dismiss) private var dismiss
    
    @State private var frequency: RecurrenceRuleInput.RecurrenceFrequency = .weekly
    @State private var interval: Int = 1
    @State private var endCondition: RecurrenceRuleInput.EndCondition = .never
    @State private var endDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
    @State private var occurrenceCount: Int = 10
    @State private var selectedWeekdays: Set<Int> = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("빈도") {
                    Picker("반복", selection: $frequency) {
                        Text("매일").tag(RecurrenceRuleInput.RecurrenceFrequency.daily)
                        Text("매주").tag(RecurrenceRuleInput.RecurrenceFrequency.weekly)
                        Text("매월").tag(RecurrenceRuleInput.RecurrenceFrequency.monthly)
                        Text("매년").tag(RecurrenceRuleInput.RecurrenceFrequency.yearly)
                    }
                    
                    HStack {
                        Text("매")
                        TextField("간격", value: $interval, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        Text(frequency == .daily ? "일" :
                             frequency == .weekly ? "주" :
                             frequency == .monthly ? "개월" : "년")
                    }
                }
                
                if frequency == .weekly {
                    Section("요일") {
                        let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                            ForEach(Array(weekdays.enumerated()), id: \.offset) { index, day in
                                Button(day) {
                                    let dayNumber = index + 1
                                    if selectedWeekdays.contains(dayNumber) {
                                        selectedWeekdays.remove(dayNumber)
                                    } else {
                                        selectedWeekdays.insert(dayNumber)
                                    }
                                }
                                .font(.pretendardRegular(size: 14))
                                .foregroundStyle(selectedWeekdays.contains(index + 1) ? .white : Color(hexCode: "A76545"))
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(selectedWeekdays.contains(index + 1) ? Color(hexCode: "A76545") : Color(hexCode: "A76545").opacity(0.1))
                                )
                            }
                        }
                    }
                }
                
                Section("종료 조건") {
                    Picker("종료", selection: $endCondition) {
                        Text("끝나지 않음").tag(RecurrenceRuleInput.EndCondition.never)
                        Text("특정 날짜").tag(RecurrenceRuleInput.EndCondition.endDate(endDate))
                        Text("횟수 제한").tag(RecurrenceRuleInput.EndCondition.occurrenceCount(occurrenceCount))
                    }
                    
                    switch endCondition {
                    case .endDate:
                        DatePicker("종료 날짜", selection: $endDate, displayedComponents: .date)
                    case .occurrenceCount:
                        HStack {
                            TextField("횟수", value: $occurrenceCount, format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                            Text("회")
                        }
                    case .never:
                        EmptyView()
                    }
                }
            }
            .navigationTitle("반복 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        createRecurrenceRule()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            initializeFromExistingRule()
        }
    }
    
    private func createRecurrenceRule() {
        let daysOfWeek = selectedWeekdays.map { dayNumber in
            RecurrenceRuleInput.WeekdayInput(dayOfWeek: dayNumber, weekNumber: nil)
        }
        
        let finalEndCondition: RecurrenceRuleInput.EndCondition
        switch endCondition {
        case .never:
            finalEndCondition = .never
        case .endDate:
            finalEndCondition = .endDate(endDate)
        case .occurrenceCount:
            finalEndCondition = .occurrenceCount(occurrenceCount)
        }
        
        recurrenceRule = RecurrenceRuleInput(
            frequency: frequency,
            interval: interval,
            endCondition: finalEndCondition,
            daysOfWeek: frequency == .weekly && !daysOfWeek.isEmpty ? daysOfWeek : nil,
            daysOfMonth: nil
        )
    }
    
    private func initializeFromExistingRule() {
        if let existing = recurrenceRule {
            frequency = existing.frequency
            interval = existing.interval
            endCondition = existing.endCondition
            
            if let daysOfWeek = existing.daysOfWeek {
                selectedWeekdays = Set(daysOfWeek.map { $0.dayOfWeek })
            }
        }
    }
}
