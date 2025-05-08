//
//  AddSheet.swift
//  HaruView
//
//  Created by 김효석 on 5/2/25.
//

import SwiftUI

struct AddSheet<VM: AddSheetViewModelProtocol>: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: VM
    
    init(vm: VM) {
        _vm = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("종류", selection: $vm.mode) {
                    ForEach(AddSheetMode.allCases) { Text($0.rawValue).tag($0) }
                }
                Section(header: Text("제목")) {
                    TextField("제목 입력", text: $vm.title)
                }
                if vm.mode == .event {
                    Section(header: Text("시작")) {
                        DatePicker("", selection: $vm.startDate, displayedComponents: [.date, .hourAndMinute])
                    }
                    Section(header: Text("종료")) {
                        DatePicker("", selection: $vm.endDate, displayedComponents: [.date, .hourAndMinute])
                    }
                } else {
                    Section(header: Text("마감일")) {
                        DatePicker("", selection: $vm.dueDate, displayedComponents: [.date])
                    }
                }
                if let error = vm.error {
                    Section { Text("⚠️ 오류: \(error.localizedDescription)").foregroundColor(.red) }
                }
            }
            .navigationTitle("새 항목 추가")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if vm.isSaving {
                        ProgressView()
                    } else {
                        Button("저장") {
                            Task {
                                await vm.save()
                                if vm.error == nil {
                                    dismiss()
                                }
                            }
                        }
                        .disabled(vm.title.isEmpty)
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled(vm.isSaving)
    }
}

#if DEBUG
private class MockAddVM: AddSheetViewModelProtocol {
    @Published var mode: AddSheetMode = .event
    @Published var title: String = ""
    @Published var startDate: Date = .now
    @Published var endDate: Date = .now
    @Published var dueDate: Date = .now
    @Published var error: TodayBoardError? = nil
    @Published var isSaving: Bool = false
    
    func save() async {}
}

#Preview {
    AddSheet(vm: MockAddVM())
}
#endif
