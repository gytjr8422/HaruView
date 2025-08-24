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
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 16) {
                // 빠른 설정 섹션 - 날짜+시간 모드처럼 기존 AlarmInput.presets 사용
                VStack(alignment: .leading, spacing: 12) {
                    LocalizedText(key: "빠른 설정")
                        .font(.pretendardSemiBold(size: 16))
                        .foregroundStyle(.haruTextPrimary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(Array(AlarmInput.presets.prefix(6)), id: \.id) { preset in
                            Button {
                                if !alarms.contains(where: { $0.description == preset.description }) {
                                    alarms.append(preset)
                                }
                            } label: {
                                Text(getLocalizedDescription(for: preset))
                                    .font(.pretendardRegular(size: 14))
                                    .foregroundStyle(.haruPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.haruPrimary.opacity(0.1))
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
                            LocalizedText(key: "사용자 알림")
                                .font(.pretendardSemiBold(size: 16))
                                .foregroundStyle(.haruTextPrimary)
                            
                            Spacer()
                            
                            Button {
                                showCustomAlarm = true
                            } label: {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.haruPrimary)
                            }
                        }
                        
                        VStack(spacing: 8) {
                            HStack {
                                LocalizedText(key: "캘린더 앱에서 알림이 울려요.")
                                    .font(.pretendardRegular(size: 12))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(Array(alarms.enumerated()), id: \.offset) { index, alarm in
                                    HStack {
                                        Text(getLocalizedDescription(for: alarm))
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
                                            .fill(.haruPrimary)
                                    )
                                }
                            }
                        }
                    }
                } else {
                    // 알림이 없을 때는 사용자 설정 추가 버튼만 표시
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            LocalizedText(key: "사용자 설정")
                                .font(.pretendardSemiBold(size: 16))
                                .foregroundStyle(.haruTextPrimary)
                            
                            Spacer()
                            
                            Button {
                                showCustomAlarm = true
                            } label: {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.haruPrimary)
                            }
                        }
                        
                        LocalizedText(key: "알림이 설정되지 않았습니다")
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
    
    // MARK: - Helper Methods
    
    /// 알람 프리셋의 현지화된 설명 텍스트 반환 (언어 변경에 즉시 반응)
    private func getLocalizedDescription(for preset: AlarmInput) -> String {
        
        switch preset.trigger {
        case .relative(let interval):
            if interval == 0 {
                return "이벤트 시간".localized()
            } else if interval < 0 {
                let minutes = Int(abs(interval) / 60)
                let hours = minutes / 60
                let days = hours / 24
                
                if days > 0 {
                    return "%d일 전".localized(with: days)
                } else if hours > 0 {
                    return "%d시간 전".localized(with: hours)
                } else {
                    return "%d분 전".localized(with: minutes)
                }
            } else {
                let minutes = Int(interval / 60)
                let hours = minutes / 60
                let days = hours / 24
                
                if days > 0 {
                    return "%d일 후".localized(with: days)
                } else if hours > 0 {
                    return "%d시간 후".localized(with: hours)
                } else {
                    return "%d분 후".localized(with: minutes)
                }
            }
        case .absolute(let date):
            let formatter = DateFormatterFactory.formatter(for: .dateTime)
            return formatter.string(from: date)
        }
    }
}

