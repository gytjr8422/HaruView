//
//  HolidayRegionSettingView.swift
//  HaruView
//
//  Created by 김효석 on 8/1/25.
//

import SwiftUI

struct HolidayRegionSettingView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var searchText = ""
    
    private var regionsByContinent: [HolidayRegion.Continent: [HolidayRegion]] {
        let filtered = filteredRegions
        return Dictionary(grouping: filtered, by: { $0.continent })
    }
    
    private var filteredRegions: [HolidayRegion] {
        if searchText.isEmpty {
            return HolidayRegion.availableRegions
        } else {
            return HolidayRegion.availableRegions.filter { region in
                region.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 검색 바
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("국가 검색", text: $searchText)
                        .font(.pretendardRegular(size: 16))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // 현재 선택된 국가
                if searchText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("현재 설정")
                            .font(.pretendardMedium(size: 14))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            Text(settings.holidayRegion.flagEmoji)
                                .font(.system(size: 24))
                            
                            Text(settings.holidayRegion.displayName)
                                .font(.pretendardSemiBold(size: 16))
                                .foregroundStyle(Color(hexCode: "A76545"))
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(hexCode: "A76545"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(hexCode: "A76545").opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                
                // 국가 목록
                List {
                    ForEach(HolidayRegion.Continent.allCases, id: \.self) { continent in
                        if let regions = regionsByContinent[continent], !regions.isEmpty {
                            Section(continent.rawValue) {
                                ForEach(regions, id: \.id) { region in
                                    RegionRow(
                                        region: region,
                                        isSelected: region.localeIdentifier == settings.holidayRegion.localeIdentifier
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            settings.holidayRegion = region
                                        }
                                        
                                        // 햅틱 피드백
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                        
                                        // 달력 새로고침 알림
                                        NotificationCenter.default.post(name: .calendarNeedsRefresh, object: nil)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("공휴일 국가 설정")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct RegionRow: View {
    let region: HolidayRegion
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(region.flagEmoji)
                    .font(.system(size: 24))
                
                Text(region.displayName)
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hexCode: "A76545"))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        HolidayRegionSettingView()
    }
}