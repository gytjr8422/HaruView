//
//  SettingsView.swift
//  HaruView
//
//  Created by 김효석 on 8/1/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    
    var body: some View {
        List {
                Section {
                    // 공휴일 표시 여부 토글
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .foregroundStyle(Color(hexCode: "A76545"))
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("공휴일 표시")
                                .font(.pretendardRegular(size: 16))
                            
                            Text("달력에 공휴일을 표시합니다")
                                .font(.pretendardRegular(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $settings.showHolidays)
                            .labelsHidden()
                            .tint(Color(hexCode: "A76545"))
                            .onChange(of: settings.showHolidays) { _, newValue in
                                // 햅틱 피드백
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                    }
                    
                    // 공휴일 국가 설정 (공휴일 표시가 켜져있을 때만)
                    if settings.showHolidays {
                        NavigationLink {
                            HolidayRegionSettingView()
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundStyle(Color(hexCode: "A76545"))
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("공휴일 국가 설정")
                                        .font(.pretendardRegular(size: 16))
                                    
                                    Text(settings.holidayRegion.displayName)
                                        .font(.pretendardRegular(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(settings.holidayRegion.flagEmoji)
                                    .font(.system(size: 18))
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                } header: {
                    Text("달력 설정")
                        .font(.pretendardMedium(size: 14))
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Color(hexCode: "A76545"))
                            .frame(width: 24)
                        
                        Text("앱 정보")
                            .font(.pretendardRegular(size: 16))
                        
                        Spacer()
                        
                        Text("버전 1.0")
                            .font(.pretendardRegular(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    
                    // 디버깅 버튼 (임시)
                    Button {
                        debugHolidayCalendars()
                    } label: {
                        HStack {
                            Image(systemName: "ladybug")
                                .foregroundStyle(Color(hexCode: "A76545"))
                                .frame(width: 24)
                            
                            Text("공휴일 캘린더 디버그")
                                .font(.pretendardRegular(size: 16))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                        }
                    }
                } header: {
                    Text("앱 정보")
                        .font(.pretendardMedium(size: 14))
                        .foregroundStyle(.secondary)
                }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func debugHolidayCalendars() {
        let eventKitService = EventKitService()
        eventKitService.debugHolidayCalendars()
    }
}

#Preview {
    SettingsView()
}