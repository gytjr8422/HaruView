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
    @Namespace private var indicatorNS

    private var minDate: Date { Calendar.current.startOfDay(for: .now) }
    private var maxDate: Date { Calendar.current.date(byAdding: .day, value: 2, to: minDate)! }
    
    // local selection synced to vm.mode
    @State private var selected: AddSheetMode = .event
    
    @State private var showDiscardAlert = false

    init(vm: VM) { _vm = StateObject(wrappedValue: vm) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerFilterView
                TabView(selection: $selected) {
                    eventPage.tag(AddSheetMode.event)
                    
                    reminderPage.tag(AddSheetMode.reminder)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: selected) { _, newValue in
                    vm.mode = newValue
                }
            }
            .background(Color(hexCode: "FFFCF5"))
            .toolbar { leadingToolbar; toolbarTitle; saveToolbar }
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("작성 내용이 저장되지 않습니다.", isPresented: $showDiscardAlert, titleVisibility: .visible) {
                Button("저장 안 하고 닫기", role: .destructive) { dismiss() }
                Button("계속 작성", role: .cancel) { }
            }
        }
        .interactiveDismissDisabled(isDirty || vm.isSaving)
        .onAppear { selected = vm.mode }
    }
    
    private var isDirty: Bool {
        !vm.title.isEmpty ||
        (vm.mode == .event && !Calendar.current.isDate(vm.startDate, equalTo: Date(), toGranularity: .minute))
    }

    // MARK: Header -----------------------------------------------------------
    private var headerFilterView: some View {
        HStack(spacing: 0) {
            ForEach(AddSheetMode.allCases) { seg in
                VStack(spacing: 4) {
                    Text(seg.rawValue)
                        .font(.pretendardBold(size: 16))
                        .foregroundStyle(selected == seg ? Color(hexCode: "A76545") : .secondary)
                    ZStack {
                        Capsule().fill(Color.clear).frame(height: 3)
                        if selected == seg {
                            Capsule()
                                .fill(Color(hexCode: "A76545"))
                                .frame(height: 3)
                                .matchedGeometryEffect(id: "indicator", in: indicatorNS)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .contentShape(.rect)
                .onTapGesture {
                    withAnimation(.interactiveSpring(response: 0.4)) { selected = seg }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    // MARK: Pages ------------------------------------------------------------
    private var commonTitleField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("제목")
                .font(.pretendardBold(size: 15))
                .foregroundStyle(.secondary)
            HaruTextField(text: $vm.title, placeholder: "제목 입력")
        }
    }

    private var eventPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                commonTitleField
                
                HStack {
                    Spacer()
                    Text("하루 종일")
                        .font(.pretendardSemiBold(size: 16))
                    Toggle("", isOn: $vm.isAllDay)
                        .toggleStyle(HaruToggleStyle())
                        .font(.pretendardBold(size: 15))
                        .padding(.horizontal, 5)
                }
                
                HStack(spacing: 4.5) {
                    Text(vm.isAllDay ? "날짜" : "시작")
                        .font(.pretendardSemiBold(size: 18))
                        .padding(.trailing, 10)
                    
                    datePicker(date: $vm.startDate, min: minDate)
                    
                    if !vm.isAllDay {
                        timePicker(time: $vm.startDate)
                    }
                }
                
                if !vm.isAllDay {
                    HStack(spacing: 5) {
                        Text("종료")
                            .font(.pretendardSemiBold(size: 18))
                            .padding(.trailing, 10)

                        dateTimePicker(date: $vm.endDate,
                                       min: vm.startDate)
                    }
                }

                footerError
            }
            .padding(20)
        }
    }

    private var reminderPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                commonTitleField
                HStack {
                    Text("날짜/시간")
                        .font(.pretendardSemiBold(size: 18))
                        .padding(.trailing, 10)
                    dateTimePicker(date: $vm.startDate, min: minDate)
                }
                footerError
            }
            .padding(20)
        }
    }

    // MARK: Components -------------------------------------------------------
    private func dateTimePicker(date: Binding<Date>,
                                min: Date? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let min {    // 종료 피커처럼 최소값이 있을 때
                DatePicker("", selection: date, in: min...maxDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
            } else {        // 시작 피커
                DatePicker("", selection: date, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
            }
        }
    }
    
    private func datePicker(date: Binding<Date>,
                                min: Date? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let min {    // 종료 피커처럼 최소값이 있을 때
                DatePicker("", selection: date, in: min...maxDate, displayedComponents: [.date])
                    .labelsHidden()
            } else {        // 시작 
                DatePicker("", selection: date, displayedComponents: [.date])
                    .labelsHidden()
            }
        }
    }
    
    private func timePicker(time: Binding<Date>, min: Date? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let min {    // 종료 피커처럼 최소값이 있을 때
                DatePicker("", selection: time, in: min...maxDate, displayedComponents: [.hourAndMinute])
                    .labelsHidden()
            } else {        // 시작
                DatePicker("", selection: time, displayedComponents: [.hourAndMinute])
                    .labelsHidden()
            }
        }
    }

    private var footerError: some View {
        Group {
            if let e = vm.error {
                Text("⚠️ 오류: \(e.localizedDescription)")
                    .font(.jakartaRegular(size: 14))
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: Save Toolbar -----------------------------------------------------
    private var leadingToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                if isDirty { showDiscardAlert = true } else { dismiss() }
            } label: {
                Text("취소")
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(.red)
            }

        }
    }
    
    private var saveToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .confirmationAction) {
            if vm.isSaving { ProgressView() }
            else {
                Button("저장") {
                    Task {
                        await vm.save()
                        if vm.error == nil { dismiss() }
                    }
                }
                .disabled(vm.title.isEmpty)
            }
        }
    }
    
    private var toolbarTitle: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("\(selected.rawValue) 추가")
                
        }
    }
}

struct HaruToggleStyle: ToggleStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(configuration.isOn ? Color(hexCode: "A76545"): Color.gray)
                .frame(width: 46, height: 24)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20)
                        .offset(x: configuration.isOn ? 12 : -12)
                        .shadow(color: .black.opacity(0.25), radius: 4)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

#if DEBUG
private class MockAddVM: AddSheetViewModelProtocol {
    @Published var mode: AddSheetMode = .event
    @Published var title: String = ""
    @Published var startDate: Date = .now
    @Published var endDate: Date = .now
    @Published var dueDate: Date? = .now
    @Published var error: TodayBoardError? = nil
    @Published var isSaving: Bool = false
    @Published var isAllDay: Bool = false
    
    func save() async {}
}

#Preview {
    AddSheet(vm: MockAddVM())
}
#endif
