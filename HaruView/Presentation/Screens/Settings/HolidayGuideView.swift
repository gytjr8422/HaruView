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
                Text("공휴일 캘린더 추가 방법")
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
                        
                        Text("뒤로")
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
                Text("공휴일 캘린더 추가하기")
                    .font(.pretendardBold(size: 20))
                    .foregroundStyle(.haruTextPrimary)
                
                Text("iOS 캘린더 앱에서 원하는 국가의\n공휴일 캘린더를 구독해보세요")
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
                Text("단계별 가이드")
                    .font(.pretendardBold(size: 17))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                // 1단계
                guideStepView(
                    step: "1",
                    title: "캘린더 앱 열기",
                    description: "iPhone의 기본 캘린더 앱을 실행하세요",
                    icon: "calendar"
                )
                
                Divider()
                    .padding(.horizontal, 16)
                    .background(.haruSecondary.opacity(0.1))
                
                // 2단계
                guideStepView(
                    step: "2",
                    title: "캘린더 추가",
                    description: "하단의 '캘린더' 탭을 선택한 후 '캘린더 추가'를 탭하세요",
                    icon: "plus.circle"
                )
                
                Divider()
                    .padding(.horizontal, 16)
                    .background(.haruSecondary.opacity(0.1))
                
                // 3단계
                guideStepView(
                    step: "3",
                    title: "공휴일 캘린더 추가",
                    description: "'공휴일 캘린더 추가' 버튼을 탭하세요",
                    icon: "calendar.badge.plus"
                )
                
                Divider()
                    .padding(.horizontal, 16)
                    .background(.haruSecondary.opacity(0.1))
                
                // 4단계
                guideStepView(
                    step: "4",
                    title: "국가 검색",
                    description: "원하는 국가를 검색하세요",
                    icon: "magnifyingglass"
                )
                
                Divider()
                    .padding(.horizontal, 16)
                    .background(.haruSecondary.opacity(0.1))
                
                // 5단계
                guideStepView(
                    step: "5",
                    title: "공휴일 캘린더 선택",
                    description: "검색 결과에서 'Holidays in [국가명]' 형태의 캘린더를 선택하세요",
                    icon: "checkmark.circle"
                )
                
                Divider()
                    .padding(.horizontal, 16)
                    .background(.haruSecondary.opacity(0.1))
                
                // 6단계
                guideStepView(
                    step: "6",
                    title: "앱으로 돌아오기",
                    description: "하루뷰 앱으로 돌아와서 달력을 아래로 당기거나 '오늘' 버튼을 눌러 새로고침하세요",
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
                Text(title)
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundStyle(.haruTextPrimary)
                
                Text(description)
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
