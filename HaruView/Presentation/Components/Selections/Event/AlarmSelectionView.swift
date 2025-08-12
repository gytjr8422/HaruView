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
            VStack(alignment: .leading, spacing: 16) {
                // 빠른 설정 섹션 - 날짜+시간 모드처럼 기존 AlarmInput.presets 사용
                VStack(alignment: .leading, spacing: 12) {
                    Text("빠른 설정")
                        .font(.pretendardSemiBold(size: 16))
                        .foregroundStyle(Color(hexCode: "40392B"))
                    
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
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(hexCode: "A76545").opacity(0.1))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // 사용자 알림 섹션 (사용자 설정 선택 시 또는 기존 알림이 있을 때)
                if !alarms.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("사용자 알림")
                                .font(.pretendardSemiBold(size: 16))
                                .foregroundStyle(Color(hexCode: "40392B"))
                            
                            Spacer()
                            
                            Button {
                                showCustomAlarm = true
                            } label: {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color(hexCode: "A76545"))
                            }
                        }
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("캘린더 앱에서 알림이 울려요.")
                                    .font(.pretendardRegular(size: 12))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(Array(alarms.enumerated()), id: \.offset) { index, alarm in
                                    HStack {
                                        Text(alarm.description)
                                            .font(.pretendardRegular(size: 14))
                                        
                                        Spacer()
                                        
                                        Button {
                                            alarms.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 12))
                                        }
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(hexCode: "A76545"))
                                    )
                                }
                            }
                        }
                    }
                } else {
                    // 알림이 없을 때는 사용자 설정 추가 버튼만 표시
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("사용자 설정")
                                .font(.pretendardSemiBold(size: 16))
                                .foregroundStyle(Color(hexCode: "40392B"))
                            
                            Spacer()
                            
                            Button {
                                showCustomAlarm = true
                            } label: {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color(hexCode: "A76545"))
                            }
                        }
                        
                        Text("알림이 설정되지 않았습니다")
                            .font(.pretendardRegular(size: 14))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    }
                }
            }
        }
        .sheet(isPresented: $showCustomAlarm) {
            CustomReminderAlarmSheet(alarms: $alarms, dueDateMode: .dateTime)
                .presentationDetents([.fraction(0.5)])
        }
    }
}

