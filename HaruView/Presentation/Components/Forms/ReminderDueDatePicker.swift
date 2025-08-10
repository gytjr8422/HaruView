//
//  ReminderDueDatePicker.swift
//  HaruView
//
//  Created by 김효석 on 6/26/25.
//

import SwiftUI

struct ReminderDueDatePicker: View {
    @Binding var dueDate: Date?
    @Binding var includeTime: Bool
    @Binding var reminderType: ReminderType?  // 할일 타입 바인딩 추가
    @State private var selectedMode: DueDateMode = .none
    @State private var selectedField: DateTimeField? = nil
    @State private var internalDate: Date = Date()
    
    var isTextFieldFocused: FocusState<Bool>.Binding
    
    // 날짜 제한 해제: 과거/미래 모든 날짜 허용
    var minDate: Date { Date.distantPast }
    var maxDate: Date { Date.distantFuture }
    
    enum DueDateMode: CaseIterable {
        case none, dateOnly, dateTime
        
        var title: String {
            switch self {
            case .none: return String(localized: "없음")
            case .dateOnly: return String(localized: "날짜만")
            case .dateTime: return String(localized: "날짜+시간")
            }
        }
    }
    
    enum DateTimeField {
        case dueDate
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 3개 버튼
            HStack(spacing: 8) {
                ForEach(DueDateMode.allCases, id: \.self) { mode in
                    Button(action: {
                        selectedMode = mode
                        updateBindings()
                        selectedField = nil
                        isTextFieldFocused.wrappedValue = false
                    }) {
                        Text(mode.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(selectedMode == mode ? .white : Color(hexCode: "A76545"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedMode == mode ? Color(hexCode: "A76545") : Color(hexCode: "A76545").opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                Spacer()
            }
            .padding(.bottom, selectedMode == .none ? 0 : 16)
            
            // 할일 타입 선택 (날짜가 있을 때만 표시)
            if selectedMode != .none {
                ReminderTypeSelectionView(selectedType: Binding(
                    get: { reminderType ?? .onDate },
                    set: { reminderType = $0 }
                ))
                .padding(.bottom, 16)
            }
            
            // 선택된 날짜/시간 표시 (없음이 아닐 때만)
            if selectedMode != .none {
                HStack(spacing: 0) {
                    Button(action: {
                        if selectedField == .dueDate {
                            selectedField = nil
                        } else {
                            selectedField = .dueDate
                        }
                        isTextFieldFocused.wrappedValue = false
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formatDateWithDay(internalDate))
                                .font(.pretendardRegular(size: 15))
                                .foregroundStyle(.secondary)
                            
                            if selectedMode == .dateOnly {
                                HStack {
                                    Text("마감일")
                                        .font(.system(size: 25, weight: .light))
                                        .foregroundStyle(selectedField == .dueDate ? Color(hexCode: "A76545") : .primary)
                                    Spacer()
                                }
                            } else {
                                HStack(alignment: .bottom, spacing: 3) {
                                    Text(formatTime(internalDate))
                                        .font(.system(size: 25, weight: .light))
                                        .foregroundStyle(selectedField == .dueDate ? Color(hexCode: "A76545") : .primary)
                                    Text("마감")
                                        .font(.system(size: 12, weight: .light))
                                        .padding(.bottom, 2)
                                }
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .padding(.horizontal, 15)
            }
            
            // 인라인 피커
            if (selectedField != nil), selectedMode != .none {
                VStack(spacing: 0) {
                    // 구분선
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 0.5)
                        .padding(.horizontal, 20)
                    
                    // 피커 영역
                    VStack(spacing: 0) {
                        CustomDateTimePicker(
                            date: $internalDate,
                            minDate: minDate,
                            maxDate: maxDate,
                            isAllDay: selectedMode == .dateOnly
                        )
                        .frame(height: 200)
                    }
                    .padding(.top, 10)
                }
                .padding(.top, 10)
            }
        }
        .background(Color.clear)
        .onAppear {
            initializeState()
        }
        .onChange(of: internalDate) { _, newValue in
            updateDueDateFromInternal()
        }
        .onChange(of: dueDate) { _, newValue in
            updateInternalFromDueDate()
        }
    }
    
    private func initializeState() {
        if let existingDueDate = dueDate {
            internalDate = existingDueDate
            selectedMode = includeTime ? .dateTime : .dateOnly
        } else {
            internalDate = Date()
            selectedMode = .none
        }
    }
    
    private func updateBindings() {
        switch selectedMode {
        case .none:
            includeTime = false
            dueDate = nil
            reminderType = nil  // 날짜 없을 때는 타입도 nil
        case .dateOnly:
            includeTime = false
            dueDate = internalDate
            if reminderType == nil {
                reminderType = .onDate  // 기본값 설정
            }
        case .dateTime:
            includeTime = true
            dueDate = internalDate
            if reminderType == nil {
                reminderType = .onDate  // 기본값 설정
            }
        }
    }
    
    private func updateDueDateFromInternal() {
        if selectedMode != .none {
            dueDate = internalDate
        }
    }
    
    private func updateInternalFromDueDate() {
        if let newDueDate = dueDate {
            internalDate = newDueDate
        }
    }
    
    private func formatDateWithDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        if Locale.current.language.languageCode?.identifier == "ko" {
            formatter.dateFormat = "M월 d일 (E)"
        } else {
            formatter.dateFormat = "MMM d (E)"
        }
        
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview("Reminder Due Date Picker") {
    struct PreviewWrapper: View {
        @State private var dueDate: Date? = nil  // Optional로 변경
        @State private var includeTime = false
        @FocusState private var isFocused: Bool
        
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("할 일 마감일 설정")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        ReminderDueDatePicker(
                            dueDate: $dueDate,
                            includeTime: $includeTime,
                            reminderType: .constant(.onDate),
                            isTextFieldFocused: $isFocused
                        )
                        .padding(.horizontal, 20)
                        
                        // 디버그 정보
                        VStack(alignment: .leading, spacing: 8) {
                            Text("현재 상태:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("includeTime: \(includeTime ? "true" : "false")")
                                .font(.caption)
                            if let dueDate = dueDate {
                                Text("dueDate: \(dueDate, formatter: debugFormatter)")
                                    .font(.caption)
                            } else {
                                Text("dueDate: nil")
                                    .font(.caption)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
                .background(Color(red: 1.0, green: 0.984, blue: 0.961))
                .navigationTitle("Due Date Setting")
            }
        }
        
        private var debugFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter
        }
    }
    
    return PreviewWrapper()
}
