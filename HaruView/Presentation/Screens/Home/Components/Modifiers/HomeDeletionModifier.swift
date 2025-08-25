//
//  HomeDeletionModifier.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import SwiftUI

struct DeletionUIViewModifier<VM: HomeViewModelProtocol>: ViewModifier {
    @ObservedObject var vm: VM
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "recurring_event_delete".localized(),
                isPresented: $vm.showRecurringDeletionOptions,
                titleVisibility: .visible
            ) {
                if vm.currentDeletingEvent != nil {
                    Button("delete_this_event_only".localized(), role: .destructive) {
                        vm.deleteEventWithSpan(.thisEventOnly)
                    }
                    
                    Button("delete_all_future_events".localized(), role: .destructive) {
                        vm.deleteEventWithSpan(.futureEvents)
                    }
                    
                    Button("취소".localized(), role: .cancel) {
                        vm.cancelEventDeletion()
                    }
                }
            } message: {
                if let event = vm.currentDeletingEvent {
                    Text(String(format: "recurring_event_delete_question".localized(), event.title))
                }
            }
            .overlay {
                if vm.isDeletingEvent {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            LocalizedText(key: "deleting")
                                .font(.pretendardSemiBold(size: 16))
                                .foregroundStyle(.white)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                    }
                    .transition(.opacity)
                }
            }
            .alert("삭제 오류", isPresented: .constant(vm.deletionError != nil)) {
                Button("확인") {
                    vm.deletionError = nil
                }
            } message: {
                if let error = vm.deletionError {
                    Text(error.description)
                }
            }
    }
}
