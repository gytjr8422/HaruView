//
//  CalendarView.swift
//  HaruView
//
//  Created by 김효석 on 7/7/25.
//

import SwiftUI

struct CalendarView: View {
    @Environment(\.di) private var di
    @Environment(\.scenePhase) private var phase
    @StateObject private var vm: CalendarViewModel
    @State private var showDayDetail = false
    @State private var selectedDayForDetail: CalendarDay?
    @State private var showAddSheet = false
    @State private var quickAddDate: Date?
    
    @State private var showMonthYearPicker = false
    
    // 편집 후 새로고침을 위한 상태
    @State private var pendingDetailDate: Date?
    
    // ID 최적화: 현재 표시 중인 월만 기준으로 ID 생성
    private var optimizedViewID: String {
        "\(vm.state.currentYear)-\(String(format: "%02d", vm.state.currentMonth))"
    }
    
    init() {
        _vm = StateObject(wrappedValue: DIContainer.shared.makeCalendarViewModel())
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hexCode: "FFFCF5")
                    .ignoresSafeArea()
                
                if vm.isLoading && vm.monthWindow.isEmpty {
                    loadingView
                } else if let error = vm.error, vm.monthWindow.isEmpty {
                    errorView(error)
                } else if !vm.monthWindow.isEmpty {
                    calendarContent
                } else {
                    emptyStateView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 왼쪽: 이전 달 버튼
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            vm.moveToDirectPreviousMonth()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(hexCode: "A76545"))
                    }
                }
                
                // 중앙: 월/년 + 오늘 버튼 (터치로 월/년 선택)
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            showMonthYearPicker = true
                        }) {
                            HStack(spacing: 4) {
                                Text(vm.monthDisplayText)
                                    .font(.pretendardSemiBold(size: 18))
                                    .foregroundStyle(Color(hexCode: "40392B"))
                                
                                // 시각적 힌트 아이콘
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color(hexCode: "A76545").opacity(0.7))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button("오늘") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                vm.moveToToday()
                            }
                        }
                        .font(.pretendardRegular(size: 12))
                        .foregroundStyle(Color(hexCode: "A76545"))
                    }
                }
                
                // 오른쪽: 다음 달 버튼
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            vm.moveToDirectNextMonth()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(hexCode: "A76545"))
                    }
                }
            }
        }
        .sheet(isPresented: $showDayDetail) {
            if let dayData = selectedDayForDetail {
                DayDetailSheet(initialDate: dayData.date)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            if let date = quickAddDate {
                AddSheet(vm: di.makeAddSheetVMWithDate(date)) {
                    vm.refresh()
                }
            }
        }
        .sheet(isPresented: $showMonthYearPicker) {
            MonthYearPickerSheet(
                currentYear: vm.state.currentYear,
                currentMonth: vm.state.currentMonth,
                onDateSelected: { year, month in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        vm.moveToMonth(year: year, month: month)
                    }
                }
            )
        }
        .onChange(of: showDayDetail) { _, isShowing in
            if !isShowing {
                selectedDayForDetail = nil
            }
        }
        .onChange(of: showAddSheet) { _, isShowing in
            if !isShowing {
                quickAddDate = nil
            }
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .active {
                vm.refresh()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                vm.forceRefresh()
            }
        }
    }
    
    @ViewBuilder
    private var calendarContent: some View {
        VStack(spacing: 0) {
            // 요일 헤더
            WeekdayHeaderView()
            
            // 최적화된 PagedTabView - 현재 월만 기준으로 ID 설정
            if vm.monthWindow.count >= 7 {
                OptimizedPagedCalendarView(
                    monthWindow: vm.monthWindow,
                    currentIndex: vm.currentWindowIndex,
                    selectedDate: vm.selectedDate,
                    onPageChange: { index in
                        vm.handlePageChange(to: index)
                    },
                    onDateTap: { date in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            vm.selectDate(date)
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showDayDetailIfNeeded(for: date)
                        }
                    },
                    onDateLongPress: { date in
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        quickAddDate = date
                        showAddSheet = true
                    }
                )
                .id(optimizedViewID) // 최적화된 ID 사용
            } else {
                ProgressView("달력 준비 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            if vm.isLoading && !vm.monthWindow.isEmpty {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("업데이트 중...")
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .transition(.opacity)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("달력을 불러오는 중...")
                .font(.pretendardRegular(size: 16))
                .foregroundStyle(Color(hexCode: "6E5C49"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ error: TodayBoardError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
            
            Text("달력을 불러올 수 없습니다")
                .font(.pretendardSemiBold(size: 18))
                .foregroundStyle(Color(hexCode: "40392B"))
            
            Text(error.description)
                .font(.pretendardRegular(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("다시 시도") {
                vm.refresh()
            }
            .font(.pretendardSemiBold(size: 16))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(hexCode: "A76545"))
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 50))
                .foregroundStyle(Color(hexCode: "A76545"))
            
            Text("달력 데이터가 없습니다")
                .font(.pretendardSemiBold(size: 18))
                .foregroundStyle(Color(hexCode: "40392B"))
            
            Button("새로고침") {
                vm.loadCurrentMonth()
            }
            .font(.pretendardRegular(size: 16))
            .foregroundStyle(Color(hexCode: "A76545"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func showDayDetailIfNeeded(for date: Date) {
        guard vm.isCurrentMonthDataReady,
              !vm.isLoading,
              vm.error == nil else { return }
        
        guard !showDayDetail else { return }
        
        let calendarDay = findCalendarDay(for: date) ?? CalendarDay(date: date, events: [], reminders: [])
        
        DispatchQueue.main.async {
            self.selectedDayForDetail = calendarDay
            self.showDayDetail = true
        }
    }
    
    private func findCalendarDay(for date: Date) -> CalendarDay? {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        if let currentMonth = vm.monthWindow.first(where: {
            $0.year == vm.state.currentYear && $0.month == vm.state.currentMonth
        }) {
            if let day = currentMonth.day(for: targetDate) {
                return day
            }
        }
        
        for monthData in vm.monthWindow {
            if let day = monthData.day(for: targetDate) {
                return day
            }
        }
        
        return nil
    }
}

// MARK: - 최적화된 PagedCalendarView 컴포넌트
struct OptimizedPagedCalendarView: View {
    let monthWindow: [CalendarMonth]
    let currentIndex: Int
    let selectedDate: Date?
    let onPageChange: (Int) -> Void
    let onDateTap: (Date) -> Void
    let onDateLongPress: (Date) -> Void
    
    // currentIndex 변경을 감지하여 PagedTabView의 바인딩 업데이트
    @State private var internalCurrentIndex: Int = 3
    @State private var isInternalUpdate = false
    
    var body: some View {
        PagedTabView(
            currentIndex: $internalCurrentIndex,
            views: monthWindow.enumerated().map { index, monthData in
                MonthGridView(
                    monthData: monthData,
                    selectedDate: selectedDate,
                    isCurrentDisplayedMonth: index == currentIndex,
                    onDateTap: onDateTap,
                    onDateLongPress: onDateLongPress
                )
                .id("\(monthData.year)-\(monthData.month)") // 개별 월은 개별 ID 유지
            },
            onPageSettled: { index in
                // 내부 스와이프로 인한 변경임을 표시
                isInternalUpdate = true
                internalCurrentIndex = index
                onPageChange(index)
                
                // 플래그 리셋
                DispatchQueue.main.async {
                    isInternalUpdate = false
                }
            }
        )
        .onAppear {
            internalCurrentIndex = currentIndex
        }
        .onChange(of: currentIndex) { _, newIndex in
            // 외부에서 currentIndex가 변경되었을 때만 업데이트
            // 내부 스와이프로 인한 변경은 onPageSettled에서 처리
            if !isInternalUpdate && internalCurrentIndex != newIndex {
                internalCurrentIndex = newIndex
            }
        }
    }
}

#Preview {
    CalendarView()
        .environment(\.di, .shared)
}
