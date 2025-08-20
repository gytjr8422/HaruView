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
//                .foregroundStyle(.haruPrimary)
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
                        .fill(.haruPrimary)
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
                            .foregroundStyle(.haruPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.haruPrimary.opacity(0.1))
                            )
                    }
                }
                
                // 커스텀 설정 버튼
                Button {
                    showCustomRecurrence = true
                } label: {
                    Text("사용자 설정")
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.haruPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.haruPrimary, lineWidth: 1)
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
    @StateObject private var settings = AppSettings.shared
    
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
                                .foregroundStyle(.haruSecondary)
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
                                    .foregroundStyle(.haruSecondary)
                                
                                TextField("간격", value: $interval, format: .number)
                                    .keyboardType(.numberPad)
                                    .font(.pretendardRegular(size: 14))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.haruBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(.haruPrimary.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .frame(width: 60)
                                
                                Text(frequency == .daily ? "일" :
                                     frequency == .weekly ? "주" :
                                     frequency == .monthly ? "개월" : "년")
                                    .font(.pretendardRegular(size: 14))
                                    .foregroundStyle(.haruSecondary)
                                
                                Spacer()
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.haruAccent.opacity(0.09))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.haruAccent.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    // 요일 선택 섹션 (매주일 때만)
                    if frequency == .weekly {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("요일")
                                    .font(.pretendardBold(size: 16))
                                    .foregroundStyle(.haruSecondary)
                                Spacer()
                            }
                            
                            let weekdays = Calendar.weekdaySymbols(startingOnMonday: settings.weekStartsOnMonday)
                            HStack(spacing: 8) {
                                ForEach(Array(weekdays.enumerated()), id: \.offset) { index, day in
                                    Button(action: {
                                        let dayNumber = weekdayIndexToCalendarWeekday(index: index)
                                        if selectedWeekdays.contains(dayNumber) {
                                            selectedWeekdays.remove(dayNumber)
                                        } else {
                                            selectedWeekdays.insert(dayNumber)
                                        }
                                    }) {
                                        Text(day)
                                            .font(.pretendardMedium(size: 14))
                                            .foregroundStyle(selectedWeekdays.contains(weekdayIndexToCalendarWeekday(index: index)) ? .white : .haruPrimary)
                                            .frame(width: 36, height: 36)
                                            .background(
                                                Circle()
                                                    .fill(selectedWeekdays.contains(weekdayIndexToCalendarWeekday(index: index)) ? .haruPrimary : .haruPrimary.opacity(0.1))
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.haruAccent.opacity(0.09))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(.haruAccent.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    
                    // 종료 조건 섹션
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("종료 조건")
                                .font(.pretendardBold(size: 16))
                                .foregroundStyle(.haruSecondary)
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
                                    .foregroundStyle(.haruSecondary)
                            case .occurrenceCount:
                                HStack {
                                    Text("총")
                                        .font(.pretendardRegular(size: 14))
                                        .foregroundStyle(.haruSecondary)
                                    
                                    TextField("횟수", value: $occurrenceCount, format: .number)
                                        .keyboardType(.numberPad)
                                        .font(.pretendardRegular(size: 14))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(.haruBackground)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(.haruPrimary.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                        .frame(width: 60)
                                    
                                    Text("회")
                                        .font(.pretendardRegular(size: 14))
                                        .foregroundStyle(.haruSecondary)
                                    
                                    Spacer()
                                }
                            case .never:
                                EmptyView()
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.haruAccent.opacity(0.09))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.haruAccent.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(.haruBackground)
            .navigationTitle("반복 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { 
                        dismiss() 
                    }
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(.haruSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        createRecurrenceRule()
                        dismiss()
                    }
                    .font(.pretendardMedium(size: 16))
                    .foregroundStyle(.haruPrimary)
                }
            }
        }
        .onAppear {
            initializeFromExistingRule()
        }
        .onChange(of: frequency) { _, newFrequency in
            if newFrequency == .weekly && selectedWeekdays.isEmpty {
                // 매주로 변경했는데 선택된 요일이 없으면 현재 요일로 설정
                let currentWeekday = Calendar.withUserWeekStartPreference().component(.weekday, from: Date())
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
    
    /// UI의 요일 인덱스를 Calendar의 weekday 번호로 변환
    private func weekdayIndexToCalendarWeekday(index: Int) -> Int {
        if settings.weekStartsOnMonday {
            // 월요일 시작: [월, 화, 수, 목, 금, 토, 일] -> [2, 3, 4, 5, 6, 7, 1]
            return index == 6 ? 1 : index + 2
        } else {
            // 일요일 시작: [일, 월, 화, 수, 목, 금, 토] -> [1, 2, 3, 4, 5, 6, 7]
            return index + 1
        }
    }
    
    /// Calendar의 weekday 번호를 UI의 요일 인덱스로 변환
    private func calendarWeekdayToIndex(weekday: Int) -> Int {
        if settings.weekStartsOnMonday {
            // [2, 3, 4, 5, 6, 7, 1] -> [0, 1, 2, 3, 4, 5, 6]
            return weekday == 1 ? 6 : weekday - 2
        } else {
            // [1, 2, 3, 4, 5, 6, 7] -> [0, 1, 2, 3, 4, 5, 6]
            return weekday - 1
        }
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
                let currentWeekday = Calendar.withUserWeekStartPreference().component(.weekday, from: Date())
                selectedWeekdays = [currentWeekday]
            }
        } else {
            // 새로 생성할 때는 현재 요일로 기본 설정
            if frequency == .weekly {
                let currentWeekday = Calendar.withUserWeekStartPreference().component(.weekday, from: Date())
                selectedWeekdays = [currentWeekday]
            }
        }
    }
}
