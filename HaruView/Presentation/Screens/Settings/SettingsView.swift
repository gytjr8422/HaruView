//
//  SettingsView.swift
//  HaruView
//
//  Created by 김효석 on 8/1/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        HolidayRegionSettingView()
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(Color(hexCode: "A76545"))
                                .frame(width: 24)
                            
                            Text("공휴일 국가 설정")
                                .font(.pretendardRegular(size: 16))
                        }
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
                } header: {
                    Text("앱 정보")
                        .font(.pretendardMedium(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(Color(hexCode: "A76545"))
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}