//
//  ReminderSections.swift
//  HaruView
//
//  Created by 김효석 on 7/1/25.
//

import SwiftUI

// MARK: - 할일 타입 선택 컴포넌트
struct ReminderTypeSelectionView: View {
    @Binding var selectedType: ReminderType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // 타입 선택 버튼들
            VStack(spacing: 8) {
                ForEach(ReminderType.allCases, id: \.rawValue) { type in
                    Button {
                        selectedType = type
                        
                        // 햅틱 피드백
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    } label: {
                        HStack(spacing: 12) {
                            // 라디오 버튼
                            Image(systemName: selectedType == type ? "largecircle.fill.circle" : "circle")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(selectedType == type ? .haruPrimary : .haruSecondary.opacity(0.5))
                            
                            Image(systemName: type.iconName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(selectedType == type ? .haruPrimary : .haruSecondary)
                                .frame(width: 20, height: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.displayText)
                                    .font(.pretendardRegular(size: 15))
                                    .foregroundStyle(selectedType == type ? .haruTextPrimary : .haruSecondary)
                                
                                Text(type.description)
                                    .font(.pretendardRegular(size: 11))
                                    .foregroundStyle(.haruSecondary.opacity(0.8))
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selectedType == type ? .haruPrimary.opacity(0.05) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    selectedType == type ? .haruPrimary.opacity(0.2) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}


// MARK: - 우선순위 선택 컴포넌트
struct PrioritySelectionView: View {
    @Binding var selectedPriority: Int
    
    private let priorities = ReminderInput.Priority.allCases
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if selectedPriority > 0 {
                HStack {
                    let currentPriority = ReminderInput.Priority(rawValue: selectedPriority) ?? .none
                    
                    HStack(spacing: 8) {
//                        Image(systemName: currentPriority.symbolName)
//                            .font(.system(size: 10))
//                            .foregroundStyle(.white)
                        Text(currentPriority.localizedDescription)
                            .font(.pretendardRegular(size: 14))
                        
                        Spacer()
                        
                        Button {
                            selectedPriority = 0
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(currentPriority.color)
                    )
                }
            } else {
                LocalizedText(key: "우선순위가 설정되지 않았습니다")
                    .font(.pretendardRegular(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
            
            // 우선순위 선택 버튼들
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(priorities.filter { $0 != .none }, id: \.rawValue) { priority in
                    Button {
                        selectedPriority = priority.rawValue
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: priority.symbolName)
                                .foregroundStyle(priority.color)
                            Text(priority.localizedDescription)
                                .font(.pretendardRegular(size: 14))
                                .foregroundStyle(.haruPrimary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(priority.color.opacity(0.1))
                        )
                    }
                    .disabled(selectedPriority == priority.rawValue)
                }
            }
        }
    }
}

// MARK: - 리마인더용 목록 선택 컴포넌트
struct ReminderCalendarSelectionView: View {
    @Binding var selectedCalendar: ReminderCalendar?
    let availableCalendars: [ReminderCalendar]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if availableCalendars.isEmpty {
                LocalizedText(key: "사용 가능한 목록이 없습니다")
                    .font(.pretendardRegular(size: 14))
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(availableCalendars, id: \.id) { calendar in
                        HStack {
                            Circle()
                                .fill(Color(calendar.color))
                                .frame(width: 12, height: 12)
                            
                            Text(calendar.title)
                                .font(.pretendardRegular(size: 16))
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if selectedCalendar?.id == calendar.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.haruPrimary)
                                    .font(.system(size: 12, weight: .bold))
                            }
                        }
                        .font(.pretendardRegular(size: 12))
                        .foregroundStyle(.haruPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.haruPrimary.opacity(0.1))
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCalendar = calendar
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 리마인더용 상세 정보 입력 뷰들
struct ReminderDetailInputViews {
    
    // 위치 입력 (기존 LocationInputView와 동일하지만 리마인더용)
    struct LocationInputView: View {
        @Binding var location: String
        @State private var showLocationPicker = false
        @EnvironmentObject private var languageManager: LanguageManager
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    LocalizedText(key: "위치")
                        .font(.pretendardSemiBold(size: 16))
//                    Spacer()
//                    Button("빠른 선택") {
//                        showLocationPicker = true
//                    }
//                    .font(.pretendardRegular(size: 14))
//                    .foregroundStyle(.haruPrimary)
                }
                
                HaruTextField(text: $location, placeholder: getLocalizedLocationPlaceholder())
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerSheet(selectedLocation: $location)
            }
        }
        
        private func getLocalizedLocationPlaceholder() -> String {
            return "위치 입력".localized()
        }
    }
    
    // URL 입력
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
    
    // 메모 입력
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
                        Text(getLocalizedNotesPlaceholder())
                            .foregroundStyle(.secondary)
                            .font(.pretendardRegular(size: 16))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        
        private func getLocalizedNotesPlaceholder() -> String {
            return "메모를 입력하세요".localized()
        }
    }
}

// MARK: - 리마인더용 알람 선택 뷰 (프리셋 + 사용자 지원)
struct ReminderAlarmSelectionView: View {
    @Binding var alarms: [AlarmInput]
    @Binding var alarmPreset: ReminderAlarmPreset?
    let dueDate: Date?
    let includeTime: Bool
    @State private var showCustomAlarm = false
    @EnvironmentObject private var languageManager: LanguageManager
    
    private var dueDateMode: DueDateMode {
        if dueDate == nil {
            return .none
        } else if includeTime {
            return .dateTime
        } else {
            return .dateOnly
        }
    }
    
    private var availablePresets: [ReminderAlarmPreset] {
        return ReminderAlarmPreset.availablePresets(for: dueDateMode)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 빠른 설정 섹션 - 날짜+시간 모드에서는 기존 AlarmInput.presets 사용
            if dueDateMode == .dateTime {
                VStack(alignment: .leading, spacing: 12) {
                    Text(getLocalizedQuickSetting())
                        .font(.pretendardSemiBold(size: 16))
                        .foregroundStyle(.haruTextPrimary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(Array(AlarmInput.presets.prefix(5)), id: \.id) { preset in
                            Button {
                                if !alarms.contains(where: { $0.description == preset.description }) {
                                    alarms.append(preset)
                                }
                                alarmPreset = .custom  // 기존 방식 사용 시 사용자 설정으로 설정
                            } label: {
                                Text(getLocalizedDescription(for: preset))
                                    .font(.pretendardRegular(size: 14))
                                    .foregroundStyle(.haruPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.haruPrimary.opacity(0.1))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // 사용자 설정 버튼 추가
                        Button {
                            showCustomAlarm = true
                            alarmPreset = .custom
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.haruPrimary)
                                
                                Text(getLocalizedCustomSetting())
                                    .font(.pretendardRegular(size: 14))
                                    .foregroundStyle(.haruPrimary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.haruPrimary.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            } else {
                // 프리셋 선택 섹션 (없음, 날짜만 모드용)
                VStack(alignment: .leading, spacing: 12) {
                    Text(getLocalizedQuickSetting())
                        .font(.pretendardSemiBold(size: 16))
                        .foregroundStyle(.haruTextPrimary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(availablePresets, id: \.rawValue) { preset in
                            Button {
                                // 프리셋 선택 시 기존 사용자 알림 초기화
                                if preset != .custom {
                                    alarms.removeAll()
                                    alarmPreset = preset
                                } else {
                                    alarmPreset = .custom
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: preset.iconName)
                                        .font(.system(size: 14))
                                        .foregroundStyle(alarmPreset == preset ? .white : .haruPrimary)
                                    
                                    Text(preset.displayText)
                                        .font(.pretendardRegular(size: 13))
                                        .foregroundStyle(alarmPreset == preset ? .white : .haruPrimary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(alarmPreset == preset ? .haruPrimary : .haruPrimary.opacity(0.1))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            
            // 사용자 알림 섹션 (사용자 설정 선택 시 또는 기존 알림이 있을 때)
            if alarmPreset == .custom || !alarms.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(getLocalizedUserAlarms())
                            .font(.pretendardSemiBold(size: 16))
                            .foregroundStyle(.haruTextPrimary)
                        
                        Spacer()
                        
                        Button {
                            showCustomAlarm = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 18))
                                .foregroundStyle(.haruPrimary)
                        }
                    }
                    
                    if alarms.isEmpty {
                        Text(getLocalizedNoAlarms())
                            .font(.pretendardRegular(size: 14))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 8) {
                            HStack {
                                Text(getLocalizedReminderAppNote())
                                    .font(.pretendardRegular(size: 12))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(Array(alarms.enumerated()), id: \.offset) { index, alarm in
                                    HStack {
                                        Text(getLocalizedDescription(for: alarm))
                                            .font(.pretendardRegular(size: 14))
                                        
                                        Spacer()
                                        
                                        Button {
                                            alarms.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 12))
                                        }
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.haruPrimary)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showCustomAlarm) {
            CustomReminderAlarmSheet(alarms: $alarms, dueDateMode: dueDateMode)
                .presentationDetents([.fraction(0.5)])
        }
        .onChange(of: dueDateMode) { oldValue, newValue in
            // 마감일 모드가 바뀌면 적절한 기본 프리셋으로 설정
            if alarmPreset == nil || !availablePresets.contains(alarmPreset!) {
                switch newValue {
                case .none:
                    alarmPreset = .dailyMorning9AM
                case .dateOnly:
                    alarmPreset = Optional.none
                case .dateTime:
                    alarmPreset = .custom
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// 알람 프리셋의 현지화된 설명 텍스트 반환 (언어 변경에 즉시 반응)
    private func getLocalizedDescription(for preset: AlarmInput) -> String {
        switch preset.trigger {
        case .relative(let interval):
            if interval == 0 {
                return "이벤트 시간".localized()
            } else if interval < 0 {
                let minutes = Int(abs(interval) / 60)
                let hours = minutes / 60
                let days = hours / 24
                
                if days > 0 {
                    return "%d일 전".localized(with: days)
                } else if hours > 0 {
                    return "%d시간 전".localized(with: hours)
                } else {
                    return "%d분 전".localized(with: minutes)
                }
            } else {
                let minutes = Int(interval / 60)
                let hours = minutes / 60
                let days = hours / 24
                
                if days > 0 {
                    return "%d일 후".localized(with: days)
                } else if hours > 0 {
                    return "%d시간 후".localized(with: hours)
                } else {
                    return "%d분 후".localized(with: minutes)
                }
            }
        case .absolute(let date):
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: languageManager.currentLanguage.appleLanguageCode)
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Helper Methods
    
    /// "빠른 설정" 텍스트를 현지화하여 반환
    private func getLocalizedQuickSetting() -> String {
        return "빠른 설정".localized()
    }
    
    /// "사용자 설정" 텍스트를 현지화하여 반환
    private func getLocalizedCustomSetting() -> String {
        return "사용자 설정".localized()
    }
    
    /// "사용자 알림" 텍스트를 현지화하여 반환
    private func getLocalizedUserAlarms() -> String {
        return "사용자 알림".localized()
    }
    
    /// "알림이 설정되지 않았습니다" 텍스트를 현지화하여 반환
    private func getLocalizedNoAlarms() -> String {
        return "알림이 설정되지 않았습니다".localized()
    }
    
    /// "미리알림 앱에서 알림이 울려요." 텍스트를 현지화하여 반환
    private func getLocalizedReminderAppNote() -> String {
        return "미리알림 앱에서 알림이 울려요.".localized()
    }
}

// MARK: - 사용자 리마인더 알람 설정 시트
struct CustomReminderAlarmSheet: View {
    @Binding var alarms: [AlarmInput]
    let dueDateMode: DueDateMode
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    
    @State private var triggerMode: TriggerMode = .relative
    
    private var availableTriggerModes: [TriggerMode] {
        switch dueDateMode {
        case .none, .dateOnly:
            return [.absolute] // 절대 시간만 허용
        case .dateTime:
            return TriggerMode.allCases // 모든 옵션 허용
        }
    }
    @State private var relativeMinutes: Int = 15
    @State private var absoluteDate: Date = Date()
    
    enum TriggerMode: String, CaseIterable {
        case relative = "relative"
        case absolute = "absolute"
        
        var displayText: String {
            switch self {
            case .relative:
                return "미리 알림".localized()
            case .absolute:
                return "특정 시간".localized()
            }
        }
        
        var iconName: String {
            switch self {
            case .relative:
                return "clock.badge.questionmark"
            case .absolute:
                return "clock"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 헤더
                HStack {
                    Button("취소".localized()) {
                        dismiss()
                    }
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(.haruPrimary)
                    
                    Spacer()
                    
                    LocalizedText(key: "알림 추가")
                        .font(.pretendardSemiBold(size: 18))
                        .foregroundStyle(.haruTextPrimary)
                    
                    Spacer()
                    
                    Button("추가".localized()) {
                        let trigger: AlarmInput.AlarmTrigger
                        if triggerMode == .relative {
                            trigger = .relative(-TimeInterval(relativeMinutes * 60))
                        } else {
                            trigger = .absolute(absoluteDate)
                        }
                        
                        let alarm = AlarmInput(type: .display, trigger: trigger) // 알림 타입 고정
                        alarms.append(alarm)
                        dismiss()
                    }
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundStyle(.haruPrimary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.haruBackground)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // 컨텐츠
                VStack(spacing: 24) {
                    // 알림 방식 선택 (dateTime 모드에서만 표시)
                    if dueDateMode == .dateTime {
                        VStack(alignment: .leading, spacing: 16) {
                            LocalizedText(key: "알림 방식")
                                .font(.pretendardSemiBold(size: 16))
                                .foregroundStyle(.haruTextPrimary)
                            
                            HStack(spacing: 12) {
                                ForEach(availableTriggerModes, id: \.self) { mode in
                                    Button {
                                        triggerMode = mode
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: mode.iconName)
                                                .font(.system(size: 14))
                                                .foregroundStyle(triggerMode == mode ? .white : .haruPrimary)
                                            
                                            Text(mode.displayText)
                                                .font(.pretendardRegular(size: 14))
                                                .foregroundStyle(triggerMode == mode ? .white : .haruPrimary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(triggerMode == mode ? .haruPrimary : .haruPrimary.opacity(0.1))
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    
                    // 시간 설정
                    VStack(alignment: .leading, spacing: 16) {
                        LocalizedText(key: dueDateMode == .dateTime && triggerMode == .relative ? "몇 분 전에 알림 받을까요?" : "언제 알림 받을까요?")
                            .font(.pretendardSemiBold(size: 16))
                            .foregroundStyle(.haruTextPrimary)
                        
                        if triggerMode == .relative {
                            VStack(spacing: 12) {
                                HStack {
                                    TextField("", value: $relativeMinutes, format: .number)
                                        .keyboardType(.numberPad)
                                        .font(.pretendardRegular(size: 16))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(.haruPrimary.opacity(0.3), lineWidth: 1)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(.haruBackground)
                                                )
                                        )
                                    
                                    LocalizedText(key: "분 전")
                                        .font(.pretendardRegular(size: 16))
                                        .foregroundStyle(.haruTextPrimary)
                                }
                            }
                        } else {
                            VStack(spacing: 12) {
                                DatePicker("", selection: $absoluteDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .environment(\.locale, Locale(identifier: getLocalizedLocaleIdentifier()))
                                    .accentColor(.haruPrimary)
                                    .id(languageManager.currentLanguage)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
            .background(.haruBackground)
        }
        .onAppear {
            // dueDateMode에 따라 적절한 triggerMode로 초기화
            triggerMode = availableTriggerModes.first ?? .relative
        }
    }
    
    // MARK: - Helper Methods
    
    /// 현재 언어에 맞는 로케일 식별자 반환
    private func getLocalizedLocaleIdentifier() -> String {
        return languageManager.currentLanguage.appleLanguageCode
    }
    
    /// 알람 프리셋의 현지화된 설명 텍스트 반환 (언어 변경에 즉시 반응)
    private func getLocalizedDescription(for preset: AlarmInput) -> String {
        
        switch preset.trigger {
        case .relative(let interval):
            if interval == 0 {
                return "이벤트 시간".localized()
            } else if interval < 0 {
                let minutes = Int(abs(interval) / 60)
                let hours = minutes / 60
                let days = hours / 24
                
                if days > 0 {
                    return "%d일 전".localized(with: days)
                } else if hours > 0 {
                    return "%d시간 전".localized(with: hours)
                } else {
                    return "%d분 전".localized(with: minutes)
                }
            } else {
                let minutes = Int(interval / 60)
                let hours = minutes / 60
                let days = hours / 24
                
                if days > 0 {
                    return "%d일 후".localized(with: days)
                } else if hours > 0 {
                    return "%d시간 후".localized(with: hours)
                } else {
                    return "%d분 후".localized(with: minutes)
                }
            }
        case .absolute(let date):
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: languageManager.currentLanguage.appleLanguageCode)
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PrioritySelectionView(selectedPriority: .constant(1))

        ReminderDetailInputViews.URLInputView(url: .constant(""))

        ReminderDetailInputViews.NotesInputView(notes: .constant(""))

        ReminderAlarmSelectionView(
            alarms: .constant([]),
            alarmPreset: .constant(Optional.none),
            dueDate: Date(),
            includeTime: false
        )
    }
    .padding()
}

