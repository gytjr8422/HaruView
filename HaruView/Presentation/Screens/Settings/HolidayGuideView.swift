//
//  HolidayGuideView.swift
//  HaruView
//
//  Created by 김효석 on 8/5/25.
//

import SwiftUI

struct HolidayGuideView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.haruBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // 제목 섹션
                    titleSection
                    
                    // 단계별 가이드
                    guideStepsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 70)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                LocalizedText(key: "holiday_calendar_guide_title")
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
        }
        .improvedSwipeBack {
            dismiss()
        }
    }
    
    // MARK: - 제목 섹션
    private var titleSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.haruPrimary)
            
            VStack(spacing: 8) {
                LocalizedText(key: "add_holiday_calendar")
                    .font(.pretendardBold(size: 20))
                    .foregroundStyle(.haruTextPrimary)
                
                LocalizedText(key: "holiday_calendar_description")
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(.haruSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 6)
    }
    
    // MARK: - 단계별 가이드
    private var guideStepsSection: some View {
        VStack(spacing: 0) {
            HStack {
                LocalizedText(key: "step_by_step_guide")
                    .font(.pretendardBold(size: 17))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                // 1단계
                guideStepView(
                    step: "1",
                    title: "open_calendar_app",
                    description: "launch_default_calendar_app",
                    icon: "calendar"
                )
                
                Divider()
                    .padding(.horizontal, 16)
                    .background(.haruSecondary.opacity(0.1))
                
                // 2단계
                guideStepView(
                    step: "2",
                    title: "add_calendar",
                    description: "select_calendar_tab_and_add",
                    icon: "plus.circle"
                )
                
                Divider()
                    .padding(.horizontal, 16)
                    .background(.haruSecondary.opacity(0.1))
                
                // 3단계
                guideStepView(
                    step: "3",
                    title: "add_holiday_calendar_button",
                    description: "tap_add_holiday_calendar_button",
                    icon: "calendar.badge.plus"
                )
                
                Divider()
                    .padding(.horizontal, 16)
                    .background(.haruSecondary.opacity(0.1))
                
                // 4단계
                guideStepView(
                    step: "4",
                    title: "search_country",
                    description: "search_desired_country",
                    icon: "magnifyingglass"
                )
                
                Divider()
                    .padding(.horizontal, 16)
                    .background(.haruSecondary.opacity(0.1))
                
                // 5단계
                guideStepView(
                    step: "5",
                    title: "select_holiday_calendar",
                    description: "select_holidays_in_country_calendar",
                    icon: "checkmark.circle"
                )
                
                Divider()
                    .padding(.horizontal, 16)
                    .background(.haruSecondary.opacity(0.1))
                
                // 6단계
                guideStepView(
                    step: "6",
                    title: "return_to_app",
                    description: "return_to_haruview_and_refresh",
                    icon: "arrow.clockwise"
                )
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
    
    // MARK: - 헬퍼 뷰들
    private func guideStepView(step: String, title: String, description: String, icon: String) -> some View {
        HStack(spacing: 16) {
            // 단계 번호
            ZStack {
                Circle()
                    .fill(.haruPrimary)
                    .frame(width: 32, height: 32)
                
                Text(step)
                    .font(.pretendardBold(size: 16))
                    .foregroundStyle(.white)
            }
            
            // 아이콘
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.haruPrimary)
                .frame(width: 24, height: 24)
            
            // 내용
            VStack(alignment: .leading, spacing: 4) {
                LocalizedText(key: title)
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundStyle(.haruTextPrimary)
                
                LocalizedText(key: description)
                    .font(.pretendardRegular(size: 14))
                    .foregroundStyle(.haruSecondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

#Preview {
    NavigationStack {
        HolidayGuideView()
    }
}
