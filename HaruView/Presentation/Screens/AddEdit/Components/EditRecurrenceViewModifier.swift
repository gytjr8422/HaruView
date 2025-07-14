//
//  EditRecurrenceViewModifier.swift
//  HaruView
//
//  Created by Claude on 7/14/25.
//

import SwiftUI

struct EditRecurrenceViewModifier<VM: AddSheetViewModelProtocol>: ViewModifier {
    @ObservedObject var vm: VM
    @State private var internalShowDialog = false
    
    func body(content: Content) -> some View {
        if let editVM = vm as? EditSheetViewModel {
            content
                .alert(
                    "반복 일정 편집",
                    isPresented: $internalShowDialog,
                    actions: {
                        Button("이 이벤트만 편집") {
                            print("DEBUG: '이 이벤트만 편집' 버튼 클릭됨")
                            editVM.editEventWithSpan(.thisEventOnly)
                        }
                        
                        Button("이후 모든 이벤트 편집") {
                            print("DEBUG: '이후 모든 이벤트 편집' 버튼 클릭됨")
                            editVM.editEventWithSpan(.futureEvents)
                        }
                        
                        Button("취소", role: .cancel) {
                            print("DEBUG: '취소' 버튼 클릭됨")
                            editVM.cancelEventEdit()
                        }
                    },
                    message: {
                        Text("반복 일정입니다. 어떻게 편집하시겠습니까?")
                    }
                )
                .onChange(of: editVM.showRecurringEditOptions) { _, newValue in
                    print("DEBUG: showRecurringEditOptions 변경됨: \(newValue)")
                    if newValue {
                        internalShowDialog = true
                    }
                }
                .onChange(of: internalShowDialog) { _, newValue in
                    print("DEBUG: internalShowDialog 변경됨: \(newValue)")
                    // dialog가 닫혔을 때만 처리
                    if !newValue {
                        Task { @MainActor in
                            editVM.showRecurringEditOptions = false
                        }
                    }
                }
        } else {
            content
        }
    }
}