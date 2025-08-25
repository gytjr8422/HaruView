//
//  ReminderListSheet.swift
//  HaruView
//
//  Created by 김효석 on 5/7/25.
//

import SwiftUI

struct ReminderListSheet<VM: ReminderListViewModelProtocol>: View {
    @Environment(\.scenePhase) private var phase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.di) private var di
    @StateObject var vm: VM
    @State private var editingReminder: Reminder?
    
    init(vm: VM) {
        _vm = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // 오늘 표시되는 할 일 섹션
                    if !todayReminders.isEmpty {
                        sectionHeader(title: "today_reminders", count: todayReminders.count)
                        
                        VStack(spacing: 0) {
                            ForEach(Array(todayReminders.enumerated()), id: \.element.id) { index, reminder in
                                reminderRow(reminder: reminder)
                                
                                if index < todayReminders.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    
                    Divider()
                    
                    // 마감일 없는 할 일 섹션
                    if !noDeadlineReminders.isEmpty {
                        sectionHeader(title: "anytime_reminders", count: noDeadlineReminders.count)
                        
                        VStack(spacing: 0) {
                            ForEach(Array(noDeadlineReminders.enumerated()), id: \.element.id) { index, reminder in
                                reminderRow(reminder: reminder)
                                
                                if index < noDeadlineReminders.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.bottom, 24)
                    }
                    
                    // 빈 상태 표시
                    if todayReminders.isEmpty && noDeadlineReminders.isEmpty {
                        emptyStateView
                            .padding(.top, 60)
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(.haruBackground)
            .toolbar { navigationTitleView; exitButton }
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
        }
        .onAppear { vm.load() }
        .onChange(of: phase) {
            if phase == .active { vm.refresh() }
        }
        .refreshable { vm.refresh() }
        .sheet(item: $editingReminder) { rem in
            AddSheet(vm: di.makeEditSheetVM(reminder: rem)) { isDeleted in
                ToastManager.shared.show(isDeleted ? .delete : .success)
                vm.refresh()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// 오늘 표시될 할 일들 (마감일이 오늘이거나, untilDate 타입으로 오늘까지 표시되는 것들)
    private var todayReminders: [Reminder] {
        let today = Date()
        
        return vm.reminders.filter { reminder in
            guard reminder.due != nil else { return false }
            return reminder.shouldDisplay(on: today)
        }
    }
    
    /// 마감일 없는 할 일들
    private var noDeadlineReminders: [Reminder] {
        return vm.reminders.filter { reminder in
            reminder.due == nil
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            LocalizedText(key: title)
                .font(.pretendardSemiBold(size: 18))
                .foregroundStyle(.haruTextPrimary)
            
            Text("(\(count))")
                .font(.pretendardRegular(size: 16))
                .foregroundStyle(.haruSecondary.opacity(0.7))
            
            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 5)
    }
    
    @ViewBuilder
    private func reminderRow(reminder: Reminder) -> some View {
        ReminderCard(reminder: reminder) {
            Task {
                await vm.toggleReminder(id: reminder.id)
            }
        }
        .contextMenu {
            Button {
                editingReminder = reminder
            } label: {
                Label {
                    LocalizedText(key: "편집").font(Font.pretendardRegular(size: 14))
                } icon: {
                    Image(systemName: "pencil")
                }
            }
            Button(role: .destructive) {
                Task {
                    await vm.delete(id: reminder.id)
                }
            } label: {
                Label {
                    LocalizedText(key: "삭제").font(Font.pretendardRegular(size: 14))
                } icon: {
                    Image(systemName: "trash")
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 50))
                .foregroundStyle(.haruPrimary.opacity(0.6))
            
            VStack(spacing: 8) {
                LocalizedText(key: "no_reminders")
                    .font(.pretendardSemiBold(size: 18))
                    .foregroundStyle(.haruTextPrimary)
                
                LocalizedText(key: "add_new_reminder")
                    .font(.pretendardRegular(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var navigationTitleView: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            LocalizedText(key: "all_reminders")
                .font(.pretendardSemiBold(size: 18))
        }
    }
    
    private var exitButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                dismiss()
            } label: {
                LocalizedText(key: "close")
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(.haruPrimary)
            }
        }
    }
}


//#Preview {
//    ReminderListView()
//}
