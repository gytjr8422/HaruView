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
                    // 오늘 마감인 할 일 섹션
                    if !todayReminders.isEmpty {
                        sectionHeader(title: "오늘 할 일", count: todayReminders.count)
                        
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
                        sectionHeader(title: "언제든 할 일", count: noDeadlineReminders.count)
                        
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
            .background(Color(hexCode: "FFFCF5"))
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
    
    /// 오늘 마감인 할 일들
    private var todayReminders: [Reminder] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return vm.reminders.filter { reminder in
            guard let dueDate = reminder.due else { return false }
            let reminderDate = calendar.startOfDay(for: dueDate)
            return calendar.isDate(reminderDate, inSameDayAs: today)
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
            Text(title)
                .font(.pretendardSemiBold(size: 18))
                .foregroundStyle(Color(hexCode: "40392B"))
            
            Text("(\(count))")
                .font(.pretendardRegular(size: 16))
                .foregroundStyle(Color(hexCode: "6E5C49").opacity(0.7))
            
            Spacer()
        }
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
                    Text("편집").font(Font.pretendardRegular(size: 14))
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
                    Text("삭제").font(Font.pretendardRegular(size: 14))
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
                .foregroundStyle(Color(hexCode: "A76545").opacity(0.6))
            
            VStack(spacing: 8) {
                Text("할 일이 없습니다")
                    .font(.pretendardSemiBold(size: 18))
                    .foregroundStyle(Color(hexCode: "40392B"))
                
                Text("새로운 할 일을 추가해보세요!")
                    .font(.pretendardRegular(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var navigationTitleView: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("전체 할 일")
                .font(.pretendardSemiBold(size: 18))
        }
    }
    
    private var exitButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                dismiss()
            } label: {
                Text("닫기")
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(Color(hexCode: "A76545"))
            }
        }
    }
}


//#Preview {
//    ReminderListView()
//}
