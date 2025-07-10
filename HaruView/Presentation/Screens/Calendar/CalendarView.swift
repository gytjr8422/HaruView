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
            // 수정된 부분: 데이터 유효성을 다시 한 번 확인
            if let dayData = selectedDayForDetail,
               dayData.hasItems {
                DayDetailSheet(calendarDay: dayData)
            } else {
                // 빈 시트 방지: 데이터가 없으면 즉시 닫기
                EmptyView()
                    .onAppear {
                        showDayDetail = false
                        selectedDayForDetail = nil
                    }
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
        
        // CalendarDay 찾기
        guard let calendarDay = findCalendarDay(for: date) else { return }
        
        // 아이템이 있는지 확인
        let totalCount = calendarDay.events.count + calendarDay.reminders.count
        
        // 실제로 표시할 아이템이 있는지 재확인
        if totalCount > 0 && calendarDay.hasItems {
            // 데이터를 다시 한 번 검증
            DispatchQueue.main.async {
                // UI 업데이트 시점에서 다시 확인
                let revalidatedDay = self.findCalendarDay(for: date)
                let revalidatedCount = (revalidatedDay?.events.count ?? 0) + (revalidatedDay?.reminders.count ?? 0)
                
                if revalidatedCount > 0, let validDay = revalidatedDay, validDay.hasItems {
                    self.selectedDayForDetail = validDay
                    self.showDayDetail = true
                }
            }
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
}


// MARK: - 월/년 선택기 시트
struct MonthYearPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let currentYear: Int
    let currentMonth: Int
    let onDateSelected: (Int, Int) -> Void
    
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    
    init(currentYear: Int, currentMonth: Int, onDateSelected: @escaping (Int, Int) -> Void) {
        self.currentYear = currentYear
        self.currentMonth = currentMonth
        self.onDateSelected = onDateSelected
        _selectedYear = State(initialValue: currentYear)
        _selectedMonth = State(initialValue: currentMonth)
    }
    
    private let years = Array(2020...2030)
    private let months = Array(1...12)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("이동할 월을 선택하세요")
                    .font(.pretendardSemiBold(size: 18))
                    .foregroundStyle(Color(hexCode: "40392B"))
                    .padding(.top, 20)
                
                HStack(spacing: 20) {
                    // 년도 선택
                    VStack(spacing: 8) {
                        Picker("년", selection: $selectedYear) {
                            ForEach(years, id: \.self) { year in
                                Text(String(year) + "년").tag(year)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                    
                    // 월 선택
                    VStack(spacing: 8) {
                        Picker("월", selection: $selectedMonth) {
                            ForEach(months, id: \.self) { month in
                                Text(String(month) + "월").tag(month)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color(hexCode: "FFFCF5"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(Color(hexCode: "A76545"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("이동") {
                        onDateSelected(selectedYear, selectedMonth)
                        dismiss()
                    }
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundStyle(Color(hexCode: "A76545"))
                }
                
                ToolbarItem(placement: .principal) {
                    Text("년/월 선택")
                        .font(.pretendardSemiBold(size: 17))
                        .foregroundStyle(Color(hexCode: "40392B"))
                }
            }
        }
        .presentationDetents([.fraction(0.35)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - MonthGridView (개별 월 표시용)
struct MonthGridView: View {
    let monthData: CalendarMonth
    let selectedDate: Date?
    let isCurrentDisplayedMonth: Bool
    let onDateTap: (Date) -> Void
    let onDateLongPress: (Date) -> Void
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(monthData.calendarDates, id: \.self) { date in
                        CalendarDayCell(
                            date: date,
                            calendarDay: monthData.day(for: date),
                            isSelected: isDateSelected(date),
                            isToday: Calendar.current.isDateInToday(date),
                            isCurrentMonth: isDateInCurrentMonth(date),
                            onTap: {
                                onDateTap(date)
                            },
                            onLongPress: {
                                onDateLongPress(date)
                            }
                        )
                    }
                }
                .padding(.horizontal, 2)
                .transition(.opacity)
                
                Spacer(minLength: 20)
            }
        }
        .refreshable {
            // 부모 뷰에서 전체 새로고침 처리
        }
    }
    
    private func isDateSelected(_ date: Date) -> Bool {
        guard let selectedDate = selectedDate else { return false }
        return Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    private func isDateInCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month], from: date)
        return dateComponents.year == monthData.year && dateComponents.month == monthData.month
    }
}

// MARK: - 기존 Sheet들은 그대로 유지
// DayDetailSheet, QuickAddSheet 등은 기존과 동일

#Preview {
    CalendarView()
        .environment(\.di, .shared)
}

// OptimizedCalendarTabView 제거 - 불필요한 래퍼 컴포넌트

// MARK: - 최적화된 달력 페이지 컴포넌트 (ProgressView 최소화)
struct CalendarPageView: View {
    let monthData: CalendarMonth?
    let pageIndex: Int
    let selectedDate: Date?
    let onDateTap: (Date, Int) -> Void
    let onDateLongPress: (Date) -> Void
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                if let monthData = monthData {
                    // 데이터가 있는 경우 (즉시 표시)
                    CalendarGridView(
                        monthData: monthData,
                        selectedDate: selectedDate,
                        onDateTap: { date in
                            onDateTap(date, pageIndex)
                        },
                        onDateLongPress: onDateLongPress
                    )
                    .id("\(monthData.year)-\(monthData.month)")
                    .padding(.horizontal, 20)
                } else {
                    // 로딩 상태 (최소화된 플레이스홀더)
                    CalendarGridPlaceholder()
                        .padding(.horizontal, 20)
                }
                
                // 하단 여백 추가 (탭바와 겹치지 않도록)
                Spacer(minLength: 100)
            }
        }
    }
}

// MARK: - 가벼운 플레이스홀더 (ProgressView 대신)
struct CalendarGridPlaceholder: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            // 6주 × 7일 = 42개 셀의 플레이스홀더
            ForEach(0..<42, id: \.self) { index in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 108) // CalendarDayCell과 동일한 높이
                    .overlay {
                        if index == 21 { // 중앙에만 작은 인디케이터
                            ProgressView()
                                .scaleEffect(0.6)
                                .opacity(0.5)
                        }
                    }
            }
        }
    }
}
// MARK: - Day Detail Sheet
struct DayDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.di) private var di
    let calendarDay: CalendarDay
    
    // 시트가 로드될 때 데이터 유효성 확인
    @State private var isDataValid: Bool = false
    @State private var editingEvent: Event?
    @State private var editingReminder: Reminder?
    @State private var showToast: Bool = false
    
    // 로컬 상태로 reminders 관리 (토글 업데이트를 위해)
    @State private var localReminders: [CalendarReminder] = []
    
    var body: some View {
        NavigationStack {
            if isDataValid && (calendarDay.hasItems || !localReminders.isEmpty) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        headerView
                        
                        if !calendarDay.events.isEmpty {
                            eventSection
                        }
                        
                        if !localReminders.isEmpty {
                            reminderSection
                        }
                        
                        Spacer(minLength: 20)
                    }
                }
                .background(Color(hexCode: "FFFCF5"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("닫기") {
                            dismiss()
                        }
                        .font(.pretendardRegular(size: 16))
                        .foregroundStyle(Color(hexCode: "A76545"))
                    }
                }
            } else {
                loadingOrEmptyView
            }
        }
        .sheet(item: $editingEvent) { event in
            AddSheet(vm: di.makeEditSheetVM(event: event)) {
                showToast = true
            }
        }
        .sheet(item: $editingReminder) { reminder in
            AddSheet(vm: di.makeEditSheetVM(reminder: reminder)) {
                showToast = true
            }
        }
        .overlay(toastOverlay)
        .onAppear {
            // 초기 데이터 설정
            localReminders = calendarDay.reminders
            validateData()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Header
    private var headerView: some View {
        Text(dateFormatter.string(from: calendarDay.date))
            .font(.pretendardBold(size: 20))
            .foregroundStyle(Color(hexCode: "40392B"))
            .padding(.horizontal, 20)
            .padding(.top, 10)
    }
    
    // MARK: - Event Section
    private var eventSection: some View {
        VStack(alignment: .leading) {
            Text("일정")
                .font(.pretendardSemiBold(size: 18))
                .foregroundStyle(Color(hexCode: "40392B"))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            
            ForEach(calendarDay.events, id: \.id) { event in
                EventDetailRow(event: event)
            }
        }
    }
    
    // MARK: - Reminder Section with Toggle
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("할일")
                .font(.pretendardSemiBold(size: 18))
                .foregroundStyle(Color(hexCode: "40392B"))
                .padding(.horizontal, 20)
            
            // HomeView와 동일한 스타일의 컨테이너
            VStack(spacing: 0) {
                ForEach(Array(localReminders.enumerated()), id: \.element.id) { index, reminder in
                    ReminderCard(reminder: convertToFullReminder(reminder)) {
                        // 토글 기능 구현
                        toggleReminder(reminder)
                    }
                    
                    // 마지막 아이템이 아니면 구분선 추가 (HomeView와 동일)
                    if index < localReminders.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                            .background(Color.gray.opacity(0.1))
                    }
                }
            }
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hexCode: "C2966B").opacity(0.09))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hexCode: "C2966B").opacity(0.5), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Loading or Empty View
    private var loadingOrEmptyView: some View {
        VStack(spacing: 16) {
            if !isDataValid {
                ProgressView("로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("표시할 내용이 없습니다")
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(hexCode: "FFFCF5"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("닫기") {
                    dismiss()
                }
                .font(.pretendardRegular(size: 16))
                .foregroundStyle(Color(hexCode: "A76545"))
            }
        }
        .onAppear {
            // 짧은 지연 후 데이터 유효성 재확인
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                validateData()
            }
        }
    }
    
    // MARK: - Toast Overlay
    private var toastOverlay: some View {
        Group {
            if showToast {
                VStack {
                    Spacer()
                    Text("변경사항이 저장되었습니다")
                        .font(.pretendardSemiBold(size: 14))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: showToast)
            }
        }
    }
    
    // MARK: - Helper Functions
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .full
        return formatter
    }
    
    // 할 일 토글 기능
    private func toggleReminder(_ calendarReminder: CalendarReminder) {
        Task {
            // Use Case를 통해 실제 데이터 토글
            let toggleUseCase = di.makeToggleReminderUseCase()
            let result = await toggleUseCase(calendarReminder.id)
            
            await MainActor.run {
                switch result {
                case .success:
                    // 로컬 상태 업데이트 (애니메이션과 함께)
                    if let index = localReminders.firstIndex(where: { $0.id == calendarReminder.id }) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            // 완료 상태만 토글 (CalendarReminder는 struct이므로 전체를 새로 만들어야 함)
                            let originalReminder = localReminders[index]
                            
                            // 원본 Reminder로 변환 후 상태 변경
                            let fullReminder = convertToFullReminder(originalReminder)
                            let updatedFullReminder = Reminder(
                                id: fullReminder.id,
                                title: fullReminder.title,
                                due: fullReminder.due,
                                isCompleted: !fullReminder.isCompleted, // 토글
                                priority: fullReminder.priority,
                                notes: fullReminder.notes,
                                url: fullReminder.url,
                                location: fullReminder.location,
                                hasAlarms: fullReminder.hasAlarms,
                                alarms: fullReminder.alarms,
                                calendar: fullReminder.calendar
                            )
                            
                            // 다시 CalendarReminder로 변환
                            let updatedCalendarReminder = CalendarReminder(from: updatedFullReminder)
                            localReminders[index] = updatedCalendarReminder
                            
                            // 정렬 (완료된 항목이 아래로)
                            localReminders.sort { a, b in
                                if a.isCompleted != b.isCompleted {
                                    return !a.isCompleted // 미완료가 먼저
                                }
                                return a.title < b.title // 제목순
                            }
                        }
                    }
                    
                    // 성공 토스트 표시
                    showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showToast = false
                    }
                    
                case .failure(let error):
                    print("❌ 할 일 토글 실패: \(error.description)")
                }
            }
        }
    }
    
    // CalendarReminder를 Reminder로 변환하는 헬퍼 함수
    private func convertToFullReminder(_ calendarReminder: CalendarReminder) -> Reminder {
        return Reminder(
            id: calendarReminder.id,
            title: calendarReminder.title,
            due: calendarReminder.dueTime,
            isCompleted: calendarReminder.isCompleted,
            priority: calendarReminder.priority,
            notes: nil,
            url: nil,
            location: nil,
            hasAlarms: false,
            alarms: [],
            calendar: ReminderCalendar(
                id: calendarReminder.id + "_calendar",
                title: "기본 목록",
                color: calendarReminder.calendarColor,
                type: .local,
                isReadOnly: false,
                allowsContentModifications: true,
                source: ReminderCalendar.CalendarSource(title: "로컬", type: .local)
            )
        )
    }
    
    private func validateData() {
        let totalItems = calendarDay.events.count + localReminders.count
        
        if totalItems > 0 {
            isDataValid = true
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        }
    }
}

// MARK: - Event Detail Row
struct EventDetailRow: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(event.calendarColor))
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .lineLimit(1)
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundStyle(Color(hexCode: "40392B"))
                
                if let timeText = event.timeDisplayText {
                    Text(timeText)
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.secondary)
                }
                
                if event.isAllDay {
                    Text("하루 종일")
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if event.hasAlarms {
                Image(systemName: "bell.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hexCode: "A76545"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(event.calendarColor).opacity(0.1))
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Reminder Detail Row
struct ReminderDetailRow: View {
    let reminder: CalendarReminder
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundStyle(reminder.isCompleted ? Color(hexCode: "A76545") : .secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundStyle(Color(hexCode: "40392B"))
                    .strikethrough(reminder.isCompleted)
                
                if let timeText = reminder.timeDisplayText {
                    Text(timeText)
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.secondary)
                }
                
                if reminder.priority > 0 {
                    HStack(spacing: 4) {
                        if let priorityColor = reminder.priorityColor {
                            Circle()
                                .fill(Color(priorityColor))
                                .frame(width: 8, height: 8)
                        }
                        Text(priorityText(reminder.priority))
                            .font(.pretendardRegular(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hexCode: "C2966B").opacity(0.1))
        )
        .padding(.horizontal, 20)
    }
    
    private func priorityText(_ priority: Int) -> String {
        switch priority {
        case 1: return "높은 우선순위"
        case 5: return "보통 우선순위"
        case 9: return "낮은 우선순위"
        default: return ""
        }
    }
}

// MARK: - Quick Add Sheet
struct QuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.di) private var di
    let date: Date
    let onSave: () -> Void
    
    @State private var selectedType: QuickAddType = .event
    @State private var title: String = ""
    @State private var showFullAddSheet = false
    
    enum QuickAddType: String, CaseIterable {
        case event = "일정"
        case reminder = "할일"
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(dateFormatter.string(from: date))
                    .font(.pretendardBold(size: 18))
                    .foregroundStyle(Color(hexCode: "40392B"))
                    .padding(.top, 10)
                
                Picker("타입", selection: $selectedType) {
                    ForEach(QuickAddType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("제목")
                        .font(.pretendardSemiBold(size: 16))
                        .foregroundStyle(Color(hexCode: "40392B"))
                    
                    TextField("제목을 입력하세요", text: $title)
                        .font(.pretendardRegular(size: 16))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 20)
                
                VStack(spacing: 12) {
                    Button("빠른 저장") {
                        saveQuickItem()
                    }
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hexCode: "A76545"))
                    .cornerRadius(8)
                    .disabled(title.isEmpty)
                    
                    Button("자세한 설정") {
                        showFullAddSheet = true
                    }
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(Color(hexCode: "A76545"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hexCode: "A76545"), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color(hexCode: "FFFCF5"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(Color(hexCode: "A76545"))
                }
                
                ToolbarItem(placement: .principal) {
                    Text("빠른 추가")
                        .font(.pretendardSemiBold(size: 18))
                        .foregroundStyle(Color(hexCode: "40392B"))
                }
            }
        }
        .sheet(isPresented: $showFullAddSheet) {
            AddSheet(vm: makePrefilledAddSheetVM()) {
                onSave()
                dismiss()
            }
        }
    }
    
    private func saveQuickItem() {
        Task {
            if selectedType == .event {
                await saveQuickEvent()
            } else {
                await saveQuickReminder()
            }
            
            await MainActor.run {
                onSave()
                dismiss()
            }
        }
    }
    
    private func saveQuickEvent() async {
        let startDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
        
        let input = EventInput(
            title: title,
            start: startDate,
            end: endDate,
            location: nil,
            notes: nil,
            url: nil,
            alarms: [],
            recurrenceRule: nil,
            calendarId: nil
        )
        
        let addEventUseCase = di.makeAddEventUseCase()
        _ = await addEventUseCase(input)
    }
    
    private func saveQuickReminder() async {
        let input = ReminderInput(
            title: title,
            due: date,
            includesTime: false,
            priority: 0,
            notes: nil,
            url: nil,
            location: nil,
            alarms: [],
            calendarId: nil
        )
        
        let addReminderUseCase = di.makeAddReminderUseCase()
        _ = await addReminderUseCase(input)
    }
    
    private func makePrefilledAddSheetVM() -> AddSheetViewModel {
        let vm = di.makeAddSheetVM()
        vm.mode = selectedType == .event ? .event : .reminder
        vm.currentTitle = title
        
        if selectedType == .event {
            vm.startDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
            vm.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: vm.startDate) ?? vm.startDate
        } else {
            vm.dueDate = date
        }
        
        return vm
    }
}

#Preview {
    CalendarView()
        .environment(\.di, .shared)
}


struct PagedTabView<Content: View>: UIViewControllerRepresentable {
    @Binding var currentIndex: Int
    let views: [Content]
    let onPageSettled: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )

        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator

        if let initialVC = context.coordinator.viewController(for: currentIndex) {
            controller.setViewControllers([initialVC], direction: .forward, animated: false)
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        // 뷰가 변경되었으면 컨트롤러들을 새로 생성
        context.coordinator.updateControllers(with: views)
        
        // 외부에서 currentIndex가 변경되었을 때만 업데이트
        if let currentVC = uiViewController.viewControllers?.first,
           let currentVCIndex = context.coordinator.controllers.firstIndex(of: currentVC),
           currentVCIndex != currentIndex {
            
            if let newVC = context.coordinator.viewController(for: currentIndex) {
                let direction: UIPageViewController.NavigationDirection = currentIndex > currentVCIndex ? .forward : .reverse
                uiViewController.setViewControllers([newVC], direction: direction, animated: true)
            }
        } else if let newVC = context.coordinator.viewController(for: currentIndex) {
            // 같은 인덱스라도 내용이 바뀌었을 수 있으므로 업데이트
            uiViewController.setViewControllers([newVC], direction: .forward, animated: false)
        }
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PagedTabView
        private(set) var controllers: [UIViewController]

        init(parent: PagedTabView) {
            self.parent = parent
            self.controllers = parent.views.map { UIHostingController(rootView: $0) }
        }
        
        // 뷰 컨트롤러들을 업데이트할 수 있는 메서드 추가
        func updateControllers(with views: [Content]) {
            controllers = views.map { UIHostingController(rootView: $0) }
        }

        func viewController(for index: Int) -> UIViewController? {
            guard index >= 0 && index < controllers.count else { return nil }
            return controllers[index]
        }

        func presentationCount(for _: UIPageViewController) -> Int { controllers.count }
        func presentationIndex(for _: UIPageViewController) -> Int { parent.currentIndex }

        func pageViewController(_: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController), index > 0 else { return nil }
            return controllers[index - 1]
        }

        func pageViewController(_: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController), index < controllers.count - 1 else { return nil }
            return controllers[index + 1]
        }

        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating _: Bool, previousViewControllers _: [UIViewController], transitionCompleted completed: Bool) {
            if completed, let visibleVC = pageViewController.viewControllers?.first,
               let newIndex = controllers.firstIndex(of: visibleVC) {
                parent.currentIndex = newIndex
                parent.onPageSettled(newIndex) // 손을 떼고 이동이 확정된 순간 호출
            }
        }
    }
}
