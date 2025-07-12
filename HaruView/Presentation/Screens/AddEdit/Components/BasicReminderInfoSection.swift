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
            HaruTextField(text: $vm.currentTitle, placeholder: String(localized: "제목 입력"))
                .focused(isTextFieldFocused)
            
            // 마감일 선택기
            ReminderDueDatePicker(
                dueDate: $vm.dueDate,
                includeTime: $vm.includeTime,
                isTextFieldFocused: isTextFieldFocused
            )
            
            Divider()
                .padding(.top, 8)
        }
    }
}
