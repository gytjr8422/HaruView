//
//  SettingsView.swift
//  HaruView
//
//  Created by 김효석 on 8/1/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var subscribedCalendars: [HolidayCalendarInfo] = []
    
    private let eventKitService = EventKitService()
    
    var body: some View {
        ZStack {
            Color.haruBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 달력 설정 섹션
                    calendarSettingsSection
                    
                    // 앱 정보 섹션
                    appInfoSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 70)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                LocalizedText(key: "설정")
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
                        
                        LocalizedText(key: "뒤로")
                            .font(.pretendardRegular(size: 16))
                    }
                    .foregroundStyle(.haruPrimary)
                }
            }
        }
        .improvedSwipeBack {
            dismiss()
        }
        .onAppear {
            loadSubscribedCalendars()
        }
    }
    
    // MARK: - 계산된 프로퍼티들
    private var selectedCalendars: [HolidayCalendarInfo] {
        return subscribedCalendars.filter { calendar in
            settings.selectedHolidayCalendarIds.contains(calendar.id)
        }
    }
    
    private var holidayStatusText: String {
        let selectedCount = selectedCalendars.count
        let totalCount = subscribedCalendars.count
        
        if totalCount == 0 {
            return "구독된 캘린더 없음".localized()
        } else if selectedCount == 0 {
            return "선택된 캘린더 없음".localized()
        } else if selectedCount == 1 {
            return selectedCalendars.first?.countryName ?? "1개 선택됨".localized()
        } else {
            return "\(selectedCount)개 선택됨".localized(with: selectedCount)
        }
    }
    
    // MARK: - 메서드들
    private func loadSubscribedCalendars() {
        subscribedCalendars = eventKitService.getSubscribedHolidayCalendars()
    }
    
    // MARK: - 달력 설정 섹션
    private var calendarSettingsSection: some View {
        VStack(spacing: 0) {
            // 섹션 헤더
            HStack {
                LocalizedText(key: "달력 설정")
                    .font(.pretendardBold(size: 17))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                // 언어 설정
                languageSettingCard
                
                Divider()
                    .padding(.horizontal, 16)
                    .background(.haruSecondary.opacity(0.1))
                
                // 주 시작일 설정
                weekStartToggleCard
                
                Divider()
                    .padding(.horizontal, 16)
                    .background(.haruSecondary.opacity(0.1))
                
                // 공휴일 표시 토글
                holidayToggleCard
                
                // 공휴일 국가 설정 (조건부)
                if settings.showHolidays {
                    Divider()
                        .padding(.horizontal, 16)
                        .background(.haruSecondary.opacity(0.1))
                    
                    holidayRegionCard
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
    
    // MARK: - 주 시작일 설정 카드
    private var weekStartToggleCard: some View {
        NavigationLink {
            WeekStartSelectionView()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "calendar.day.timeline.leading")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.haruPrimary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    LocalizedText(key: "주 시작일")
                        .font(.pretendardRegular(size: 16))
                        .foregroundStyle(.haruTextPrimary)
                    
                    LocalizedText(key: settings.weekStartsOnMonday ? "월요일부터 시작" : "일요일부터 시작")
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
    
    // MARK: - 공휴일 표시 토글 카드
    private var holidayToggleCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.haruPrimary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                LocalizedText(key: "공휴일 표시")
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(.haruTextPrimary)
                
                LocalizedText(key: "달력에 공휴일을 표시합니다")
                    .font(.pretendardRegular(size: 12))
                    .foregroundStyle(.haruSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $settings.showHolidays)
                .labelsHidden()
                .tint(.haruPrimary)
                .onChange(of: settings.showHolidays) { _, newValue in
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - 공휴일 국가 설정 카드
    private var holidayRegionCard: some View {
        NavigationLink {
            HolidayRegionSettingView()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.haruPrimary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    LocalizedText(key: "공휴일 캘린더 설정")
                        .font(.pretendardRegular(size: 16))
                        .foregroundStyle(.haruTextPrimary)
                    
                    Text(holidayStatusText)
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
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - 언어 설정 카드
    private var languageSettingCard: some View {
        NavigationLink {
            LanguageSelectionView()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "globe")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.haruPrimary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    LocalizedText(key: "언어 설정")
                        .font(.pretendardRegular(size: 16))
                        .foregroundStyle(.haruTextPrimary)
                    
                    Text(languageManager.currentLanguage.displayName)
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
    
    // MARK: - 앱 정보 섹션
    private var appInfoSection: some View {
        VStack(spacing: 0) {
            // 섹션 헤더
            HStack {
                LocalizedText(key: "앱 정보")
                    .font(.pretendardBold(size: 17))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.bottom, 12)
            
            // 앱 정보 카드
            HStack(spacing: 16) {
                Image(systemName: "info.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.haruPrimary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    LocalizedText(key: "앱 정보")
                        .font(.pretendardRegular(size: 16))
                        .foregroundStyle(.haruTextPrimary)
                    
                    Text("HaruView")
                        .font(.pretendardRegular(size: 12))
                        .foregroundStyle(.haruSecondary)
                }
                
                Spacer()
                
                Text("버전".localized() + " \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .font(.pretendardRegular(size: 14))
                    .foregroundStyle(.haruSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
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
    
}

#Preview {
    SettingsView()
}

