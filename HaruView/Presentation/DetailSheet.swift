//
//  DetailSheet.swift
//  HaruView
//
//  Created by 김효석 on 5/3/25.
//

import SwiftUI

struct DetailSheet<VM: DetailSheetViewModelProtocol>: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: VM
    
    init(vm: VM) {
        _vm = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .toolbar { toolbarContent }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch vm.item {
        case .event(let event):
            EventDetail(event: event)
        case .reminder(let reminder):
            ReminderDetail(reminder: reminder)
        }
        
        if let error = vm.error {
            Text("⚠️ 오류: \(error.localizedDescription)")
                .foregroundColor(.red).padding()
        }
    }
    
    private var title: String {
        switch vm.item {
        case .event: return "일정"
        case .reminder: return "할 일"
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            if vm.isDeleting {
                ProgressView()
            } else {
                Button(role: .destructive) {
                    Task { await vm.deleteItem()
                        if vm.error == nil { dismiss() }
                    }
                } label: {
                    Text("삭제")
                }
            }
        }
        if case .reminder = vm.item {
            ToolbarItem(placement: .bottomBar) {
                Button{
                    Task { await vm.toggleCompletion() }
                } label: {
                    Text("완료 토글")
                }
            }
        }
        ToolbarItem(placement: .cancellationAction) {
            Button("닫기", action: { dismiss() })
        }
    }
}


private struct EventDetail: View {
    let event: Event
    var body: some View {
        List {
            Section(header: Text("제목")) { Text(event.title) }
            Section(header: Text("기간")) {
                Text("시작: \(format(event.start))")
                Text("종료: \(format(event.end))")
            }
            Section(header: Text("캘린더")) { Text(event.calendarTitle) }
        }
    }
    private func format(_ d: Date) -> String {
        DateFormatter.localizedString(from: d, dateStyle: .short, timeStyle: .short)
    }
}

private struct ReminderDetail: View {
    let reminder: Reminder
    var body: some View {
        List {
            Section(header: Text("제목")) { Text(reminder.title) }
            if let due = reminder.due {
                Section(header: Text("마감")) { Text(DateFormatter.localizedString(from: due, dateStyle: .short, timeStyle: .none)) }
            }
            Section { Label(reminder.isCompleted ? "완료" : "미완료", systemImage: reminder.isCompleted ? "checkmark.circle.fill" : "circle") }
        }
    }
}


#if DEBUG
private final class MockDetailVM: DetailSheetViewModelProtocol {
    @Published var item: DetailItem = .event(Event(id: "1", title: "회의", start: .now, end: .now.addingTimeInterval(3600), calendarTitle: "업무", calendarColor: CGColor(gray: 0.9, alpha: 0.9), location: "서울특별시"))
    @Published var error: TodayBoardError? = nil
    @Published var isDeleting: Bool = false
    func toggleCompletion() async {}
    func deleteItem() async {}
}
#Preview {
    DetailSheet(vm: MockDetailVM())
}
#endif
