//
//  AddSheet.swift
//  HaruView
//
//  Created by 김효석 on 5/2/25.
//

import SwiftUI

struct AddSheet<VM: AddSheetViewModelProtocol>: View {
    @Environment(\.dismiss) private var dismiss
    @Namespace private var indicatorNS
    @FocusState private var isTextFieldFocused: Bool
    @EnvironmentObject private var languageManager: LanguageManager

    @StateObject private var vm: VM
    var onSave: (Bool) -> Void // Bool: 삭제 여부 (true: 삭제, false: 저장)

    // 날짜 제한 해제: 과거 날짜도 허용하고 미래 날짜 범위 확장
    private var minDate: Date {
        Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date.distantPast
    }
    private var maxDate: Date {
        Calendar.current.date(byAdding: .year, value: 10, to: Date()) ?? Date.distantFuture
    }

    @State private var selected: AddSheetMode = .event
    @State private var showDiscardAlert = false
    @State private var expandedSection: ExpandableSection? = nil
    
    // MARK: - Dirty Check
    private var isDirty: Bool {
        vm.hasChanges
    }

    init(vm: VM, onSave: @escaping (Bool) -> Void) {
        _vm = StateObject(wrappedValue: vm)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !vm.isEdit {
                    AddSheetHeader(
                        selected: $selected,
                        indicatorNS: indicatorNS
                    )
                }

                if vm.isEdit {
                    if vm.mode == .event {
                        eventPage
                    } else {
                        reminderPage
                    }
                } else {
                    TabView(selection: $selected) {
                        eventPage.tag(AddSheetMode.event)
                        reminderPage.tag(AddSheetMode.reminder)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .onChange(of: selected) { _, newValue in
                        vm.mode = newValue
                        isTextFieldFocused = false
                        expandedSection = nil
                    }
                }
            }
            .background(.haruBackground)
            .toolbar { leadingToolbar; toolbarTitle; saveToolbar }
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(getDiscardMessage(),
                                isPresented: $showDiscardAlert) {
                Button(getDiscardButtonText(), role: .destructive) { dismiss() }
                Button(getContinueButtonText(), role: .cancel) {}
            }
            .confirmationDialog(
                getDeleteConfirmationMessage(),
                isPresented: Binding<Bool>(
                    get: { 
                        if let editVM = vm as? EditSheetViewModel {
                            return editVM.showDeleteConfirmation
                        }
                        return false
                    },
                    set: { newValue in 
                        if let editVM = vm as? EditSheetViewModel, !newValue {
                            editVM.cancelDelete()
                        }
                    }
                )
            ) {
                Button("delete".localized(), role: .destructive) {
                    if let editVM = vm as? EditSheetViewModel {
                        Task {
                            await editVM.confirmDelete()
                        }
                    }
                }
                Button("cancel".localized(), role: .cancel) {
                    if let editVM = vm as? EditSheetViewModel {
                        editVM.cancelDelete()
                    }
                }
            } message: {
                LocalizedText(key: "삭제된 항목은 복구할 수 없습니다.")
            }
        }
        .interactiveDismissDisabled(isDirty || vm.isSaving)
        .modifier(EditRecurrenceViewModifier(vm: vm))
        .onAppear {
            selected = vm.mode
        }
        .onChange(of: vm.saveCompleted) { _, newValue in
            if newValue && vm.error == nil && !vm.showRecurringEditOptions {
                dismiss()
                onSave(false) // 저장 완료
            }
        }
        .onChange(of: (vm as? EditSheetViewModel)?.deleteCompleted) { _, newValue in
            if newValue == true {
                dismiss()
                onSave(true) // 삭제 완료
            }
        }
    }

    // MARK: - Event Page
    private var eventPage: some View {
        ScrollView {
            VStack {
                // 기본 정보
                BasicEventInfoSection(
                    vm: vm,
                    isTextFieldFocused: $isTextFieldFocused,
                    minDate: minDate,
                    maxDate: maxDate
                )
                
                // 확장 가능한 섹션들
                ExpandableSectionView(
                    vm: vm,
                    expandedSection: $expandedSection,
                    isTextFieldFocused: $isTextFieldFocused,
                    mode: .event
                )
                
                footerError
                
                // 편집 모드에서만 삭제 버튼 표시
                if vm is EditSheetViewModel {
                    deleteButton
                }
            }
            .padding(20)
            .contentShape(Rectangle())
        }
    }

    // MARK: - Reminder Page
    private var reminderPage: some View {
        ScrollView {
            VStack {
                // 기본 정보
                BasicReminderInfoSection(
                    vm: vm,
                    isTextFieldFocused: $isTextFieldFocused,
                    minDate: minDate,
                    maxDate: maxDate
                )
                
                // 확장 가능한 섹션들
                ExpandableSectionView(
                    vm: vm,
                    expandedSection: $expandedSection,
                    isTextFieldFocused: $isTextFieldFocused,
                    mode: .reminder
                )
                
                footerError
                
                // 편집 모드에서만 삭제 버튼 표시
                if vm is EditSheetViewModel {
                    deleteButton
                }
            }
            .padding(20)
            .contentShape(Rectangle())
            .onTapGesture {
                isTextFieldFocused = false
            }
        }
    }
    
    private var footerError: some View {
        Group {
            if let e = vm.error {
                Text(String(format: getErrorFormat(), e.localizedDescription))
                    .font(.jakartaRegular(size: 14))
                    .foregroundStyle(.red)
            }
        }
    }
    
    /// 오류 메시지 포맷을 현지화하여 반환
    private func getErrorFormat() -> String {
        return "error_format".localized()
    }
    
    @ViewBuilder
    private var deleteButton: some View {
        if let editVM = vm as? EditSheetViewModel {
            VStack(spacing: 0) {
                // 구분선
                Divider()
                    .padding(.vertical, 20)
                
                // 삭제 버튼
                Button {
                    editVM.requestDelete()
                } label: {
                    HStack {
                        if editVM.isDeleting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .padding(.trailing, 8)
                        }
                        
                        LocalizedText(key: vm.mode == .event ? "일정 삭제" : "할일 삭제")
                            .font(.pretendardSemiBold(size: 16))
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.red.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(editVM.isDeleting)
            }
        }
    }

    // MARK: - Toolbar
    private var leadingToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button { isDirty ? (showDiscardAlert = true) : dismiss() } label: {
                LocalizedText(key: "취소").font(.pretendardSemiBold(size: 16)).foregroundStyle(.red.opacity(0.8))
            }
        }
    }
    
    private var saveToolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            if vm.isSaving {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Button {
                    Task {
                        await vm.save()
                        // 저장 후 즉시 시트를 닫지 않음 - saveCompleted onChange에서 처리
                    }
                } label: {
                    LocalizedText(key: "저장").font(.pretendardSemiBold(size: 16))
                        .foregroundStyle(vm.currentTitle.isEmpty ? .secondary : Color.blue.opacity(0.8))
                }
                .disabled(vm.currentTitle.isEmpty)
            }
        }
    }
    
    private var toolbarTitle: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack(spacing: 4) {
                if vm.isEdit {
                    LocalizedText(key: "edit")
                } else {
                    LocalizedText(key: "add")
                }
                LocalizedText(key: vm.mode == .event ? "event" : "reminder")
            }
            .font(.pretendardSemiBold(size: 18))
        }
    }
    
    // MARK: - Helper Methods
    
    /// 작성 취소 메시지를 현지화하여 반환
    private func getDiscardMessage() -> String {
        return (vm.isEdit ? "unsaved_edit_changes" : "unsaved_new_changes").localized()
    }
    
    /// 취소 버튼 텍스트를 현지화하여 반환
    private func getDiscardButtonText() -> String {
        return (vm.isEdit ? "cancel_edit" : "close_without_saving").localized()
    }
    
    /// 계속 버튼 텍스트를 현지화하여 반환
    private func getContinueButtonText() -> String {
        return (vm.isEdit ? "continue_editing" : "continue_writing").localized()
    }
    
    /// 삭제 확인 메시지를 현지화하여 반환
    private func getDeleteConfirmationMessage() -> String {
        return (vm.mode == .event ? "confirm_delete_event" : "confirm_delete_reminder").localized()
    }
    
    /// 일반 텍스트를 현지화하여 반환
    private func getLocalizedText(_ key: String) -> String {
        return key.localized()
    }
    
}

// MARK: - Preview
#if DEBUG
private class MockAddVM: AddSheetViewModelProtocol {
    var hasChanges: Bool = false
    var isEdit: Bool = false
    var currentTitle: String = ""
    var location: String = ""
    var notes: String = ""
    var url: String = ""
    var alarms: [AlarmInput] = []
    var recurrenceRule: RecurrenceRuleInput? = nil
    var selectedCalendar: EventCalendar? = nil
    var availableCalendars: [EventCalendar] = []
    
    var reminderType: ReminderType? = nil
    var reminderPriority: Int = 0
    var reminderNotes: String = ""
    var reminderURL: String = ""
    var reminderLocation: String = ""
    var reminderAlarms: [AlarmInput] = []
    var reminderAlarmPreset: ReminderAlarmPreset? = nil
    var selectedReminderCalendar: ReminderCalendar? = nil
    var availableReminderCalendars: [ReminderCalendar] = []
    
    @Published var mode: AddSheetMode = .event
    @Published var title: String = ""
    @Published var startDate: Date = .now
    @Published var endDate: Date = .now
    @Published var dueDate: Date? = nil
    @Published var error: TodayBoardError? = nil
    @Published var isSaving: Bool = false
    @Published var isAllDay: Bool = false
    @Published var includeTime: Bool = false
    
    func save() async {}
    func addAlarm(_ alarm: AlarmInput) {}
    func removeAlarm(at index: Int) {}
    func setRecurrenceRule(_ rule: RecurrenceRuleInput?) {}
    
    func addReminderAlarm(_ alarm: AlarmInput) {}
    func removeReminderAlarm(at index: Int) {}
    func setReminderPriority(_ priority: Int) {}
}

#Preview {
    AddSheet(vm: MockAddVM(), onSave: { _ in })
}
#endif



