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
                                        LocalizedText(key: "편집").font(Font.pretendardRegular(size: 14))
                                    } icon: {
                                        Image(systemName: "pencil")
                                    }
                                }
                                Button(role: .destructive) {
                                    vm.requestEventDeletion(event)
                                } label: {
                                    Label {
                                        LocalizedText(key: "삭제").font(Font.pretendardRegular(size: 14))
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
            .background(.haruBackground)
        }
        .modifier(EventListSheetsModifier(
            editingEvent: $editingEvent,
            vm: vm,
            di: di
        ))
        .modifier(EventListDeletionModifier(vm: vm))
    }
    
    private var navigationTitleView: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            LocalizedText(key: "all_events")
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



// MARK: - ViewModifiers

private struct EventListSheetsModifier<VM: EventListViewModelProtocol>: ViewModifier {
    @Binding var editingEvent: Event?
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
                AddSheet(vm: di.makeEditSheetVM(event: event)) { isDeleted in
                    ToastManager.shared.show(isDeleted ? .delete : .success)
                    vm.refresh()
                }
            }
    }
}

private struct EventListDeletionModifier<VM: EventListViewModelProtocol>: ViewModifier {
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
            .alert("deletion_error".localized(), isPresented: .constant(vm.deletionError != nil)) {
                Button("confirm".localized()) {
                    vm.deletionError = nil
                }
            } message: {
                if let error = vm.deletionError {
                    Text(error.description)
                }
            }
    }
}


#if DEBUG
final class MockEventListVM: EventListViewModelProtocol {
    var showRecurringDeletionOptions: Bool = false
    var currentDeletingEvent: Event?
    var isDeletingEvent: Bool = false
    var deletionError: TodayBoardError?
    var events: [Event] = TodayOverview.placeholder.events
    
    func load() {}
    func refresh() {}
    func delete(id: String) {}
    func requestEventDeletion(_ event: Event) {}
    func deleteEventWithSpan(_ span: EventDeletionSpan) {}
    func cancelEventDeletion() {}
}

#Preview {
    EventListSheet(vm: MockEventListVM())
}
#endif
