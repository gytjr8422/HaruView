//
//  CalendarViewModel.swift
//  HaruView
//
//  Created by 김효석 on 7/8/25.
//

import SwiftUI
import Combine

// MARK: - CalendarViewModel Protocol
protocol CalendarViewModelProtocol: ObservableObject {
    var state: CalendarState { get }
    var currentMonthData: CalendarMonth? { get }
    var isLoading: Bool { get }
    var error: TodayBoardError? { get }
    var selectedDate: Date? { get }
    
    // 7개월 윈도우 관련
    var monthWindow: [CalendarMonth] { get }
    var currentWindowIndex: Int { get }
    var isCurrentMonthDataReady: Bool { get }
    
    func loadCurrentMonth()
    func moveToMonth(year: Int, month: Int)
    func moveToPreviousMonth()
    func moveToNextMonth()
    func selectDate(_ date: Date)
    func refresh()
    func moveToToday()
    
    // PagedTabView 관련
    func handlePageChange(to index: Int)
    func moveToDirectPreviousMonth()
    func moveToDirectNextMonth()
    func forceRefresh()
    func isDateDataReady(for date: Date) -> Bool
}

// MARK: - CalendarViewModel Implementation
@MainActor
final class CalendarViewModel: ObservableObject, @preconcurrency CalendarViewModelProtocol {
    
    // MARK: - Published State
    @Published private(set) var state = CalendarState()
    @Published private(set) var hasInitialDataLoaded = false
    @Published private(set) var isDataReady = false
    
    // 7개월 윈도우 관리
    @Published private(set) var monthWindow: [CalendarMonth] = []
    @Published var currentWindowIndex = 3 // 중간이 현재 월
    
    // MARK: - Computed Properties
    var currentMonthData: CalendarMonth? { state.currentMonthData }
    var isLoading: Bool { state.isLoading }
    var error: TodayBoardError? { state.error }
    var selectedDate: Date? { state.selectedDate }
    
    // 7개월 윈도우 관련 프로퍼티
    var previousMonth: CalendarMonth? {
        monthWindow.indices.contains(2) ? monthWindow[2] : nil
    }
    
    var currentMonth: CalendarMonth? {
        monthWindow.indices.contains(1) ? monthWindow[3] : nil
    }
    
    var nextMonth: CalendarMonth? {
        monthWindow.indices.contains(2) ? monthWindow[4] : nil
    }
    
    /// 현재 월 데이터가 완전히 준비되었는지 확인
    var isCurrentMonthDataReady: Bool {
        return isDataReady &&
               !isLoading &&
               !monthWindow.isEmpty &&
               error == nil
    }
    
    // MARK: - Use Cases
    private let fetchMonth: FetchCalendarMonthUseCase
    private let fetchDay: FetchCalendarDayUseCase
    private let fetchWindow: FetchCalendarWindowUseCase
    private let cacheManager: CalendarCacheUseCase
    private let addEvent: AddEventUseCase
    private let addReminder: AddReminderUseCase
    private let deleteObject: DeleteObjectUseCase
    
    // MARK: - EventKit Service
    private let eventKitService: EventKitService
    
    // MARK: - Smart Data Loader & Progressive Update
    private let smartLoader = SmartDataLoader.shared
    private let progressiveUpdateManager = ProgressiveUpdateManager()
    let selectiveUpdateManager = SelectiveUpdateManager()
    
    // MARK: - Tasks & Combine
    private var loadTask: Task<Void, Never>?
    private var preloadTask: Task<Void, Never>?
    private var windowLoadTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var isLoadingNewWindow = false
    
    // MARK: - Initialization
    init(
        fetchMonth: FetchCalendarMonthUseCase,
        fetchDay: FetchCalendarDayUseCase,
        fetchWindow: FetchCalendarWindowUseCase,
        cacheManager: CalendarCacheUseCase,
        addEvent: AddEventUseCase,
        addReminder: AddReminderUseCase,
        deleteObject: DeleteObjectUseCase,
        eventKitService: EventKitService
    ) {
        self.fetchMonth = fetchMonth
        self.fetchDay = fetchDay
        self.fetchWindow = fetchWindow
        self.cacheManager = cacheManager
        self.addEvent = addEvent
        self.addReminder = addReminder
        self.deleteObject = deleteObject
        self.eventKitService = eventKitService
        
        // 초기 로드
        loadCurrentMonth()
        
        bindEventKitChanges()
        
        // 메모리 경고 시 캐시 정리
        setupMemoryWarningObserver()
        
        // 선택적 데이터 업데이트 알림 수신
        setupSelectiveUpdateObserver()
        
        // 달력 설정 변경 시 새로고침
        setupCalendarRefreshObserver()
    }
    
    deinit {
        loadTask?.cancel()
        preloadTask?.cancel()
        windowLoadTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// 현재 월 데이터 로드 (스마트 로딩)
    func loadCurrentMonth() {
        Task {
            await loadCurrentMonthSmart()
        }
    }
    
    /// 스마트 로더를 사용한 현재 월 로딩
    private func loadCurrentMonthSmart() async {
        state.isLoading = true
        state.error = nil
        
        do {
            // 1. 현재 월 우선 로드
            let result = await smartLoader.loadCurrentMonth(year: state.currentYear, month: state.currentMonth)
            
            switch result {
            case .success(let month):
                state.currentMonthData = month
                state.setCachedMonth(month)
                
                // 2. 7개월 윈도우 로드
                let windowMonths = await smartLoader.loadWindow(
                    centerYear: state.currentYear,
                    centerMonth: state.currentMonth,
                    range: 3
                )
                
                await MainActor.run {
                    self.monthWindow = windowMonths
                    self.currentWindowIndex = windowMonths.firstIndex { $0.year == state.currentYear && $0.month == state.currentMonth } ?? 3
                    self.isDataReady = true
                    self.hasInitialDataLoaded = true
                }
                
                // 3. 백그라운드에서 추가 범위 프리페치
                prefetchAdditionalMonths()
                
            case .failure(let error):
                await MainActor.run {
                    self.state.error = error
                }
            }
        }
        
        await MainActor.run {
            self.state.isLoading = false
        }
    }
    
    /// 백그라운드에서 추가 월 프리페치
    private func prefetchAdditionalMonths() {
        let currentYear = state.currentYear
        let currentMonth = state.currentMonth
        
        // 현재 월 기준 ±6개월 범위를 백그라운드에서 프리페치
        Task.detached(priority: .utility) {
            for offset in -6...6 {
                if abs(offset) <= 3 { continue } // 이미 로드된 범위는 스킵
                
                // MainActor에서 실행되지 않으므로 직접 계산
                let totalMonths = currentYear * 12 + currentMonth - 1 + offset
                let year = totalMonths / 12
                let month = totalMonths % 12 + 1
                
                await self.smartLoader.prefetchMonth(year: year, month: month, priority: .low)
            }
        }
    }
    
    /// 년/월 계산 헬퍼
    private func calculateYearMonth(_ year: Int, _ month: Int, offset: Int) -> (Int, Int) {
        let totalMonths = year * 12 + month - 1 + offset
        let newYear = totalMonths / 12
        let newMonth = totalMonths % 12 + 1
        return (newYear, newMonth)
    }
    
    /// 특정 월로 이동
    func moveToMonth(year: Int, month: Int) {
        handle(.moveToMonth(year: year, month: month))
    }
    
    /// 이전 달로 이동 (기본 구현 - PagedTabView에서 주로 처리)
    func moveToPreviousMonth() {
        handle(.moveToPreviousMonth)
    }
    
    /// 다음 달로 이동 (기본 구현 - PagedTabView에서 주로 처리)
    func moveToNextMonth() {
        handle(.moveToNextMonth)
    }
    
    /// 날짜 선택
    func selectDate(_ date: Date) {
        handle(.selectDate(date))
    }
    
    /// 새로고침 (점진적 업데이트 사용)
    func refresh() {
        refresh(force: false)
    }
    
    /// 새로고침 (force 옵션으로 완전 재로드 가능)
    func refresh(force: Bool) {
        if force {
            // 강제 새로고침: 전체 윈도우 재로드
            loadMonthWindow()
            return
        }
        // 기존 데이터를 유지하면서 백그라운드에서 새 데이터 로드
        progressiveUpdateManager.startProgressiveUpdate(
            for: state.currentYear,
            month: state.currentMonth
        ) { [weak self] updatedMonth in
            guard let self = self, let month = updatedMonth else { return }
            
            // 새 데이터로 업데이트
            self.state.currentMonthData = month
            self.state.setCachedMonth(month)
            
            // 주변 월들도 백그라운드에서 업데이트
            self.progressiveUpdateManager.prepareBackgroundData(
                centerYear: self.state.currentYear,
                centerMonth: self.state.currentMonth,
                range: 2
            )
        }
    }
    
    
    /// 오늘로 이동
    func moveToToday() {
        state.moveToToday()
        loadMonthWindow()
    }
    
    // MARK: - PagedTabView 관련 메서드
    
    /// 페이지 변경 처리
    func handlePageChange(to index: Int) {
        guard index >= 0 && index < monthWindow.count else { return }
        
        currentWindowIndex = index
        let selectedMonth = monthWindow[index]
        
        // 상태 업데이트
        state.currentYear = selectedMonth.year
        state.currentMonth = selectedMonth.month
        state.currentMonthData = selectedMonth
        isDataReady = true
        
        // 경계에 도달하면 새로운 윈도우 로드 (더 보수적인 경계 설정)
        // 이미 로딩 중이면 중복 로드 방지
        if !isLoadingNewWindow {
            // 첫 번째 인덱스나 마지막 인덱스에 도달했을 때만 로드
            if index == 0 {
                loadNewWindow(direction: .previous)
            } else if index == monthWindow.count - 1 {
                loadNewWindow(direction: .next)
            }
        }
    }
    
    /// 헤더 버튼용 직접 이전 달 이동
    func moveToDirectPreviousMonth() {
        if currentWindowIndex > 0 {
            currentWindowIndex -= 1
            handlePageChange(to: currentWindowIndex)
        } else {
            state.moveToPreviousMonth()
            loadMonthWindow()
        }
    }
    
    /// 헤더 버튼용 직접 다음 달 이동
    func moveToDirectNextMonth() {
        if currentWindowIndex < monthWindow.count - 1 {
            currentWindowIndex += 1
            handlePageChange(to: currentWindowIndex)
        } else {
            state.moveToNextMonth()
            loadMonthWindow()
        }
    }
    
    /// 강제 새로고침 (주 시작일 변경 등 전체 구조 변경 시 사용)
    func forceRefresh() {
        print("🔄 CalendarViewModel: forceRefresh() 호출됨")
        
        // 현재 상태 즉시 무효화
        state.currentMonthData = nil
        monthWindow.removeAll()
        isDataReady = false
        
        // 전체 달력 구조가 바뀔 수 있는 변경사항(주 시작일 등)에 대해서는 완전한 리로드 실행
        loadMonthWindow()
        
        // 강제로 UI 업데이트 트리거
        objectWillChange.send()
        
        print("🔄 CalendarViewModel: forceRefresh() 완료")
    }
    
    /// 낙관적 이벤트 추가 업데이트
    func optimisticallyAddEvent(_ event: Event) {
        let affectedDates = selectiveUpdateManager.getAffectedDates(for: event)
        
        // UI에 즉시 반영
        updateMonthWindowWithNewEvent(event, affectedDates: affectedDates)
        
        // 백그라운드에서 실제 데이터와 동기화
        selectiveUpdateManager.scheduleEventAddUpdate(event: event, affectedDate: affectedDates.first ?? Date())
    }
    
    /// 낙관적 이벤트 수정 업데이트
    func optimisticallyUpdateEvent(_ event: Event, originalDates: [Date]) {
        let newAffectedDates = selectiveUpdateManager.getAffectedDates(for: event)
        let allAffectedDates = Set(originalDates + newAffectedDates)
        
        // UI에 즉시 반영
        updateMonthWindowWithUpdatedEvent(event, affectedDates: Array(allAffectedDates))
        
        // 백그라운드에서 실제 데이터와 동기화
        for date in allAffectedDates {
            selectiveUpdateManager.scheduleEventEditUpdate(event: event, affectedDate: date)
        }
    }
    
    /// 낙관적 이벤트 삭제 업데이트
    func optimisticallyDeleteEvent(eventId: String, affectedDates: [Date]) {
        // UI에서 즉시 제거
        removeEventFromMonthWindow(eventId: eventId, affectedDates: affectedDates)
        
        // 백그라운드에서 실제 데이터와 동기화
        for date in affectedDates {
            selectiveUpdateManager.scheduleEventDeleteUpdate(eventId: eventId, affectedDate: date)
        }
    }
    
    /// 낙관적 할일 추가 업데이트
    func optimisticallyAddReminder(_ reminder: Reminder) {
        let affectedDate = selectiveUpdateManager.getAffectedDate(for: reminder)
        
        // UI에 즉시 반영
        if let date = affectedDate {
            updateMonthWindowWithNewReminder(reminder, affectedDate: date)
        }
        
        // 백그라운드에서 실제 데이터와 동기화
        selectiveUpdateManager.scheduleReminderAddUpdate(reminder: reminder, affectedDate: affectedDate)
    }
    
    /// 특정 날짜의 데이터가 준비되었는지 확인
    func isDateDataReady(for date: Date) -> Bool {
        guard isCurrentMonthDataReady else { return false }
        
        // 7개월 윈도우에서 해당 날짜 확인
        for monthData in monthWindow {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month], from: date)
            if dateComponents.year == monthData.year &&
               dateComponents.month == monthData.month {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Public Update Methods
    
    /// 통합 캘린더 데이터 업데이트 핸들러
    func handleCalendarDataUpdate(_ updatedMonths: [CalendarMonth]) {
        for updatedMonth in updatedMonths {
            // monthWindow에서 해당하는 월을 찾아서 교체
            if let windowIndex = monthWindow.firstIndex(where: { 
                $0.year == updatedMonth.year && $0.month == updatedMonth.month 
            }) {
                monthWindow[windowIndex] = updatedMonth
                
                // 현재 월인 경우 currentWindowIndex도 업데이트
                if updatedMonth.year == state.currentYear && updatedMonth.month == state.currentMonth {
                    currentWindowIndex = windowIndex
                    state.currentMonthData = updatedMonth
                }
            }
        }
        
        // UI 강제 새로고침
        objectWillChange.send()
    }
    
    // MARK: - Private Methods
    
    private func bindEventKitChanges() {
        eventKitService.changePublisher
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main) // 디바운싱 시간 단축
            .sink { [weak self] in
                guard let self = self else { return }
                
                // 모든 EventKit 변경도 SelectiveUpdateManager를 통해 처리
                let currentDate = self.state.currentMonthFirstDay
                let calendar = Calendar.current
                
                let affectedDates = (-1...1).compactMap { offset in
                    calendar.date(byAdding: .month, value: offset, to: currentDate)
                }
                
                self.selectiveUpdateManager.scheduleDateRangeUpdate(dates: affectedDates)
                
                // 위젯 새로고침
                WidgetRefreshService.shared.refreshWithDebounce()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Action Handler
    private func handle(_ action: CalendarAction) {
        switch action {
        case .moveToMonth(let year, let month):
            isDataReady = false
            state.moveToMonth(year: year, month: month)
            loadMonthWindow()
            
        case .moveToPreviousMonth:
            isDataReady = false
            state.moveToPreviousMonth()
            loadMonthWindow()
            
        case .moveToNextMonth:
            isDataReady = false
            state.moveToNextMonth()
            loadMonthWindow()
            
        case .refresh:
            isDataReady = false
            clearCurrentMonthCache()
            loadMonthWindow()
            
        case .loadCurrentMonth:
            loadMonthWindow()
            
        case .selectDate(let date):
            state.selectDate(date)
            if !state.isSelectedDateInCurrentMonth {
                // 선택된 날짜가 현재 월이 아니면 해당 월로 이동
                let components = Calendar.current.dateComponents([.year, .month], from: date)
                if let year = components.year, let month = components.month {
                    moveToMonth(year: year, month: month)
                }
            }
            
        case .changeViewMode(let mode):
            state.viewMode = mode
            
        case .clearError:
            state.error = nil
        }
    }
    
    // MARK: - 7개월 윈도우 로딩
    private func loadMonthWindow() {
        loadTask?.cancel()
        
        isDataReady = false
        
        loadTask = Task {
            state.isLoading = true
            state.error = nil
            
            let centerDate = state.currentMonthFirstDay
            let result = await fetchWindow(centerMonth: centerDate)
            
            guard !Task.isCancelled else { return }
            
            switch result {
            case .success(let months):
                monthWindow = months
                currentWindowIndex = 3 // 중간이 현재 월
                
                // 현재 월 데이터도 업데이트 (중간이 현재 월)
                if months.count >= 4 {
                    let currentMonth = months[3]
                    state.currentMonthData = currentMonth
                    state.setCachedMonth(currentMonth)
                    
                    // 상태도 업데이트
                    state.currentYear = currentMonth.year
                    state.currentMonth = currentMonth.month
                }
                
                // 모든 월을 캐시에 저장
                for month in months {
                    state.setCachedMonth(month)
                }
                
                state.error = nil
                hasInitialDataLoaded = true
                isDataReady = true
                
                // 인접 월 미리 로딩 시작
                startPreloadAdjacentMonths()
                
            case .failure(let error):
                state.error = error
                isDataReady = false
            }
            
            state.isLoading = false
        }
    }
    
    // MARK: - 윈도우 방향
    private enum WindowDirection {
        case previous, next
    }
    
    private func loadNewWindow(direction: WindowDirection) {
        // 이미 로딩 중이면 중복 방지
        guard !isLoadingNewWindow else { return }
        
        // 현재 진행 중인 작업 취소
        windowLoadTask?.cancel()
        
        windowLoadTask = Task {
            // 로딩 플래그 설정
            await MainActor.run {
                isLoadingNewWindow = true
            }
            
            let newCenterDate: Date
            
            switch direction {
            case .previous:
                // 현재 이전 달을 새로운 중심으로
                newCenterDate = monthWindow[0].firstDay
            case .next:
                // 현재 가장 이후 달을 새로운 중심으로
                newCenterDate = monthWindow[6].firstDay
            }
            
            let result = await fetchWindow(centerMonth: newCenterDate)
            
            // 작업이 취소되었는지 확인
            guard !Task.isCancelled else { 
                await MainActor.run {
                    isLoadingNewWindow = false
                }
                return 
            }
            
            switch result {
            case .success(let newMonths):
                await MainActor.run {
                    // 안전한 상태 업데이트
                    guard !Task.isCancelled else {
                        isLoadingNewWindow = false
                        return
                    }
                    
                    monthWindow = newMonths
                    currentWindowIndex = 3 // 다시 중간으로
                    
                    // 캐시 업데이트
                    for month in newMonths {
                        state.setCachedMonth(month)
                    }
                    
                    // 현재 월 업데이트
                    if newMonths.count >= 4 {
                        let currentMonth = newMonths[3]
                        state.currentYear = currentMonth.year
                        state.currentMonth = currentMonth.month
                        state.currentMonthData = currentMonth
                    }
                    
                    isLoadingNewWindow = false
                }
            case .failure:
                await MainActor.run {
                    isLoadingNewWindow = false
                }
            }
        }
    }
    
    // MARK: - Preloading
    private func startPreloadAdjacentMonths() {
        preloadTask?.cancel()
        
        preloadTask = Task {
            // 약간의 지연 후 미리 로딩 (UI 응답성 우선)
            try? await Task.sleep(for: .milliseconds(500))
            
            guard !Task.isCancelled else { return }
            
            let (prevYear, prevMonth) = state.previousMonthInfo
            let (nextYear, nextMonth) = state.nextMonthInfo
            
            // 캐시되지 않은 월들만 로딩
            await withTaskGroup(of: Void.self) { group in
                // 이전 달
                if state.getCachedMonth(year: prevYear, month: prevMonth) == nil {
                    group.addTask {
                        let result = await self.fetchMonth(year: prevYear, month: prevMonth)
                        if case .success(let monthData) = result {
                            await MainActor.run {
                                self.state.setCachedMonth(monthData)
                            }
                        }
                    }
                }
                
                // 다음 달
                if state.getCachedMonth(year: nextYear, month: nextMonth) == nil {
                    group.addTask {
                        let result = await self.fetchMonth(year: nextYear, month: nextMonth)
                        if case .success(let monthData) = result {
                            await MainActor.run {
                                self.state.setCachedMonth(monthData)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Cache Management
    private func clearCurrentMonthCache() {
        let key = state.currentCacheKey
        CalendarCacheManager.shared.removeCachedMonth(for: key)
    }
    
    private func clearOldCache() {
        state.clearOldCache()
    }
    
    // MARK: - Optimistic UI Update Helpers
    
    /// 새 이벤트를 monthWindow에 즉시 추가
    private func updateMonthWindowWithNewEvent(_ event: Event, affectedDates: [Date]) {
        withAnimation(.easeInOut(duration: 0.2)) {
            for (index, month) in monthWindow.enumerated() {
                let monthDate = Calendar.current.date(from: DateComponents(year: month.year, month: month.month, day: 1))
                
                if let monthDate = monthDate,
                   affectedDates.contains(where: { Calendar.current.isDate($0, equalTo: monthDate, toGranularity: .month) }) {
                    
                    // 해당 월의 일정에 새 이벤트 추가
                    let updatedMonth = addEventToMonth(month, event: event, affectedDates: affectedDates)
                    monthWindow[index] = updatedMonth
                    
                    // 현재 월이라면 state도 업데이트
                    if month.year == state.currentYear && month.month == state.currentMonth {
                        state.currentMonthData = updatedMonth
                    }
                }
            }
        }
    }
    
    /// 수정된 이벤트를 monthWindow에 즉시 반영
    private func updateMonthWindowWithUpdatedEvent(_ event: Event, affectedDates: [Date]) {
        withAnimation(.easeInOut(duration: 0.2)) {
            for (index, month) in monthWindow.enumerated() {
                let monthDate = Calendar.current.date(from: DateComponents(year: month.year, month: month.month, day: 1))
                
                if let monthDate = monthDate,
                   affectedDates.contains(where: { Calendar.current.isDate($0, equalTo: monthDate, toGranularity: .month) }) {
                    
                    // 해당 월에서 기존 이벤트 제거 후 새 이벤트 추가
                    let updatedMonth = updateEventInMonth(month, event: event, affectedDates: affectedDates)
                    monthWindow[index] = updatedMonth
                    
                    // 현재 월이라면 state도 업데이트
                    if month.year == state.currentYear && month.month == state.currentMonth {
                        state.currentMonthData = updatedMonth
                    }
                }
            }
        }
    }
    
    /// 이벤트를 monthWindow에서 즉시 제거
    private func removeEventFromMonthWindow(eventId: String, affectedDates: [Date]) {
        withAnimation(.easeInOut(duration: 0.2)) {
            for (index, month) in monthWindow.enumerated() {
                let monthDate = Calendar.current.date(from: DateComponents(year: month.year, month: month.month, day: 1))
                
                if let monthDate = monthDate,
                   affectedDates.contains(where: { Calendar.current.isDate($0, equalTo: monthDate, toGranularity: .month) }) {
                    
                    // 해당 월에서 이벤트 제거
                    let updatedMonth = removeEventFromMonth(month, eventId: eventId)
                    monthWindow[index] = updatedMonth
                    
                    // 현재 월이라면 state도 업데이트
                    if month.year == state.currentYear && month.month == state.currentMonth {
                        state.currentMonthData = updatedMonth
                    }
                }
            }
        }
    }
    
    /// 새 할일을 monthWindow에 즉시 추가
    private func updateMonthWindowWithNewReminder(_ reminder: Reminder, affectedDate: Date) {
        withAnimation(.easeInOut(duration: 0.2)) {
            for (index, month) in monthWindow.enumerated() {
                if Calendar.current.isDate(affectedDate, equalTo: Calendar.current.date(from: DateComponents(year: month.year, month: month.month, day: 1))!, toGranularity: .month) {
                    
                    // 해당 월의 할일에 새 할일 추가
                    let updatedMonth = addReminderToMonth(month, reminder: reminder, affectedDate: affectedDate)
                    monthWindow[index] = updatedMonth
                    
                    // 현재 월이라면 state도 업데이트
                    if month.year == state.currentYear && month.month == state.currentMonth {
                        state.currentMonthData = updatedMonth
                    }
                    break
                }
            }
        }
    }
    
    // MARK: - Data Manipulation Helpers
    
    /// 월에 새 이벤트 추가 (간단한 구현)
    private func addEventToMonth(_ month: CalendarMonth, event: Event, affectedDates: [Date]) -> CalendarMonth {
        // 실제로는 더 복잡한 로직이 필요하지만, 간단한 구현
        // 백그라운드 동기화에서 정확한 데이터가 로드될 예정
        return month
    }
    
    /// 월에서 이벤트 업데이트 (간단한 구현)
    private func updateEventInMonth(_ month: CalendarMonth, event: Event, affectedDates: [Date]) -> CalendarMonth {
        // 실제로는 더 복잡한 로직이 필요하지만, 간단한 구현
        // 백그라운드 동기화에서 정확한 데이터가 로드될 예정
        return month
    }
    
    /// 월에서 이벤트 제거 (간단한 구현)
    private func removeEventFromMonth(_ month: CalendarMonth, eventId: String) -> CalendarMonth {
        // 실제로는 더 복잡한 로직이 필요하지만, 간단한 구현
        // 백그라운드 동기화에서 정확한 데이터가 로드될 예정
        return month
    }
    
    /// 월에 새 할일 추가 (간단한 구현)
    private func addReminderToMonth(_ month: CalendarMonth, reminder: Reminder, affectedDate: Date) -> CalendarMonth {
        // 실제로는 더 복잡한 로직이 필요하지만, 간단한 구현
        // 백그라운드 동기화에서 정확한 데이터가 로드될 예정
        return month
    }
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default
            .publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.clearOldCache()
            }
            .store(in: &cancellables)
    }
    
    private func setupSelectiveUpdateObserver() {
        NotificationCenter.default
            .publisher(for: .calendarDataUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self,
                      let updatedMonths = notification.userInfo?["updatedMonths"] as? [CalendarMonth] else { return }
                
                self.handleSelectiveDataUpdate(updatedMonths: updatedMonths)
            }
            .store(in: &cancellables)
    }
    
    private func setupCalendarRefreshObserver() {
        NotificationCenter.default
            .publisher(for: .calendarNeedsRefresh)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.forceRefresh()
            }
            .store(in: &cancellables)
    }
    
    private func handleSelectiveDataUpdate(updatedMonths: [CalendarMonth]) {
        withAnimation(.easeInOut(duration: 0.15)) {
            // monthWindow에서 업데이트된 월들을 교체
            for updatedMonth in updatedMonths {
                if let index = monthWindow.firstIndex(where: { 
                    $0.year == updatedMonth.year && $0.month == updatedMonth.month 
                }) {
                    monthWindow[index] = updatedMonth
                    
                    // 현재 표시중인 월이라면 currentMonthData도 업데이트
                    if updatedMonth.year == state.currentYear && updatedMonth.month == state.currentMonth {
                        state.currentMonthData = updatedMonth
                        state.setCachedMonth(updatedMonth)
                    }
                }
            }
        }
    }
    
    // MARK: - Date Utilities
    
    /// 특정 날짜의 CalendarDay 조회
    func getCalendarDay(for date: Date) -> CalendarDay? {
        // 먼저 현재 월에서 찾기
        if let day = state.currentMonthData?.day(for: date) {
            return day
        }
        
        // 7개월 윈도우에서 찾기
        for monthData in monthWindow {
            if let day = monthData.day(for: date) {
                return day
            }
        }
        
        return nil
    }
    
    /// 현재 월의 모든 날짜 (6주 그리드)
    var calendarDates: [Date] {
        return state.currentMonthData?.calendarDates ?? []
    }
    
    /// 월 표시 텍스트
    var monthDisplayText: String {
        return state.monthDisplayText
    }
    
    /// 날짜 선택 가능 여부 확인
    func canSelectDate(_ date: Date) -> Bool {
        return true
    }
    
    /// 특정 날짜가 선택된 날짜인지
    func isDateSelected(_ date: Date) -> Bool {
        return state.isDateSelected(date)
    }
    
    /// 특정 날짜가 오늘인지
    func isDateToday(_ date: Date) -> Bool {
        return state.isDateToday(date)
    }
    
    /// 특정 날짜가 현재 월인지
    func isDateInCurrentMonth(_ date: Date) -> Bool {
        return state.isDateInCurrentMonth(date)
    }
    
    // MARK: - Quick Actions
    
    /// 특정 날짜에 빠른 이벤트 추가
    func addQuickEvent(on date: Date, title: String) async {
        let input = EventInput(
            title: title,
            start: date,
            end: Calendar.current.date(byAdding: .hour, value: 1, to: date) ?? date,
            location: nil,
            notes: nil,
            url: nil,
            alarms: [],
            recurrenceRule: nil,
            calendarId: nil
        )
        
        let result = await addEvent(input)
        if case .success = result {
            refresh()
        }
    }
    
    /// 특정 날짜에 빠른 할일 추가
    func addQuickReminder(on date: Date, title: String) async {
        let input = ReminderInput(
            title: title,
            due: date,
            includesTime: false,
            priority: 0,
            notes: nil,
            url: nil,
            location: nil,
            alarms: [],
            calendarId: nil,
            reminderType: .onDate,
            alarmPreset: nil
        )
        
        let result = await addReminder(input)
        if case .success = result {
            refresh()
        }
    }
}

// MARK: - Debug & Testing Helpers
#if DEBUG
extension CalendarViewModel {
    
    /// 디버그용 상태 출력
    func printCurrentState() {
        print("=== Calendar State ===")
        print("Current Month: \(state.currentYear)/\(state.currentMonth)")
        print("Selected Date: \(selectedDate?.description ?? "nil")")
        print("Is Loading: \(isLoading)")
        print("Error: \(error?.description ?? "nil")")
        let cacheStats = CalendarCacheManager.shared.cacheStatistics
        print("Cached Months: \(cacheStats.monthCount), Display Items: \(cacheStats.displayItemsCount), Memory: \(cacheStats.memoryEstimate)")
        print("Month Window: \(monthWindow.map { "\($0.year)/\($0.month)" })")
        print("Current Window Index: \(currentWindowIndex)")
        print("Is Data Ready: \(isDataReady)")
        print("=====================")
    }
    
    /// 테스트용 더미 데이터 로드
    func loadDummyData() {
        let dummyMonths = (-3...3).map { offset -> CalendarMonth in
                    var comps = DateComponents()
                    comps.month = offset
                    let date = Calendar.current.date(byAdding: comps, to: state.currentMonthFirstDay)!
                    let year = Calendar.current.component(.year, from: date)
                    let month = Calendar.current.component(.month, from: date)
                    return CalendarMonth(year: year, month: month, days: [])
                }
        
        monthWindow = dummyMonths
        currentWindowIndex = 3
        state.currentMonthData = dummyMonths[3]
        
        for month in dummyMonths {
            state.setCachedMonth(month)
        }
        
        isDataReady = true
    }
}
#endif
