//
//  BasicEventInfoSection.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import SwiftUI

struct BasicEventInfoSection<VM: AddSheetViewModelProtocol>: View {
    @ObservedObject var vm: VM
    var isTextFieldFocused: FocusState<Bool>.Binding
    let minDate: Date
    let maxDate: Date
    
    var body: some View {
        VStack(spacing: 20) {
            // 제목 입력
            HaruTextField(text: $vm.currentTitle, placeholder: String(localized: "제목 입력"))
                .focused(isTextFieldFocused)
            
            // 안내 메시지 및 하루 종일 토글
            HStack {
                Spacer()
                
                Text("하루 종일")
                    .font(.pretendardSemiBold(size: 16))
                Toggle("", isOn: $vm.isAllDay)
                    .toggleStyle(HaruToggleStyle())
                    .padding(.horizontal, 5)
            }
            
            // 날짜/시간 선택기
            EventDateTimePicker(
                startDate: $vm.startDate,
                endDate: $vm.endDate,
                isAllDay: $vm.isAllDay,
                isTextFieldFocused: isTextFieldFocused
            )
            
            Divider()
                .padding(.top, 8)
        }
    }
}
