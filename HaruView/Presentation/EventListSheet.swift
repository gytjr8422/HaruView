//
//  EventListSheet.swift
//  HaruView
//
//  Created by 김효석 on 5/6/25.
//

import SwiftUI

struct EventListSheet<VM: EventListViewModelProtocol>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var phase
    @Environment(\.di) private var di
    @StateObject var vm: VM
    @State private var editingEvent: Event?
    @State private var showToast: Bool = false
    
    init(vm: VM) {
        _vm = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    ForEach(vm.events) { event in
                        EventCard(event: event)
                            .contextMenu {
                                Button {
                                    editingEvent = event
                                } label: {
                                    Label {
                                        Text("편집").font(Font.pretendardRegular(size: 14))
                                    } icon: {
                                        Image(systemName: "pencil")
                                    }
                                }
                                Button(role: .destructive) {
                                    vm.requestEventDeletion(event)
                                } label: {
                                    Label {
                                        Text("삭제").font(Font.pretendardRegular(size: 14))
                                    } icon: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                    }
                }
                .padding(16)
            }
            .toolbar { navigationTitleView; exitButton }
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .background(Color(hexCode: "FFFCF5"))
        }
        .modifier(EventListSheetsModifier(
            editingEvent: $editingEvent,
            showToast: $showToast,
            vm: vm,
            di: di
        ))
        .modifier(EventListDeletionModifier(vm: vm))
    }
    
    private var navigationTitleView: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("전체 일정")
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



// MARK: - ViewModifiers

private struct EventListSheetsModifier<VM: EventListViewModelProtocol>: ViewModifier {
    @Binding var editingEvent: Event?
    @Binding var showToast: Bool
    @ObservedObject var vm: VM
    let di: DIContainer
    @Environment(\.scenePhase) private var phase
    
    func body(content: Content) -> some View {
        content
            .onAppear { vm.load() }
            .onChange(of: phase) {
                if phase == .active { vm.refresh() }
            }
            .refreshable { vm.refresh() }
            .sheet(item: $editingEvent) { event in
                AddSheet(vm: di.makeEditSheetVM(event: event)) {
                    showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showToast = false
                    }
                    vm.refresh()
                }
            }
            .overlay(
                Group {
                    if showToast {
                        ToastView()
                            .animation(.easeInOut, value: showToast)
                            .transition(.opacity)
                    }
                }
            )
    }
    
    private struct ToastView: View {
        var body: some View {
            Text("저장이 완료되었습니다.")
                .font(.pretendardSemiBold(size: 14))
                .foregroundStyle(Color.white)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .opacity(0.85)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

private struct EventListDeletionModifier<VM: EventListViewModelProtocol>: ViewModifier {
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


//#if DEBUG
//final class MockEventListVM: EventListViewModelProtocol {
//    
//    var events: [Event] = TodayOverview.placeholder.events
//    
//    func load() {}
//    func refresh() { }
//    func delete(id: String) {}
//}
//
//#Preview {
//    EventListSheet(vm: MockEventListVM())
//}
//#endif
