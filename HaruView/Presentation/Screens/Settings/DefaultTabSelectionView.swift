//
//  DefaultTabSelectionView.swift
//  HaruView
//
//  Created by Claude on 8/29/25.
//

import SwiftUI

struct DefaultTabSelectionView: View {
    @Binding var selectedTab: TabItem
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    
    private let availableTabs: [TabItem] = [.home, .calendar]
    
    var body: some View {
        ZStack {
            Color.haruBackground
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 탭 선택 카드들
                VStack(spacing: 0) {
                    ForEach(Array(availableTabs.enumerated()), id: \.element.id) { index, tab in
                        TabSelectionCard(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            onTap: {
                                selectedTab = tab
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                        )
                        
                        if index < availableTabs.count - 1 {
                            Divider()
                                .padding(.horizontal, 16)
                                .background(.haruSecondary.opacity(0.1))
                        }
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
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                LocalizedText(key: "기본 시작 탭")
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
    }
}

struct TabSelectionCard: View {
    let tab: TabItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 탭 아이콘
                Image(systemName: isSelected ? tab.selectedIconName : tab.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.haruPrimary)
                    .frame(width: 24, height: 24)
                
                // 탭 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(tab.title)
                        .font(.pretendardRegular(size: 16))
                        .foregroundStyle(.haruTextPrimary)
                    
                    Text(tab == .home ? "오늘의 일정과 할 일을 확인".localized() : "월간 달력 보기".localized())
                        .font(.pretendardRegular(size: 12))
                        .foregroundStyle(.haruSecondary)
                }
                
                Spacer()
                
                // 선택 표시
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.haruPrimary)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.haruSecondary.opacity(0.3))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        DefaultTabSelectionView(selectedTab: .constant(.home))
    }
}