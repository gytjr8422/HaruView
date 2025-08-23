//
//  BasicReminderInfoSection.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import SwiftUI

struct BasicReminderInfoSection<VM: AddSheetViewModelProtocol>: View {
    @ObservedObject var vm: VM
    var isTextFieldFocused: FocusState<Bool>.Binding
    let minDate: Date
    let maxDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 제목 입력
            HaruTextField(text: $vm.currentTitle, placeholder: "제목 입력".localized())
                .focused(isTextFieldFocused)
            
            // 마감일 선택기 (할일 타입 및 알림 프리셋 선택 포함)
            ReminderDueDatePicker(
                dueDate: $vm.dueDate,
                includeTime: $vm.includeTime,
                reminderType: $vm.reminderType,
                alarmPreset: $vm.reminderAlarmPreset,
                customAlarms: $vm.reminderAlarms,
                isTextFieldFocused: isTextFieldFocused
            )
            
            Divider()
                .padding(.top, 8)
        }
    }
}
