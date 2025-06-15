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
                                    Task {
                                        await vm.delete(id: event.id)
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
                }
                .padding(16)
            }
            .toolbar { navigationTitleView; exitButton }
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .background(Color(hexCode: "FFFCF5"))
        }
        .onAppear { vm.load() }
        .onChange(of: phase) {
            if phase == .active { vm.refresh() }
        }
        .refreshable { vm.refresh() }
        .sheet(item: $editingEvent) { event in
            AddSheet(vm: di.makeEditSheetVM(event: event)) {
                vm.refresh()
                showToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showToast = false }
            }
        }
        .overlay(alignment: .top) {
            if showToast { ToastView().transition(.opacity) }
        }
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


#if DEBUG
final class MockEventListVM: EventListViewModelProtocol {
    
    var events: [Event] = TodayOverview.placeholder.events
    
    func load() {}
    func refresh() { }
    func delete(id: String) {}
}

#Preview {
    EventListSheet(vm: MockEventListVM())
}
#endif
