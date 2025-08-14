//
//  SectionStatusView.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import SwiftUI

struct SectionStatusView<VM: AddSheetViewModelProtocol>: View {
    let section: ExpandableSection
    @ObservedObject var vm: VM
    let mode: AddSheetMode
    
    var body: some View {
        Group {
            if mode == .event {
                eventSectionStatusView
            } else {
                reminderSectionStatusView
            }
        }
    }
    
    @ViewBuilder
    private var eventSectionStatusView: some View {
        switch section {
        case .details:
            if !vm.location.isEmpty || !vm.url.isEmpty || !vm.notes.isEmpty {
                HStack(spacing: 4) {
                    if !vm.location.isEmpty {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.haruPrimary)
                    }
                    if !vm.url.isEmpty {
                        Image(systemName: "link")
                            .font(.system(size: 12))
                            .foregroundStyle(.haruPrimary)
                    }
                    if !vm.notes.isEmpty {
                        Image(systemName: "note.text")
                            .font(.system(size: 12))
                            .foregroundStyle(.haruPrimary)
                    }
                }
            }
        case .alarms:
            if !vm.alarms.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.haruPrimary)
                    Text("\(vm.alarms.count)")
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
        case .recurrence:
            if vm.recurrenceRule != nil {
                Image(systemName: "repeat")
                    .font(.system(size: 12))
                    .foregroundStyle(.haruPrimary)
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
    private var reminderSectionStatusView: some View {
        switch section {
        case .details:
            if !vm.reminderLocation.isEmpty || !vm.reminderURL.isEmpty || !vm.reminderNotes.isEmpty {
                HStack(spacing: 4) {
                    if !vm.reminderLocation.isEmpty {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.haruPrimary)
                    }
                    if !vm.reminderURL.isEmpty {
                        Image(systemName: "link")
                            .font(.system(size: 12))
                            .foregroundStyle(.haruPrimary)
                    }
                    if !vm.reminderNotes.isEmpty {
                        Image(systemName: "note.text")
                            .font(.system(size: 12))
                            .foregroundStyle(.haruPrimary)
                    }
                }
            }
        case .alarms:
            if !vm.reminderAlarms.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.haruPrimary)
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
}
