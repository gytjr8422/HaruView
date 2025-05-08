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
    @StateObject var vm: VM
    
    init(vm: VM) {
        _vm = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    ForEach(vm.events) { event in
                        EventCard(event: event)
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
