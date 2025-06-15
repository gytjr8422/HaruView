//
//  AddSheet.swift
//  HaruView
//
//  Created by 김효석 on 5/2/25.
//

import SwiftUI

struct AddSheet<VM: AddSheetViewModelProtocol>: View {
    @Environment(\.dismiss) private var dismiss
    @Namespace private var indicatorNS
    @FocusState private var isTextFieldFocused: Bool

    @StateObject private var vm: VM
    var onSave: () -> Void

    private var minDate: Date { Calendar.current.startOfDay(for: .now) }
    private var maxDate: Date { Calendar.current.date(byAdding: .day, value: 2, to: minDate)! }

    @State private var selected: AddSheetMode = .event
    @State private var showDiscardAlert = false

    init(vm: VM, onSave: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: vm)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !vm.isEdit { headerFilterView }

                if vm.isEdit {
                    if vm.mode == .event {
                        eventPage
                    } else {
                        reminderPage
                    }
                } else {
                    TabView(selection: $selected) {
                        eventPage.tag(AddSheetMode.event)
                        reminderPage.tag(AddSheetMode.reminder)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .onChange(of: selected) { _, newValue in vm.mode = newValue }
                }
            }
            .background(Color(hexCode: "FFFCF5"))
            .toolbar { leadingToolbar; toolbarTitle; saveToolbar }
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("작성 내용이 저장되지 않습니다.",
                                isPresented: $showDiscardAlert) {
                Button("저장 안 하고 닫기", role: .destructive) { dismiss() }
                Button("계속 작성", role: .cancel) {}
            }
        }
        .interactiveDismissDisabled(isDirty || vm.isSaving)
        .onAppear {
            selected = vm.mode
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { isTextFieldFocused = true }
        }
    }

    // MARK: Dirty Check
    private var isDirty: Bool {
        !vm.currentTitle.isEmpty || (vm.mode == .event && vm.startDate > Date())
    }

    // MARK: Header -----------------------------------------------------------
    private var headerFilterView: some View {
        HStack(spacing: 0) {
            ForEach(AddSheetMode.allCases) { seg in
                VStack(spacing: 4) {
                    Text(seg.localized)
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
                .onTapGesture { withAnimation(.spring()) { selected = seg } }
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    // MARK: 공통 Title Field --------------------------------------------------
    private var commonTitleField: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("제목").font(.pretendardBold(size: 17))
            HaruTextField(text: $vm.currentTitle, placeholder: String(localized: "제목 입력"))
                .focused($isTextFieldFocused)
        }
    }

    private var eventPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                commonTitleField
                
                HStack {
                    if Calendar.current.compare(vm.startDate, to: .now, toGranularity: .day) == .orderedDescending {
                        Text("내일/모레 일정은 홈에서 보이지 않아요!")
                            .font(.pretendardRegular(size: 14))
                            .foregroundStyle(Color.red)
                    } else {
                        Text("날짜는 이틀 후까지만 선택 가능합니다.")
                            .font(.pretendardRegular(size: 14))
                            .foregroundStyle(Color(hexCode: "A76545"))
                    }
                    
                    Spacer()
                    
                    Text("하루 종일")
                        .font(.pretendardSemiBold(size: 16))
                    Toggle("", isOn: $vm.isAllDay)
                        .toggleStyle(HaruToggleStyle())
                        .padding(.horizontal, 5)
                }
                
                HStack(spacing: 4.5) {
                    Text(vm.isAllDay ? "날짜" : "시작")
                        .font(.pretendardSemiBold(size: 18))
                        .padding(.trailing, 10)
                    
                    datePicker(date: $vm.startDate, min: minDate)
                        .frame(width: 120, alignment: .trailing)
                        .environment(\.locale, Locale.current.language.languageCode?.identifier == "ko" ? Locale(identifier: "ko_KR") : Locale(identifier: "en_US"))
                    
                    if !vm.isAllDay {
                        timePicker(time: $vm.startDate)
                            .environment(\.locale, Locale.current.language.languageCode?.identifier == "ko" ? Locale(identifier: "ko_KR") : Locale(identifier: "en_US"))
                    }
                }
                
                if !vm.isAllDay {
                    HStack(spacing: 5) {
                        Text("종료")
                            .font(.pretendardSemiBold(size: 18))
                            .padding(.trailing, Locale.current.language.languageCode?.identifier == "ko" ? 10 : 22)
                        
                        datePicker(date: $vm.endDate, min: vm.startDate)
                            .frame(width: 120, alignment: .trailing)
                            .environment(\.locale, Locale.current.language.languageCode?.identifier == "ko" ? Locale(identifier: "ko_KR") : Locale(identifier: "en_US"))
                        
                        timePicker(time: $vm.endDate, min: vm.startDate)
                                .environment(\.locale, Locale.current.language.languageCode?.identifier == "ko" ? Locale(identifier: "ko_KR") : Locale(identifier: "en_US"))
                    }
                }

                footerError
            }
            .padding(20)
        }
    }

    private var reminderPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                commonTitleField
                
                HStack {
                    if Calendar.current.compare(vm.dueDate, to: .now, toGranularity: .day) == .orderedDescending {
                        Text("내일/모레 할 일은 홈에서 보이지 않아요!")
                            .font(.pretendardRegular(size: 14))
                            .foregroundStyle(Color.red)
                    } else {
                        Text("날짜는 이틀 후까지만 선택 가능합니다.")
                            .font(.pretendardRegular(size: 14))
                            .foregroundStyle(Color(hexCode: "A76545"))
                    }
                    
                    Spacer()
                    
                    Text("시간")
                        .font(.pretendardSemiBold(size: 16))
                    Toggle("", isOn: $vm.includeTime)
                        .toggleStyle(HaruToggleStyle())
                        .padding(.horizontal, 5)
                }
                
                HStack {
                    Text(vm.includeTime ? "날짜/시간" : "날짜")
                        .font(.pretendardSemiBold(size: 18))
                        .padding(.trailing, 10)
                    
                    datePicker(date: $vm.dueDate, min: minDate)
                        .frame(width: 120, alignment: .trailing)
                        .environment(\.locale, Locale.current.language.languageCode?.identifier == "ko" ? Locale(identifier: "ko_KR") : Locale(identifier: "en_US"))
                    
                    if vm.includeTime {
                        timePicker(time: $vm.dueDate, min: .now)
                            .environment(\.locale, Locale.current.language.languageCode?.identifier == "ko" ? Locale(identifier: "ko_KR") : Locale(identifier: "en_US"))
                    }
                }
                .animation(.easeIn, value: 10)
                
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
        if let min {
            DatePicker("", selection: date, in: min...maxDate, displayedComponents: [.date])
                .labelsHidden()
        } else {
            DatePicker("", selection: date, displayedComponents: [.date])
                .labelsHidden()
        }
    }
    
    private func timePicker(time: Binding<Date>, min: Date? = nil) -> some View {
        if let min {    // 종료 피커처럼 최소값이 있을 때
            DatePicker("", selection: time, in: min...maxDate, displayedComponents: [.hourAndMinute])
                .labelsHidden()
        } else {        // 시작
            DatePicker("", selection: time, displayedComponents: [.hourAndMinute])
                .labelsHidden()
        }
    }

    private var footerError: some View {
        Group {
            if let e = vm.error {
                Text(String(format: NSLocalizedString("⚠️ 오류: %@", comment: ""), e.localizedDescription))
                    .font(.jakartaRegular(size: 14))
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: Save Toolbar -----------------------------------------------------
    private var leadingToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button { isDirty ? (showDiscardAlert = true) : dismiss() } label: {
                Text("취소").font(.pretendardSemiBold(size: 16)).foregroundColor(.red.opacity(0.8))
            }
        }
    }
    
    private var saveToolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            if vm.isSaving { ProgressView() } else {
                Button {
                    Task {
                        await vm.save()
                        if vm.error == nil { dismiss(); onSave() }
                    }
                } label: {
                    Text("저장").font(.pretendardSemiBold(size: 16))
                        .foregroundColor(vm.currentTitle.isEmpty ? .secondary : Color.blue.opacity(0.8))
                }
                .disabled(vm.currentTitle.isEmpty)
            }
        }
    }
    
    private var toolbarTitle: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            let key = vm.isEdit ? "%@ 편집" : "%@ 추가"
            Text(String(format: NSLocalizedString(key, comment: ""), vm.mode.localized))
        }
    }
}

private struct HaruToggleStyle: ToggleStyle {
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
    var isEdit: Bool = false
    
    var currentTitle: String = ""
    
    
    @Published var mode: AddSheetMode = .event
    @Published var title: String = ""
    @Published var startDate: Date = .now
    @Published var endDate: Date = .now
    @Published var dueDate: Date = .now
    @Published var error: TodayBoardError? = nil
    @Published var isSaving: Bool = false
    @Published var isAllDay: Bool = false
    @Published var includeTime: Bool = true
    
    func save() async {}
}

#Preview {
    AddSheet(vm: MockAddVM(), onSave: {})
}
#endif
