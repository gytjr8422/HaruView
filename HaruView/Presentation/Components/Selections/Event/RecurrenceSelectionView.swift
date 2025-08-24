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
    @EnvironmentObject private var languageManager: LanguageManager
    
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
                    Text(getLocalizedRuleDescription(rule))
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
                Text(getLocalizedNoRecurrenceText())
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
                        Text(getLocalizedRuleDescription(preset))
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
                    Text(getLocalizedCustomText())
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
    
    // MARK: - Helper Methods
    
    /// 반복 규칙 설명을 현지화하여 반환
    private func getLocalizedRuleDescription(_ rule: RecurrenceRuleInput) -> String {
        let _ = languageManager.refreshTrigger
        
        // 직접 현지화된 설명 생성
        var result = ""
        
        if rule.interval > 1 {
            switch rule.frequency {
            case .daily:
                result = "%d일마다".localized(with: rule.interval)
            case .weekly:
                result = "%d주마다".localized(with: rule.interval)
            case .monthly:
                result = "%d개월마다".localized(with: rule.interval)
            case .yearly:
                result = "%d년마다".localized(with: rule.interval)
            }
        } else {
            switch rule.frequency {
            case .daily:
                result = "매일".localized()
            case .weekly:
                // 평일(월-금)인지 확인
                if let daysOfWeek = rule.daysOfWeek,
                   daysOfWeek.count == 5,
                   daysOfWeek.contains(where: { $0.dayOfWeek == 2 }) && // 월요일
                   daysOfWeek.contains(where: { $0.dayOfWeek == 3 }) && // 화요일
                   daysOfWeek.contains(where: { $0.dayOfWeek == 4 }) && // 수요일
                   daysOfWeek.contains(where: { $0.dayOfWeek == 5 }) && // 목요일
                   daysOfWeek.contains(where: { $0.dayOfWeek == 6 }) {  // 금요일
                    result = "평일만".localized()
                } else {
                    result = "매주".localized()
                }
            case .monthly:
                result = "매월".localized()
            case .yearly:
                result = "매년".localized()
            }
        }
        
        if let daysOfWeek = rule.daysOfWeek, !daysOfWeek.isEmpty {
            // 평일만인 경우 한국어에서만 괄호 표시
            let isWeekdays = daysOfWeek.count == 5 &&
                           daysOfWeek.contains(where: { $0.dayOfWeek == 2 }) && // 월요일
                           daysOfWeek.contains(where: { $0.dayOfWeek == 3 }) && // 화요일
                           daysOfWeek.contains(where: { $0.dayOfWeek == 4 }) && // 수요일
                           daysOfWeek.contains(where: { $0.dayOfWeek == 5 }) && // 목요일
                           daysOfWeek.contains(where: { $0.dayOfWeek == 6 })    // 금요일
            
            // 한국어가 아니고 평일만인 경우 괄호 생략
            if !isWeekdays || languageManager.currentLanguage == .korean {
                // 현지화된 요일 이름 매핑
                let dayNames = ["", "일".localized(), "월".localized(), "화".localized(), "수".localized(), "목".localized(), "금".localized(), "토".localized()]
                let selectedDays = daysOfWeek.compactMap {
                    dayNames.indices.contains($0.dayOfWeek) ? dayNames[$0.dayOfWeek] : nil
                }
                
                // 사용자의 주 시작일 설정에 따라 정렬
                let weekStartsOnMonday = UserDefaults.standard.object(forKey: "weekStartsOnMonday") as? Bool ?? false
                let sortedDays = selectedDays.sorted { day1, day2 in
                    guard let index1 = dayNames.firstIndex(of: day1),
                          let index2 = dayNames.firstIndex(of: day2) else {
                        return false
                    }
                    
                    let adjustedIndex1 = weekStartsOnMonday ? (index1 == 1 ? 7 : index1 - 1) : index1 - 1
                    let adjustedIndex2 = weekStartsOnMonday ? (index2 == 1 ? 7 : index2 - 1) : index2 - 1
                    
                    return adjustedIndex1 < adjustedIndex2
                }
                
                result += " (\(sortedDays.joined(separator: ",")))"
            }
        }
        
        switch rule.endCondition {
        case .never:
            break
        case .endDate(let date):
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: languageManager.currentLanguage.appleLanguageCode)
            formatter.dateStyle = .medium
            result += " - \(formatter.string(from: date))" + "까지".localized()
        case .occurrenceCount(let count):
            result += " - \(count)" + "회".localized()
        }
        
        return result
    }
    
    /// "반복하지 않음" 텍스트를 현지화하여 반환
    private func getLocalizedNoRecurrenceText() -> String {
        let _ = languageManager.refreshTrigger
        return "반복하지 않음".localized()
    }
    
    /// "사용자 설정" 텍스트를 현지화하여 반환
    private func getLocalizedCustomText() -> String {
        let _ = languageManager.refreshTrigger
        return "사용자 설정".localized()
    }
}

// MARK: - 커스텀 반복 설정 시트
struct CustomRecurrenceSheet: View {
    @Binding var recurrenceRule: RecurrenceRuleInput?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = AppSettings.shared
    @EnvironmentObject private var languageManager: LanguageManager
    
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
                            LocalizedText(key: "빈도")
                                .font(.pretendardBold(size: 16))
                                .foregroundStyle(.haruSecondary)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            // 반복 종류 선택
                            Picker("반복", selection: $frequency) {
                                Text(getLocalizedFrequency(.daily)).tag(RecurrenceRuleInput.RecurrenceFrequency.daily)
                                Text(getLocalizedFrequency(.weekly)).tag(RecurrenceRuleInput.RecurrenceFrequency.weekly)
                                Text(getLocalizedFrequency(.monthly)).tag(RecurrenceRuleInput.RecurrenceFrequency.monthly)
                                Text(getLocalizedFrequency(.yearly)).tag(RecurrenceRuleInput.RecurrenceFrequency.yearly)
                            }
                            .pickerStyle(.segmented)
                            .id(languageManager.currentLanguage)
                            
                            // 간격 설정
                            HStack {
                                Text(getLocalizedEvery())
                                    .font(.pretendardRegular(size: 14))
                                    .foregroundStyle(.haruSecondary)
                                
                                TextField(getLocalizedInterval(), value: $interval, format: .number)
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
                                
                                Text(getLocalizedUnit(for: frequency))
                                    .font(.pretendardRegular(size: 14))
                                    .foregroundStyle(.haruSecondary)
                                
                                Spacer()
                            }
                            .id("\(languageManager.currentLanguage.rawValue)-\(frequency)")
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
                                LocalizedText(key: "요일")
                                    .font(.pretendardBold(size: 16))
                                    .foregroundStyle(.haruSecondary)
                                Spacer()
                            }
                            
                            let weekdays = getLocalizedWeekdaySymbols()
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
                            LocalizedText(key: "종료 조건")
                                .font(.pretendardBold(size: 16))
                                .foregroundStyle(.haruSecondary)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            Picker("종료", selection: $endCondition) {
                                Text(getLocalizedEndCondition(.never)).tag(RecurrenceRuleInput.EndCondition.never)
                                Text(getLocalizedEndCondition(.endDate(endDate))).tag(RecurrenceRuleInput.EndCondition.endDate(endDate))
                                Text(getLocalizedEndCondition(.occurrenceCount(occurrenceCount))).tag(RecurrenceRuleInput.EndCondition.occurrenceCount(occurrenceCount))
                            }
                            .pickerStyle(.segmented)
                            .id(languageManager.currentLanguage)
                            
                            switch endCondition {
                            case .endDate:
                                DatePicker(getLocalizedEndDate(), selection: $endDate, displayedComponents: .date)
                                    .font(.pretendardRegular(size: 14))
                                    .foregroundStyle(.haruSecondary)
                            case .occurrenceCount:
                                HStack {
                                    Text(getLocalizedTotal())
                                        .font(.pretendardRegular(size: 14))
                                        .foregroundStyle(.haruSecondary)
                                    
                                    TextField(getLocalizedCount(), value: $occurrenceCount, format: .number)
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
                                    
                                    Text(getLocalizedTimes())
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
            .navigationTitle(getLocalizedTitle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(getLocalizedCancel()) { 
                        dismiss() 
                    }
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(.haruSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(getLocalizedDone()) {
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
    
    // MARK: - Helper Methods for Localization
    
    /// 빈도 텍스트를 현지화하여 반환
    private func getLocalizedFrequency(_ frequency: RecurrenceRuleInput.RecurrenceFrequency) -> String {
        let _ = languageManager.refreshTrigger
        switch frequency {
        case .daily: return "매일".localized()
        case .weekly: return "매주".localized()
        case .monthly: return "매월".localized()
        case .yearly: return "매년".localized()
        }
    }
    
    /// "매" 텍스트를 현지화하여 반환
    private func getLocalizedEvery() -> String {
        let _ = languageManager.refreshTrigger
        return "매".localized()
    }
    
    /// "간격" 텍스트를 현지화하여 반환
    private func getLocalizedInterval() -> String {
        let _ = languageManager.refreshTrigger
        return "간격".localized()
    }
    
    /// 빈도별 단위를 현지화하여 반환
    private func getLocalizedUnit(for frequency: RecurrenceRuleInput.RecurrenceFrequency) -> String {
        let _ = languageManager.refreshTrigger
        switch frequency {
        case .daily: return "일".localized()
        case .weekly: return "주".localized()
        case .monthly: return "개월".localized()
        case .yearly: return "년".localized()
        }
    }
    
    /// 종료 조건 텍스트를 현지화하여 반환
    private func getLocalizedEndCondition(_ condition: RecurrenceRuleInput.EndCondition) -> String {
        let _ = languageManager.refreshTrigger
        switch condition {
        case .never: return "끝나지 않음".localized()
        case .endDate: return "특정 날짜".localized()
        case .occurrenceCount: return "횟수 제한".localized()
        }
    }
    
    /// "종료 날짜" 텍스트를 현지화하여 반환
    private func getLocalizedEndDate() -> String {
        let _ = languageManager.refreshTrigger
        return "종료 날짜".localized()
    }
    
    /// "총" 텍스트를 현지화하여 반환
    private func getLocalizedTotal() -> String {
        let _ = languageManager.refreshTrigger
        return "총".localized()
    }
    
    /// "횟수" 텍스트를 현지화하여 반환
    private func getLocalizedCount() -> String {
        let _ = languageManager.refreshTrigger
        return "횟수".localized()
    }
    
    /// "회" 텍스트를 현지화하여 반환
    private func getLocalizedTimes() -> String {
        let _ = languageManager.refreshTrigger
        return "회".localized()
    }
    
    /// 네비게이션 제목을 현지화하여 반환
    private func getLocalizedTitle() -> String {
        let _ = languageManager.refreshTrigger
        return "반복 설정".localized()
    }
    
    /// "취소" 버튼 텍스트를 현지화하여 반환
    private func getLocalizedCancel() -> String {
        let _ = languageManager.refreshTrigger
        return "취소".localized()
    }
    
    /// "완료" 버튼 텍스트를 현지화하여 반환
    private func getLocalizedDone() -> String {
        let _ = languageManager.refreshTrigger
        return "완료".localized()
    }
    
    /// 현지화된 요일 기호를 반환
    private func getLocalizedWeekdaySymbols() -> [String] {
        let _ = languageManager.refreshTrigger
        
        let symbols: [String]
        switch languageManager.currentLanguage {
        case .korean:
            symbols = ["일", "월", "화", "수", "목", "금", "토"]
        case .english:
            symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        case .japanese:
            symbols = ["日", "月", "火", "水", "木", "金", "土"]
        }
        
        if settings.weekStartsOnMonday {
            // 월요일부터 시작: [월, 화, 수, 목, 금, 토, 일]
            return Array(symbols[1...]) + [symbols[0]]
        } else {
            // 일요일부터 시작: [일, 월, 화, 수, 목, 금, 토]
            return symbols
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
