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
            
            // 안내 메시지
            HStack {
                if let dueDate = vm.dueDate, Calendar.current.compare(dueDate, to: .now, toGranularity: .day) == .orderedDescending {
                    Text("내일/모레 할 일은 홈에서 보이지 않아요!")
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(Color.red)
                } else {
                    Text("날짜는 이틀 후까지만 선택 가능합니다.")
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(Color(hexCode: "A76545"))
                }
                
                Spacer()
            }
            
            // 마감일 선택기
            ReminderDueDatePicker(
                dueDate: $vm.dueDate,
                includeTime: $vm.includeTime,
                isTextFieldFocused: isTextFieldFocused,
                minDate: minDate,
                maxDate: maxDate
            )
            
            Divider()
                .padding(.top, 8)
        }
    }
}
