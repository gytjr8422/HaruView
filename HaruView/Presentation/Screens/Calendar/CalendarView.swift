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
                .padding(.top, 10)
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
                .padding(.top, 10)
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
                .padding(.top, 10)
            }
        }
        .sheet(isPresented: $showDayDetail) {
            if let dayData = selectedDayForDetail {
                DayDetailSheet(initialDate: dayData.date)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            if let date = quickAddDate {
                AddSheet(vm: di.makeAddSheetVMWithDate(date)) { isDeleted in
                    ToastManager.shared.show(isDeleted ? .delete : .success)
                    // 선택적 업데이트 사용 - 해당 날짜만 업데이트
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let targetDate = quickAddDate {
                            let affectedDates = [targetDate]
                            vm.selectiveUpdateManager.scheduleDateRangeUpdate(dates: affectedDates)
                        }
                    }
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
                // 현재 보고 있는 월과 인접 월만 선택적 업데이트
                let currentDate = vm.state.currentMonthFirstDay
                let calendar = Calendar.current
                let affectedDates = (-1...1).compactMap { offset in
                    calendar.date(byAdding: .month, value: offset, to: currentDate)
                }
                vm.selectiveUpdateManager.scheduleDateRangeUpdate(dates: affectedDates)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .calendarNeedsRefresh)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // 현재 보고 있는 월만 선택적 업데이트
                let currentDate = vm.state.currentMonthFirstDay
                vm.selectiveUpdateManager.scheduleDateRangeUpdate(dates: [currentDate])
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .calendarSelectiveUpdate)) { notification in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let dates = notification.userInfo?["dates"] as? [Date] {
                    vm.selectiveUpdateManager.scheduleDateRangeUpdate(dates: dates)
                }
            }
        }
    }
    
    @ViewBuilder
    private var calendarContent: some View {
        VStack(spacing: 0) {
            // 요일 헤더
            WeekdayHeaderView()
            
            // TabView 기반 달력
            if vm.monthWindow.count >= 7 {
                StableTabCalendarView(
                    currentIndex: $vm.currentWindowIndex,
                    monthWindow: vm.monthWindow,
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
                    },
                    onRefresh: {
                        await performRefresh()
                    }
                )
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
    
    /// Pull-to-refresh 액션
    private func performRefresh() async {
        // 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 캐시 무효화 및 EventKit 재조회
        await MainActor.run {
            // 캐시 전체 클리어
            CalendarCacheManager.shared.clearAllCache()
            
            // 완전한 재로드 (오늘 버튼과 동일한 방식)
            vm.refresh(force: true)
        }
        
        // 공휴일 설정 변경 확인을 위한 추가 지연
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
    }
}


#Preview {
    CalendarView()
        .environment(\.di, .shared)
}
