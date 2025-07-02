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

    @StateObject private var vm: VM
    var onSave: () -> Void

    private var minDate: Date { Calendar.current.startOfDay(for: .now) }
    private var maxDate: Date { Calendar.current.date(byAdding: .day, value: 2, to: minDate)! }

    @State private var selected: AddSheetMode = .event
    @State private var showDiscardAlert = false
    @State private var expandedSection: ExpandableSection? = nil

    enum ExpandableSection: CaseIterable {
        case details, alarms, recurrence, calendar, priority
        
        // 모드에 따라 다른 제목 반환하는 메서드 추가
        func title(for mode: AddSheetMode) -> String {
            switch self {
            case .details: return String(localized: "상세 정보")
            case .alarms: return String(localized: "알림")
            case .recurrence: return String(localized: "반복")
            case .calendar:
                return mode == .reminder ? String(localized: "목록") : String(localized: "캘린더")
            case .priority: return String(localized: "우선순위")
            }
        }
        
        // 리마인더 모드에서 사용할 섹션들
        static var reminderSections: [ExpandableSection] {
            [.details, .alarms, .priority, .calendar]
        }
        
        // 일정 모드에서 사용할 섹션들
        static var eventSections: [ExpandableSection] {
            [.details, .alarms, .recurrence, .calendar]
        }
    }
    
    // MARK: - Dirty Check
    private var isDirty: Bool {
        vm.hasChanges
    }

    init(vm: VM, onSave: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: vm)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !vm.isEdit { headerFilterView }

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
            .background(Color(hexCode: "FFFCF5"))
            .toolbar { leadingToolbar; toolbarTitle; saveToolbar }
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(vm.isEdit ? "편집 내용이 저장되지 않습니다." : "작성 내용이 저장되지 않습니다.",
                                isPresented: $showDiscardAlert) {
                Button(vm.isEdit ? "편집 취소하기" : "저장 안 하고 닫기", role: .destructive) { dismiss() }
                Button(vm.isEdit ? "계속 편집" : "계속 작성", role: .cancel) {}
            }
        }
        .interactiveDismissDisabled(isDirty || vm.isSaving)
        .onAppear {
            selected = vm.mode
        }
    }

    // MARK: - Header
    private var headerFilterView: some View {
        HStack(spacing: 0) {
            ForEach(AddSheetMode.allCases) { seg in
                VStack(spacing: 4) {
                    Text(seg.localized)
                        .font(.pretendardBold(size: 16))
                        .foregroundStyle(selected == seg ? Color(hexCode: "A76545") : .secondary)
                    ZStack {
                        Capsule().fill(Color.clear).frame(height: 3)
                        if selected == seg {
                            Capsule()
                                .fill(Color(hexCode: "A76545"))
                                .frame(height: 3)
                                .matchedGeometryEffect(id: "indicator", in: indicatorNS)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .contentShape(.rect)
                .onTapGesture { withAnimation(.spring()) { selected = seg } }
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    // MARK: - Event Page
    private var eventPage: some View {
        ScrollView {
            VStack {
                // 기본 정보
                basicEventInfo
                
                // 확장 가능한 섹션들
                expandableSections
                
                footerError
            }
            .padding(20)
            .contentShape(Rectangle())
//            .onTapGesture {
//                isTextFieldFocused = false
//                expandedSection = nil
//            }
        }
    }

    // MARK: - Reminder Page
    private var reminderPage: some View {
        ScrollView {
            VStack {
                // 기본 정보
                basicReminderInfo
                
                // 확장 가능한 섹션들 (리마인더용)
                reminderExpandableSections
                
                footerError
            }
            .padding(20)
            .contentShape(Rectangle())
            .onTapGesture {
                isTextFieldFocused = false
//                expandedSection = nil
            }
        }
    }

    // MARK: - Basic Info Sections
    private var basicEventInfo: some View {
        VStack(spacing: 20) {
            commonTitleField
            
            HStack {
                if Calendar.current.compare(vm.startDate, to: .now, toGranularity: .day) == .orderedDescending {
                    Text("내일/모레 일정은 홈에서 보이지 않아요!")
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(Color.red)
                } else {
                    Text("날짜는 이틀 후까지만 선택 가능합니다.")
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(Color(hexCode: "A76545"))
                }
                
                Spacer()
                
                Text("하루 종일")
                    .font(.pretendardSemiBold(size: 16))
                Toggle("", isOn: $vm.isAllDay)
                    .toggleStyle(HaruToggleStyle())
                    .padding(.horizontal, 5)
            }
            
            EventDateTimePicker(
                startDate: $vm.startDate,
                endDate: $vm.endDate,
                isAllDay: $vm.isAllDay,
                isTextFieldFocused: $isTextFieldFocused,
                minDate: minDate,
                maxDate: maxDate
            )
            
            Divider()
                .padding(.top, 8)
        }
    }
    
    private var basicReminderInfo: some View {
        VStack(alignment: .leading, spacing: 20) {
            commonTitleField
            
            HStack {
                if let dueDate = vm.dueDate, Calendar.current.compare(dueDate, to: .now, toGranularity: .day) == .orderedDescending {
                    Text("내일/모레 할 일은 홈에서 보이지 않아요!")
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(Color.red)
                } else {
                    Text("날짜는 이틀 후까지만 선택 가능합니다.")
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(Color(hexCode: "A76545"))
                }
                
                Spacer()
            }
            
            ReminderDueDatePicker(dueDate: $vm.dueDate,
                                  includeTime: $vm.includeTime,
                                  isTextFieldFocused: $isTextFieldFocused,
                                  minDate: minDate,
                                  maxDate: maxDate)
            
            Divider()
                .padding(.top, 8)
        }
    }

    // MARK: - Expandable Sections
    // expandableSections 메서드도 모드에 따라 다른 섹션 사용
    private var expandableSections: some View {
        VStack(spacing: 16) {
            let sections = vm.mode == .event ? ExpandableSection.eventSections : ExpandableSection.reminderSections
            ForEach(sections, id: \.self) { section in
                if vm.mode == .event {
                    expandableSection(for: section)
                } else {
                    reminderExpandableSection(for: section)
                }
            }
        }
    }
    
    private var reminderExpandableSections: some View {
        VStack(spacing: 16) {
            ForEach(ExpandableSection.reminderSections, id: \.self) { section in
                reminderExpandableSection(for: section)
            }
        }
    }
    
    @ViewBuilder
    private func expandableSection(for section: ExpandableSection) -> some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Text(section.title(for: vm.mode))  // 모드에 따른 제목 사용
                    .font(.pretendardSemiBold(size: 17))
                
                Spacer()
                
                // 상태 표시
                sectionStatusView(for: section)
                
                Button {
                    if expandedSection == section {
                        expandedSection = nil
                    } else {
                        expandedSection = section
                        isTextFieldFocused = false
                    }
                } label: {
                    Image(systemName: expandedSection == section ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hexCode: "A76545"))
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                if expandedSection == section {
                    expandedSection = nil
                } else {
                    expandedSection = section
                    isTextFieldFocused = false
                }
            }
            
            // 내용 (일정용)
            if expandedSection == section {
                VStack(spacing: 12) {
                    switch section {
                    case .details:
                        detailsSection
                    case .alarms:
                        AlarmSelectionView(alarms: $vm.alarms)
                    case .recurrence:
                        RecurrenceSelectionView(recurrenceRule: $vm.recurrenceRule)
                    case .calendar:
                        CalendarSelectionView(selectedCalendar: $vm.selectedCalendar,
                                            availableCalendars: vm.availableCalendars)
                    case .priority:
                        // 일정에서는 우선순위 섹션 사용하지 않음
                        EmptyView()
                    }
                }
                .padding(.top, 8)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            
            // 구분선
            if section != ExpandableSection.eventSections.last {
                Divider()
                    .padding(.top, 12)
            }
        }
    }
    
    @ViewBuilder
    private func reminderExpandableSection(for section: ExpandableSection) -> some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Text(section.title(for: .reminder))  // 리마인더 모드로 제목 설정
                    .font(.pretendardSemiBold(size: 17))
                
                Spacer()
                
                // 상태 표시
                reminderSectionStatusView(for: section)
                
                Button {
                    if expandedSection == section {
                        expandedSection = nil
                    } else {
                        expandedSection = section
                        isTextFieldFocused = false
                    }
                } label: {
                    Image(systemName: expandedSection == section ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hexCode: "A76545"))
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                if expandedSection == section {
                    expandedSection = nil
                } else {
                    expandedSection = section
                    isTextFieldFocused = false
                }
            }
            
            // 내용
            if expandedSection == section {
                VStack(spacing: 12) {
                    switch section {
                    case .details:
                        reminderDetailsSection
                    case .alarms:
                        ReminderAlarmSelectionView(alarms: $vm.reminderAlarms)
                    case .priority:
                        PrioritySelectionView(selectedPriority: $vm.reminderPriority)
                    case .calendar:
                        ReminderCalendarSelectionView(
                            selectedCalendar: $vm.selectedReminderCalendar,
                            availableCalendars: vm.availableReminderCalendars
                        )
                    default:
                        EmptyView()
                    }
                }
                .padding(.top, 8)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            
            // 구분선
            if section != ExpandableSection.reminderSections.last {
                Divider()
                    .padding(.top, 12)
            }
        }
    }
    
    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(spacing: 16) {
            LocationInputView(location: $vm.location)
            URLInputView(url: $vm.url)
            NotesInputView(notes: $vm.notes)
        }
    }
    
    // 리마인더 상세 정보 섹션
    private var reminderDetailsSection: some View {
        VStack(spacing: 16) {
            ReminderDetailInputViews.LocationInputView(location: $vm.reminderLocation)
            ReminderDetailInputViews.URLInputView(url: $vm.reminderURL)
            ReminderDetailInputViews.NotesInputView(notes: $vm.reminderNotes)
        }
    }
    
    @ViewBuilder
    private func sectionStatusView(for section: ExpandableSection) -> some View {
        switch section {
        case .details:
            if !vm.location.isEmpty || !vm.url.isEmpty || !vm.notes.isEmpty {
                HStack(spacing: 4) {
                    if !vm.location.isEmpty {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hexCode: "A76545"))
                    }
                    if !vm.url.isEmpty {
                        Image(systemName: "link")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hexCode: "A76545"))
                    }
                    if !vm.notes.isEmpty {
                        Image(systemName: "note.text")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hexCode: "A76545"))
                    }
                }
            }
        case .alarms:
            if !vm.alarms.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hexCode: "A76545"))
                    Text("\(vm.alarms.count)")
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
        case .recurrence:
            if vm.recurrenceRule != nil {
                Image(systemName: "repeat")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hexCode: "A76545"))
            }
        case .calendar:
            if let calendar = vm.selectedCalendar {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(calendar.color))
                        .frame(width: 8, height: 8)
                    Text(calendar.title)
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        case .priority:
            // 일정에서는 우선순위 표시하지 않음
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func reminderSectionStatusView(for section: ExpandableSection) -> some View {
        switch section {
        case .details:
            if !vm.reminderLocation.isEmpty || !vm.reminderURL.isEmpty || !vm.reminderNotes.isEmpty {
                HStack(spacing: 4) {
                    if !vm.reminderLocation.isEmpty {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hexCode: "A76545"))
                    }
                    if !vm.reminderURL.isEmpty {
                        Image(systemName: "link")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hexCode: "A76545"))
                    }
                    if !vm.reminderNotes.isEmpty {
                        Image(systemName: "note.text")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hexCode: "A76545"))
                    }
                }
            }
        case .alarms:
            if !vm.reminderAlarms.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hexCode: "A76545"))
                    Text("\(vm.reminderAlarms.count)")
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
        case .priority:
            if vm.reminderPriority > 0 {
                let priority = ReminderInput.Priority(rawValue: vm.reminderPriority) ?? .none
                HStack(spacing: 4) {
                    Image(systemName: priority.symbolName)
                        .font(.system(size: 12))
                        .foregroundStyle(priority.color)
                    Text(priority.localizedDescription)
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        case .calendar:
            if let calendar = vm.selectedReminderCalendar {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(calendar.color))
                        .frame(width: 8, height: 8)
                    Text(calendar.title)
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Common Components
    private var commonTitleField: some View {
        VStack(alignment: .leading, spacing: 15) {
            HaruTextField(text: $vm.currentTitle, placeholder: String(localized: "제목 입력"))
                .focused($isTextFieldFocused)
        }
    }

    private var footerError: some View {
        Group {
            if let e = vm.error {
                Text(String(format: NSLocalizedString("⚠️ 오류: %@", comment: ""), e.localizedDescription))
                    .font(.jakartaRegular(size: 14))
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Toolbar
    private var leadingToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button { isDirty ? (showDiscardAlert = true) : dismiss() } label: {
                Text("취소").font(.pretendardSemiBold(size: 16)).foregroundStyle(.red.opacity(0.8))
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
                        if vm.error == nil { dismiss(); onSave() }
                    }
                } label: {
                    Text("저장").font(.pretendardSemiBold(size: 16))
                        .foregroundStyle(vm.currentTitle.isEmpty ? .secondary : Color.blue.opacity(0.8))
                }
                .disabled(vm.currentTitle.isEmpty)
            }
        }
    }
    
    private var toolbarTitle: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            let key = vm.isEdit ? "%@ 편집" : "%@ 추가"
            Text(String(format: NSLocalizedString(key, comment: ""), vm.mode.localized))
                .font(.pretendardSemiBold(size: 18))
        }
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
    
    var reminderPriority: Int = 0
    var reminderNotes: String = ""
    var reminderURL: String = ""
    var reminderLocation: String = ""
    var reminderAlarms: [AlarmInput] = []
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
    AddSheet(vm: MockAddVM(), onSave: {})
}
#endif




