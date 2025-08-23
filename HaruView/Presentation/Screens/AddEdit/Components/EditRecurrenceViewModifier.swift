//
//  EditRecurrenceViewModifier.swift
//  HaruView
//
//  Created by Claude on 7/14/25.
//

import SwiftUI

struct EditRecurrenceViewModifier<VM: AddSheetViewModelProtocol>: ViewModifier {
    @ObservedObject var vm: VM
    @State private var internalShowEditDialog = false
    @State private var internalShowDeleteDialog = false
    
    func body(content: Content) -> some View {
        if let editVM = vm as? EditSheetViewModel {
            content
                .alert(
                    "반복 일정 편집".localized(),
                    isPresented: $internalShowEditDialog,
                    actions: {
                        Button("이 이벤트만 편집".localized()) {
                            editVM.editEventWithSpan(.thisEventOnly)
                        }
                        
                        Button("이후 모든 이벤트 편집".localized()) {
                            editVM.editEventWithSpan(.futureEvents)
                        }
                        
                        Button("취소".localized(), role: .cancel) {
                            editVM.cancelEventEdit()
                        }
                    },
                    message: {
                        LocalizedText(key: "반복 일정입니다. 어떻게 편집하시겠습니까?")
                    }
                )
                .alert(
                    "반복 일정 삭제".localized(),
                    isPresented: $internalShowDeleteDialog,
                    actions: {
                        Button("이 이벤트만 삭제".localized()) {
                            editVM.deleteEventWithSpan(.thisEventOnly)
                        }
                        
                        Button("이후 모든 이벤트 삭제".localized(), role: .destructive) {
                            editVM.deleteEventWithSpan(.futureEvents)
                        }
                        
                        Button("취소".localized(), role: .cancel) {
                            editVM.cancelEventDelete()
                        }
                    },
                    message: {
                        LocalizedText(key: "반복 일정입니다. 어떻게 삭제하시겠습니까?")
                    }
                )
                .onChange(of: editVM.showRecurringEditOptions) { _, newValue in
                    if newValue {
                        internalShowEditDialog = true
                    }
                }
                .onChange(of: editVM.showRecurringDeleteOptions) { _, newValue in
                    if newValue {
                        internalShowDeleteDialog = true
                    }
                }
                .onChange(of: internalShowEditDialog) { _, newValue in
                    // dialog가 닫혔을 때만 처리
                    if !newValue {
                        Task { @MainActor in
                            editVM.showRecurringEditOptions = false
                        }
                    }
                }
                .onChange(of: internalShowDeleteDialog) { _, newValue in
                    // dialog가 닫혔을 때만 처리
                    if !newValue {
                        Task { @MainActor in
                            editVM.showRecurringDeleteOptions = false
                        }
                    }
                }
        } else {
            content
        }
    }
}