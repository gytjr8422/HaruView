//
//  HolidayRegionSettingView.swift
//  HaruView
//
//  Created by 김효석 on 8/1/25.
//

import SwiftUI

struct HolidayRegionSettingView: View {
    @StateObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var subscribedCalendars: [HolidayCalendarInfo] = []
    
    private let eventKitService = EventKitService()
    
    var body: some View {
        ZStack {
            Color.haruBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 안내 섹션
                    guideSection
                    
                    // 구독된 공휴일 캘린더 섹션
                    if !subscribedCalendars.isEmpty {
                        subscribedCalendarsSection
                    } else {
                        emptyStateSection
                    }
                    
                    // 캘린더 앱에서 추가하는 방법 섹션
                    addCalendarGuideSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 70)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                LocalizedText(key: "holiday_calendar_settings")
                    .font(.pretendardSemiBold(size: 18))
                    .foregroundStyle(.haruTextPrimary)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        
                        LocalizedText(key: "back")
                            .font(.pretendardRegular(size: 16))
                    }
                    .foregroundStyle(.haruPrimary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    refreshSubscribedCalendars()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.haruPrimary)
                }
            }
        }
        .improvedSwipeBack {
            dismiss()
        }
        .onAppear {
            refreshSubscribedCalendars()
        }
        .refreshable {
            await refreshSubscribedCalendarsAsync()
        }
    }
    
    // MARK: - 안내 섹션
    private var guideSection: some View {
        VStack(spacing: 0) {
            HStack {
                LocalizedText(key: "select_holiday_calendars")
                    .font(.pretendardBold(size: 17))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.bottom, 12)
            
            HStack(spacing: 16) {
                Image(systemName: "info.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.haruPrimary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    LocalizedText(key: "only_subscribed_holidays_shown")
                        .font(.pretendardRegular(size: 16))
                        .foregroundStyle(.haruTextPrimary)
                    
                    LocalizedText(key: "select_desired_holiday_calendars")
                        .font(.pretendardRegular(size: 12))
                        .foregroundStyle(.haruSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.haruPrimary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.haruPrimary.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // MARK: - 구독된 캘린더 섹션
    private var subscribedCalendarsSection: some View {
        VStack(spacing: 0) {
            HStack {
                LocalizedText(key: "subscribed_holiday_calendars")
                    .font(.pretendardBold(size: 17))
                    .foregroundStyle(.secondary)
                Spacer()
                
                Text(String(format: "count_format".localized(), subscribedCalendars.count))
                    .font(.pretendardMedium(size: 14))
                    .foregroundStyle(.haruPrimary)
            }
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                ForEach(Array(subscribedCalendars.enumerated()), id: \.element.id) { index, calendar in
                    if index > 0 {
                        Divider()
                            .padding(.horizontal, 16)
                            .background(.haruSecondary.opacity(0.1))
                    }
                    
                    HStack(spacing: 16) {
                        // 캘린더 색상 인디케이터
                        Circle()
                            .fill(Color(calendar.color))
                            .frame(width: 12, height: 12)
                        
                        // 국기 이모지
                        Text(calendar.flagEmoji)
                            .font(.system(size: 20))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(calendar.countryName)
                                .font(.pretendardRegular(size: 16))
                                .foregroundStyle(.haruTextPrimary)
                            
                            Text(calendar.title)
                                .font(.pretendardRegular(size: 12))
                                .foregroundStyle(.haruSecondary)
                        }
                        
                        Spacer()
                        
                        // 토글 스위치
                        Toggle("", isOn: Binding(
                            get: { settings.selectedHolidayCalendarIds.contains(calendar.id) },
                            set: { isSelected in
                                if isSelected {
                                    settings.selectedHolidayCalendarIds.insert(calendar.id)
                                } else {
                                    settings.selectedHolidayCalendarIds.remove(calendar.id)
                                }
                                
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                        ))
                        .labelsHidden()
                        .tint(.haruPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.haruBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.haruSecondary.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - 빈 상태 섹션
    private var emptyStateSection: some View {
        VStack(spacing: 0) {
            HStack {
                LocalizedText(key: "subscribed_holiday_calendars")
                    .font(.pretendardBold(size: 17))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.bottom, 12)
            
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 48))
                    .foregroundStyle(.haruSecondary.opacity(0.6))
                
                VStack(spacing: 8) {
                    LocalizedText(key: "no_subscribed_holiday_calendars")
                        .font(.pretendardSemiBold(size: 16))
                        .foregroundStyle(.haruTextPrimary)
                    
                    LocalizedText(key: "please_subscribe_holiday_calendars_first")
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.haruSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.haruBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.haruSecondary.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - 캘린더 추가 가이드 섹션
    private var addCalendarGuideSection: some View {
        VStack(spacing: 0) {
            HStack {
                LocalizedText(key: "add_holiday_calendar")
                    .font(.pretendardBold(size: 17))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                // 캘린더 앱 열기 버튼
                Button {
                    openCalendarApp()
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.haruPrimary)
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            LocalizedText(key: "add_from_calendar_app")
                                .font(.pretendardRegular(size: 16))
                                .foregroundStyle(.haruTextPrimary)
                            
                            LocalizedText(key: "open_calendar_app_to_subscribe")
                                .font(.pretendardRegular(size: 12))
                                .foregroundStyle(.haruSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.haruSecondary.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .padding(.horizontal, 16)
                    .background(.haruSecondary.opacity(0.1))
                
                // 도움말 네비게이션 링크
                NavigationLink {
                    HolidayGuideView()
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.orange)
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            LocalizedText(key: "view_add_instructions")
                                .font(.pretendardRegular(size: 16))
                                .foregroundStyle(.haruTextPrimary)
                            
                            LocalizedText(key: "check_step_by_step_guide")
                                .font(.pretendardRegular(size: 12))
                                .foregroundStyle(.haruSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.haruSecondary.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.haruBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.haruSecondary.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - 메서드들
    private func refreshSubscribedCalendars() {
        subscribedCalendars = eventKitService.getSubscribedHolidayCalendars()
        
        // 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func refreshSubscribedCalendarsAsync() async {
        await MainActor.run {
            refreshSubscribedCalendars()
        }
    }
    
    /// 캘린더 앱 열기
    private func openCalendarApp() {
        // 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // 캘린더 앱 열기 (여러 URL 스킴 시도)
        let calendarURLs = [
            "calshow://",           // iOS 캘린더 앱 기본 스킴
            "x-apple-calendar://",  // 대체 스킴
            "calendar://"           // 추가 대체 스킴
        ]
        
        for urlString in calendarURLs {
            if let url = URL(string: urlString),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    if !success {
                        print("캘린더 앱 열기 실패: \(urlString)")
                    }
                }
                return
            }
        }
        
        // 모든 스킴이 실패할 경우 설정 앱으로 이동
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

#Preview {
    NavigationStack {
        HolidayRegionSettingView()
    }
}
