//
//  SheetsModifier.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import SwiftUI

struct SheetsViewModifier<VM: HomeViewModelProtocol>: ViewModifier {
    @Binding var showEventSheet: Bool
    @Binding var showReminderSheet: Bool
    @Binding var showAddSheet: Bool
    @Binding var editingEvent: Event?
    @Binding var editingReminder: Reminder?
    @Binding var showToast: Bool
    
    @ObservedObject var vm: VM
    let di: DIContainer
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showEventSheet) {
                EventListSheet(vm: di.makeEventListVM())
                    .presentationDetents([.fraction(0.75), .fraction(1.0)])
            }
            .sheet(isPresented: $showReminderSheet) {
                ReminderListSheet(vm: di.makeReminderListVM())
                    .presentationDetents([.fraction(0.75), .fraction(1.0)])
            }
            .sheet(isPresented: $showAddSheet) {
                AddSheet(vm: di.makeAddSheetVM()) {
                    showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showToast = false
                    }
                }
                .onDisappear { vm.refresh(.storeChange) }
            }
            .sheet(item: $editingEvent) { event in
                AddSheet(vm: di.makeEditSheetVM(event: event)) {
                    showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showToast = false
                    }
                    vm.refresh(.storeChange)
                }
            }
            .sheet(item: $editingReminder) { rem in
                AddSheet(vm: di.makeEditSheetVM(reminder: rem)) {
                    showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showToast = false
                    }
                    vm.refresh(.storeChange)
                }
            }
    }
}
