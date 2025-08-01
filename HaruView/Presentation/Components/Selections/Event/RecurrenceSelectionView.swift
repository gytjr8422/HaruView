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
            ScrollView {
                VStack(spacing: 20) {
                    // 빈도 섹션
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("빈도")
                                .font(.pretendardBold(size: 16))
                                .foregroundStyle(Color(hexCode: "6E5C49"))
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            // 반복 종류 선택
                            Picker("반복", selection: $frequency) {
                                Text("매일").tag(RecurrenceRuleInput.RecurrenceFrequency.daily)
                                Text("매주").tag(RecurrenceRuleInput.RecurrenceFrequency.weekly)
                                Text("매월").tag(RecurrenceRuleInput.RecurrenceFrequency.monthly)
                                Text("매년").tag(RecurrenceRuleInput.RecurrenceFrequency.yearly)
                            }
                            .pickerStyle(.segmented)
                            
                            // 간격 설정
                            HStack {
                                Text("매")
                                    .font(.pretendardRegular(size: 14))
                                    .foregroundStyle(Color(hexCode: "6E5C49"))
                                
                                TextField("간격", value: $interval, format: .number)
                                    .keyboardType(.numberPad)
                                    .font(.pretendardRegular(size: 14))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(hexCode: "FFFCF5"))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color(hexCode: "A76545").opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .frame(width: 60)
                                
                                Text(frequency == .daily ? "일" :
                                     frequency == .weekly ? "주" :
                                     frequency == .monthly ? "개월" : "년")
                                    .font(.pretendardRegular(size: 14))
                                    .foregroundStyle(Color(hexCode: "6E5C49"))
                                
                                Spacer()
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hexCode: "C2966B").opacity(0.09))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hexCode: "C2966B").opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    // 요일 선택 섹션 (매주일 때만)
                    if frequency == .weekly {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("요일")
                                    .font(.pretendardBold(size: 16))
                                    .foregroundStyle(Color(hexCode: "6E5C49"))
                                Spacer()
                            }
                            
                            let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
                            HStack(spacing: 8) {
                                ForEach(Array(weekdays.enumerated()), id: \.offset) { index, day in
                                    Button(action: {
                                        let dayNumber = index + 1
                                        if selectedWeekdays.contains(dayNumber) {
                                            selectedWeekdays.remove(dayNumber)
                                        } else {
                                            selectedWeekdays.insert(dayNumber)
                                        }
                                    }) {
                                        Text(day)
                                            .font(.pretendardMedium(size: 14))
                                            .foregroundStyle(selectedWeekdays.contains(index + 1) ? .white : Color(hexCode: "A76545"))
                                            .frame(width: 36, height: 36)
                                            .background(
                                                Circle()
                                                    .fill(selectedWeekdays.contains(index + 1) ? Color(hexCode: "A76545") : Color(hexCode: "A76545").opacity(0.1))
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hexCode: "C2966B").opacity(0.09))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(hexCode: "C2966B").opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    
                    // 종료 조건 섹션
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("종료 조건")
                                .font(.pretendardBold(size: 16))
                                .foregroundStyle(Color(hexCode: "6E5C49"))
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            Picker("종료", selection: $endCondition) {
                                Text("끝나지 않음").tag(RecurrenceRuleInput.EndCondition.never)
                                Text("특정 날짜").tag(RecurrenceRuleInput.EndCondition.endDate(endDate))
                                Text("횟수 제한").tag(RecurrenceRuleInput.EndCondition.occurrenceCount(occurrenceCount))
                            }
                            .pickerStyle(.segmented)
                            
                            switch endCondition {
                            case .endDate:
                                DatePicker("종료 날짜", selection: $endDate, displayedComponents: .date)
                                    .font(.pretendardRegular(size: 14))
                                    .foregroundStyle(Color(hexCode: "6E5C49"))
                            case .occurrenceCount:
                                HStack {
                                    Text("총")
                                        .font(.pretendardRegular(size: 14))
                                        .foregroundStyle(Color(hexCode: "6E5C49"))
                                    
                                    TextField("횟수", value: $occurrenceCount, format: .number)
                                        .keyboardType(.numberPad)
                                        .font(.pretendardRegular(size: 14))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(hexCode: "FFFCF5"))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color(hexCode: "A76545").opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                        .frame(width: 60)
                                    
                                    Text("회")
                                        .font(.pretendardRegular(size: 14))
                                        .foregroundStyle(Color(hexCode: "6E5C49"))
                                    
                                    Spacer()
                                }
                            case .never:
                                EmptyView()
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hexCode: "C2966B").opacity(0.09))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hexCode: "C2966B").opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(hexCode: "FFFCF5"))
            .navigationTitle("반복 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { 
                        dismiss() 
                    }
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(Color(hexCode: "6E5C49"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        createRecurrenceRule()
                        dismiss()
                    }
                    .font(.pretendardMedium(size: 16))
                    .foregroundStyle(Color(hexCode: "A76545"))
                }
            }
        }
        .onAppear {
            initializeFromExistingRule()
        }
        .onChange(of: frequency) { _, newFrequency in
            if newFrequency == .weekly && selectedWeekdays.isEmpty {
                // 매주로 변경했는데 선택된 요일이 없으면 현재 요일로 설정
                let currentWeekday = Calendar.current.component(.weekday, from: Date())
                selectedWeekdays = [currentWeekday]
            }
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
            } else if existing.frequency == .weekly {
                // 매주 반복이지만 특정 요일이 없으면, 현재 요일로 기본 설정
                let currentWeekday = Calendar.current.component(.weekday, from: Date())
                selectedWeekdays = [currentWeekday]
            }
        } else {
            // 새로 생성할 때는 현재 요일로 기본 설정
            if frequency == .weekly {
                let currentWeekday = Calendar.current.component(.weekday, from: Date())
                selectedWeekdays = [currentWeekday]
            }
        }
    }
}
