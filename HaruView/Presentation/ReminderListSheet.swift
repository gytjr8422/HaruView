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
                VStack {
                    ForEach(vm.reminders) { reminder in
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
                        
                        if vm.reminders.last != reminder {
                            Divider()
                        }
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
            AddSheet(vm: di.makeEditSheetVM(reminder: rem)) {
                vm.refresh()
            }
        }
    }
    
    private var navigationTitleView: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("오늘 할 일")
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
