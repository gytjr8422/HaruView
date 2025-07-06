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
                "반복 일정 삭제",
                isPresented: $vm.showRecurringDeletionOptions,
                titleVisibility: .visible
            ) {
                if vm.currentDeletingEvent != nil {
                    Button("이 이벤트만 삭제", role: .destructive) {
                        vm.deleteEventWithSpan(.thisEventOnly)
                    }
                    
                    Button("이후 모든 이벤트 삭제", role: .destructive) {
                        vm.deleteEventWithSpan(.futureEvents)
                    }
                    
                    Button("취소", role: .cancel) {
                        vm.cancelEventDeletion()
                    }
                }
            } message: {
                if let event = vm.currentDeletingEvent {
                    Text("'\(event.title)'은(는) 반복 일정입니다. 어떻게 삭제하시겠습니까?")
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
                            
                            Text("삭제 중...")
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
