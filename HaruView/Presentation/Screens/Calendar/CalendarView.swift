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
            // 빈 날짜든 아니든 항상 시트 열기
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
            
            // PagedTabView로 3개월 표시
            if vm.monthWindow.count >= 3 {
                PagedTabView(
                    currentIndex: $vm.currentWindowIndex,
                    views: vm.monthWindow.map { monthData in
                        MonthGridView(
                            monthData: monthData,
                            selectedDate: vm.selectedDate,
                            isCurrentDisplayedMonth: monthData.year == vm.state.currentYear &&
                                                   monthData.month == vm.state.currentMonth,
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
                        .id("\(monthData.year)-\(monthData.month)")
                    },
                    onPageSettled: { index in
                        vm.handlePageChange(to: index)
                    }
                )
                .id(vm.monthWindow.map { "\($0.year)-\($0.month)" }.joined(separator: "_"))
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
        // 데이터 준비 상태 확인을 더 엄격하게
        guard vm.isCurrentMonthDataReady,
              !vm.isLoading,
              vm.error == nil else { return }
        
        // 이미 시트가 표시 중이면 중복 방지
        guard !showDayDetail else { return }
        
        // CalendarDay 찾기 (빈 날짜라도 CalendarDay 객체는 생성)
        let calendarDay = findCalendarDay(for: date) ?? CalendarDay(date: date, events: [], reminders: [])
        
        // 빈 날짜든 아니든 항상 시트 열기
        DispatchQueue.main.async {
            self.selectedDayForDetail = calendarDay
            self.showDayDetail = true
        }
    }
    
    // 수정된 부분: findCalendarDay 메서드 개선
    private func findCalendarDay(for date: Date) -> CalendarDay? {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        // 먼저 현재 월에서 찾기
        if let currentMonth = vm.monthWindow.first(where: {
            $0.year == vm.state.currentYear && $0.month == vm.state.currentMonth
        }) {
            if let day = currentMonth.day(for: targetDate) {
                return day
            }
        }
        
        // 전체 윈도우에서 찾기
        for monthData in vm.monthWindow {
            if let day = monthData.day(for: targetDate) {
                return day
            }
        }
        
        return nil
    }
    
    // MARK: - 편집 후 새로고침 처리
    
    /// 편집 완료 후 데이터 변경 처리
    private func handleDataChangedInDetail() {
        // 현재 선택된 날짜 저장
        if let currentDay = selectedDayForDetail {
            pendingDetailDate = currentDay.date
        }
        
        // 시트 닫기
        showDayDetail = false
        selectedDayForDetail = nil
        
        // 데이터 새로고침
        vm.forceRefresh()
    }
    
    /// 새로고침 후 DayDetail 다시 열기
    private func reopenDayDetail(for date: Date) {
        guard let updatedCalendarDay = findCalendarDay(for: date),
              updatedCalendarDay.hasItems else {
            pendingDetailDate = nil
            return
        }
        
        // 업데이트된 데이터로 다시 시트 열기
        selectedDayForDetail = updatedCalendarDay
        showDayDetail = true
        pendingDetailDate = nil
    }
}

#Preview {
    CalendarView()
        .environment(\.di, .shared)
}
