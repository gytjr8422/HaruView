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
    @State private var showCalendarGuide = false
    
    private let eventKitService = EventKitService()
    
    private var regionsByContinent: [HolidayRegion.Continent: [HolidayRegion]] {
        let filtered = filteredRegions
        return Dictionary(grouping: filtered, by: { $0.continent })
    }
    
    private var filteredRegions: [HolidayRegion] {
        let baseRegions = if searchText.isEmpty {
            HolidayRegion.availableRegions
        } else {
            HolidayRegion.availableRegions.filter { region in
                region.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 사용 가능한 공휴일 캘린더가 있는 지역만 표시
        return baseRegions.filter { region in
            eventKitService.hasHolidayCalendarFor(region: region)
        }
    }
    
    private var unavailableRegions: [HolidayRegion] {
        let baseRegions = if searchText.isEmpty {
            HolidayRegion.availableRegions
        } else {
            HolidayRegion.availableRegions.filter { region in
                region.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return baseRegions.filter { region in
            !eventKitService.hasHolidayCalendarFor(region: region)
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
                    // 사용 가능한 지역들
                    ForEach(HolidayRegion.Continent.allCases, id: \.self) { continent in
                        if let regions = regionsByContinent[continent], !regions.isEmpty {
                            Section(continent.rawValue) {
                                ForEach(regions, id: \.id) { region in
                                    RegionRow(
                                        region: region,
                                        isSelected: region.localeIdentifier == settings.holidayRegion.localeIdentifier,
                                        isAvailable: true
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
                    
                    // 사용 불가능한 지역들 (안내와 함께)
                    if !unavailableRegions.isEmpty {
                        Section {
                            Button {
                                showCalendarGuide = true
                            } label: {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundStyle(.orange)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("추가 공휴일 캘린더")
                                            .font(.pretendardMedium(size: 16))
                                            .foregroundStyle(.primary)
                                        
                                        Text("\(unavailableRegions.count)개 국가의 공휴일을 더 이용할 수 있어요")
                                            .font(.pretendardRegular(size: 14))
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } header: {
                            Text("사용 가능한 공휴일 캘린더")
                                .font(.pretendardMedium(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("공휴일 국가 설정")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCalendarGuide) {
                HolidayCalendarGuideView()
            }
        }
    }
}

struct RegionRow: View {
    let region: HolidayRegion
    let isSelected: Bool
    let isAvailable: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(region.flagEmoji)
                    .font(.system(size: 24))
                
                Text(region.displayName)
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(isAvailable ? .primary : .secondary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hexCode: "A76545"))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isAvailable)
    }
}

// MARK: - 공휴일 캘린더 추가 가이드 뷰
struct HolidayCalendarGuideView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 헤더
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(Color(hexCode: "A76545"))
                        
                        Text("다른 국가의 공휴일 추가하기")
                            .font(.pretendardBold(size: 24))
                        
                        Text("iOS 캘린더 앱에서 원하는 국가의 공휴일 캘린더를 구독하면 하루뷰에서도 해당 공휴일을 볼 수 있어요.")
                            .font(.pretendardRegular(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    // 단계별 가이드
                    VStack(alignment: .leading, spacing: 16) {
                        Text("추가 방법")
                            .font(.pretendardSemiBold(size: 18))
                        
                        GuideStep(
                            number: 1,
                            title: "캘린더 앱 열기",
                            description: "iOS 기본 캘린더 앱을 실행하세요"
                        )
                        
                        GuideStep(
                            number: 2,
                            title: "캘린더 메뉴 접근",
                            description: "하단의 '캘린더' 탭을 선택하세요"
                        )
                        
                        GuideStep(
                            number: 3,
                            title: "캘린더 추가",
                            description: "좌측 하단의 '캘린더 추가'를 선택하세요"
                        )
                        
                        GuideStep(
                            number: 4,
                            title: "공휴일 캘린더 추가",
                            description: "'공휴일 캘린더 추가'를 선택하고 원하는 국가를 추가하세요"
                        )
                        
                        GuideStep(
                            number: 5,
                            title: "하루뷰 새로고침",
                            description: "하루뷰로 돌아와서 새로고침하면 해당 국가의 공휴일이 표시됩니다"
                        )
                    }
                    
                    // 주의사항
                    VStack(alignment: .leading, spacing: 12) {
                        Text("주의사항")
                            .font(.pretendardSemiBold(size: 18))
                        
                        Text("• 공휴일 캘린더는 해당 국가의 언어로만 제공될 수 있습니다\n• 일부 국가의 공휴일 캘린더는 제공되지 않을 수 있습니다\n• 추가한 캘린더는 iOS 캘린더 앱에서도 함께 표시됩니다")
                            .font(.pretendardRegular(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(20)
            }
            .navigationTitle("공휴일 캘린더 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                    .foregroundStyle(Color(hexCode: "A76545"))
                }
            }
        }
    }
}

struct GuideStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 번호 원
            Text("\(number)")
                .font(.pretendardSemiBold(size: 14))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color(hexCode: "A76545"))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.pretendardSemiBold(size: 16))
                
                Text(description)
                    .font(.pretendardRegular(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HolidayRegionSettingView()
    }
}