//
//  MainTabView.swift
//  HaruView
//
//  Created by 김효석 on 7/7/25.
//

import SwiftUI

enum TabItem: CaseIterable, Identifiable {
    case home
    case calendar
    
    var id: String { rawValue }
    
    var rawValue: String {
        switch self {
        case .home: return "home"
        case .calendar: return "calendar"
        }
    }
    
    var title: String {
        switch self {
        case .home: return String(localized: "오늘")
        case .calendar: return String(localized: "달력")
        }
    }
    
    var iconName: String {
        switch self {
        case .home: return "\(currentDay).square"
        case .calendar: return "calendar"
        }
    }
    
    var selectedIconName: String {
        switch self {
        case .home: return "\(currentDay).square.fill"
        case .calendar: return "calendar"
        }
    }
    
    private var currentDay: Int {
        Calendar.current.component(.day, from: Date())
    }
}

struct MainTabView: View {
    @State private var selectedTab: TabItem = .home
    @Environment(\.di) private var di
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 메인 콘텐츠
            Group {
                switch selectedTab {
                case .home:
                    HomeView(vm: di.makeHomeVM())
                case .calendar:
                    CalendarView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            
            // 커스텀 탭 바
            HaruTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard) // 키보드 올라올 때 탭바 숨기지 않음
        .ignoresSafeArea(.all, edges: .bottom) // 탭바 하단 영역 무시
    }
}

struct HaruTabBar: View {
    @Binding var selectedTab: TabItem
    @Namespace private var tabIndicator
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases) { tab in
                TabBarButton(
                    tab: tab,
                    selectedTab: $selectedTab,
                    namespace: tabIndicator
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hexCode: "FFFCF5"))
                .shadow(
                    color: Color(hexCode: "6E5C49").opacity(0.15),
                    radius: 8,
                    x: 0,
                    y: -2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    Color(hexCode: "6E5C49").opacity(0.1),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}

struct TabBarButton: View {
    let tab: TabItem
    @Binding var selectedTab: TabItem
    let namespace: Namespace.ID
    
    private var isSelected: Bool {
        selectedTab == tab
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // 선택된 탭의 배경
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(hexCode: "A76545").opacity(0.15))
                            .frame(width: 100, height: 40)
                            .matchedGeometryEffect(
                                id: "selectedBackground",
                                in: namespace
                            )
                    }
                    
                    // 아이콘
                    Image(systemName: isSelected ? tab.selectedIconName : tab.iconName)
                        .font(.system(size: 24, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(
                            isSelected
                            ? Color(hexCode: "A76545")
                            : Color(hexCode: "6E5C49").opacity(0.6)
                        )
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                
                // 라벨
                Text(tab.title)
                    .font(.pretendardMedium(size: 11))
                    .foregroundStyle(
                        isSelected
                        ? Color(hexCode: "A76545")
                        : Color(hexCode: "6E5C49").opacity(0.6)
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environment(\.di, .shared)
}
