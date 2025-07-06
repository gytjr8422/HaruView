//
//  ExpandableSectionView.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import SwiftUI

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

struct ExpandableSectionView<VM: AddSheetViewModelProtocol>: View {
    @ObservedObject var vm: VM
    @Binding var expandedSection: ExpandableSection?
    var isTextFieldFocused: FocusState<Bool>.Binding
    let mode: AddSheetMode
    
    var body: some View {
        VStack(spacing: 16) {
            let sections = mode == .event ? ExpandableSection.eventSections : ExpandableSection.reminderSections
            ForEach(sections, id: \.self) { section in
                if mode == .event {
                    eventExpandableSection(for: section)
                } else {
                    reminderExpandableSection(for: section)
                }
            }
        }
    }
    
    @ViewBuilder
    private func eventExpandableSection(for section: ExpandableSection) -> some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Text(section.title(for: mode))
                    .font(.pretendardSemiBold(size: 17))
                
                Spacer()
                
                // 상태 표시
                SectionStatusView(section: section, vm: vm, mode: mode)
                
                Button {
                    if expandedSection == section {
                        expandedSection = nil
                    } else {
                        expandedSection = section
                        isTextFieldFocused.wrappedValue = false
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
                    isTextFieldFocused.wrappedValue = false
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
                Text(section.title(for: .reminder))
                    .font(.pretendardSemiBold(size: 17))
                
                Spacer()
                
                // 상태 표시
                SectionStatusView(section: section, vm: vm, mode: .reminder)
                
                Button {
                    if expandedSection == section {
                        expandedSection = nil
                    } else {
                        expandedSection = section
                        isTextFieldFocused.wrappedValue = false
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
                    isTextFieldFocused.wrappedValue = false
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
}
