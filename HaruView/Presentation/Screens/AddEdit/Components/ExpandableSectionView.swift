//
//  ExpandableSectionView.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import SwiftUI

enum ExpandableSection: CaseIterable {
    case details, alarms, recurrence, calendar, priority
    
    // 모드에 따라 다른 제목 반환하는 메서드 추가 (LanguageManager 의존성 필요)
    func title(for mode: AddSheetMode, languageManager: LanguageManager) -> String {
        // languageManager의 refreshTrigger 의존성 생성
        let _ = languageManager.refreshTrigger
        
        switch self {
        case .details: return "상세 정보".localized()
        case .alarms: return "알림".localized()
        case .recurrence: return "반복".localized()
        case .calendar:
            return mode == .reminder ? "목록".localized() : "캘린더".localized()
        case .priority: return "우선순위".localized()
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
    @EnvironmentObject private var languageManager: LanguageManager
    
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
                Text(section.title(for: mode, languageManager: languageManager))
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
                        .foregroundStyle(.haruPrimary)
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
                Text(section.title(for: .reminder, languageManager: languageManager))
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
                        .foregroundStyle(.haruPrimary)
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
                        ReminderAlarmSelectionView(
                            alarms: $vm.reminderAlarms,
                            alarmPreset: $vm.reminderAlarmPreset,
                            dueDate: vm.dueDate,
                            includeTime: vm.includeTime
                        )
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
