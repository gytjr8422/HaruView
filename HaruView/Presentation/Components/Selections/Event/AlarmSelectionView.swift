//
//  AlarmSelectionView.swift
//  HaruView
//
//  Created by 김효석 on 6/30/25.
//

import SwiftUI

// MARK: - 알람 선택 컴포넌트
struct AlarmSelectionView: View {
    @Binding var alarms: [AlarmInput]
    @State private var showCustomAlarm = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
//            HStack {
//                Text("알림")
//                    .font(.pretendardSemiBold(size: 16))
//                Spacer()
//                Button("추가") {
//                    showCustomAlarm = true
//                }
//                .font(.pretendardRegular(size: 14))
//                .foregroundStyle(Color(hexCode: "A76545"))
//            }
            
            if alarms.isEmpty {
                Text("알림이 설정되지 않았습니다")
                    .font(.pretendardRegular(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack {
                    HStack {
                        Text("캘린더 앱에서 알림이 울려요.")
                            .font(.pretendardRegular(size: 14))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 5)
                        Spacer()
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 5) {
                        ForEach(Array(alarms.enumerated()), id: \.offset) { index, alarm in
                            HStack {
                                Text(alarm.description)
                                    .font(.pretendardRegular(size: 14))
                                
                                Spacer()
                                
                                Button {
                                    alarms.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14))
                                }
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal,12)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hexCode: "A76545"))
                            )
                        }
                    }
                }
            }
            
            // 빠른 설정 버튼들
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(AlarmInput.presets.prefix(6), id: \.description) { preset in
                    
                    Button {
                        if !alarms.contains(where: { $0.description == preset.description }) {
                            alarms.append(preset)
                        }
                    } label: {
                        Text(preset.description)
                            .font(.pretendardRegular(size: 14))
                            .foregroundStyle(Color(hexCode: "A76545"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hexCode: "A76545").opacity(0.1))
                        )

                    }
                }
            }
        }
        .sheet(isPresented: $showCustomAlarm) {
            CustomAlarmSheet(alarms: $alarms)
        }
    }
}

// MARK: - 커스텀 알람 설정 시트
struct CustomAlarmSheet: View {
    @Binding var alarms: [AlarmInput]
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: AlarmInput.AlarmType = .display
    @State private var triggerMode: TriggerMode = .relative
    @State private var relativeMinutes: Int = 15
    @State private var absoluteDate: Date = Date()
    
    enum TriggerMode: String, CaseIterable {
        case relative = "상대적"
        case absolute = "절대적"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("알림 타입") {
                    Picker("타입", selection: $selectedType) {
                        Text("알림").tag(AlarmInput.AlarmType.display)
                        Text("이메일").tag(AlarmInput.AlarmType.email)
                        Text("소리").tag(AlarmInput.AlarmType.sound)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("알림 시간") {
                    Picker("설정 방식", selection: $triggerMode) {
                        ForEach(TriggerMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if triggerMode == .relative {
                        HStack {
                            TextField("분", value: $relativeMinutes, format: .number)
                                .keyboardType(.numberPad)
                            Text("분 전")
                        }
                    } else {
                        DatePicker("알림 시간", selection: $absoluteDate)
                    }
                }
            }
            .navigationTitle("알림 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        let trigger: AlarmInput.AlarmTrigger
                        if triggerMode == .relative {
                            trigger = .relative(-TimeInterval(relativeMinutes * 60))
                        } else {
                            trigger = .absolute(absoluteDate)
                        }
                        
                        let alarm = AlarmInput(type: selectedType, trigger: trigger)
                        alarms.append(alarm)
                        dismiss()
                    }
                }
            }
        }
    }
}
