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
    
    // 3개월 윈도우 관련
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
    
    // 3개월 윈도우 관리
    @Published private(set) var monthWindow: [CalendarMonth] = []
    @Published var currentWindowIndex = 1 // 중간이 현재 월
    
    // MARK: - Computed Properties
    var currentMonthData: CalendarMonth? { state.currentMonthData }
    var isLoading: Bool { state.isLoading }
    var error: TodayBoardError? { state.error }
    var selectedDate: Date? { state.selectedDate }
    
    // 3개월 윈도우 관련 프로퍼티
    var previousMonth: CalendarMonth? {
        monthWindow.indices.contains(0) ? monthWindow[0] : nil
    }
    
    var currentMonth: CalendarMonth? {
        monthWindow.indices.contains(1) ? monthWindow[1] : nil
    }
    
    var nextMonth: CalendarMonth? {
        monthWindow.indices.contains(2) ? monthWindow[2] : nil
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
    
    // MARK: - Tasks & Combine
    private var loadTask: Task<Void, Never>?
    private var preloadTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
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
    }
    
    deinit {
        loadTask?.cancel()
        preloadTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// 현재 월 데이터 로드 (3개월 윈도우)
    func loadCurrentMonth() {
        handle(.loadCurrentMonth)
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
    
    /// 새로고침
    func refresh() {
        handle(.refresh)
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
        
        // 경계에 도달하면 새로운 윈도우 로드
        if index == 0 {
            loadNewWindow(direction: .previous)
        } else if index == monthWindow.count - 1 {
            loadNewWindow(direction: .next)
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
    
    /// 강제 새로고침
    func forceRefresh() {
        // 모든 캐시 삭제
        state.cachedMonths.removeAll()
        monthWindow.removeAll()
        
        // 데이터 준비 상태 리셋
        isDataReady = false
        
        // 강제 리로드
        loadMonthWindow()
    }
    
    /// 특정 날짜의 데이터가 준비되었는지 확인
    func isDateDataReady(for date: Date) -> Bool {
        guard isCurrentMonthDataReady else { return false }
        
        // 3개월 윈도우에서 해당 날짜 확인
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
    
    // MARK: - Private Methods
    
    private func bindEventKitChanges() {
        eventKitService.changePublisher
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] in
                guard let self = self else { return }
                
                // 현재 월 캐시 무효화
                let currentKey = self.state.currentCacheKey
                self.state.cachedMonths.removeValue(forKey: currentKey)
                
                // 윈도우 초기화 후 데이터 새로고침
                self.monthWindow.removeAll()
                self.loadMonthWindow()
                
                // 위젯도 새로고침
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
    
    // MARK: - 3개월 윈도우 로딩
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
                currentWindowIndex = 1 // 중간이 현재 월
                
                // 현재 월 데이터도 업데이트 (중간이 현재 월)
                if months.count >= 2 {
                    let currentMonth = months[1]
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
        Task {
            let newCenterDate: Date
            
            switch direction {
            case .previous:
                // 현재 이전 달을 새로운 중심으로
                newCenterDate = monthWindow[0].firstDay
            case .next:
                // 현재 다음 달을 새로운 중심으로
                newCenterDate = monthWindow[2].firstDay
            }
            
            let result = await fetchWindow(centerMonth: newCenterDate)
            
            guard !Task.isCancelled else { return }
            
            if case .success(let newMonths) = result {
                await MainActor.run {
                    
                    monthWindow = newMonths
                    currentWindowIndex = 1 // 다시 중간으로
                    
                    // 캐시 업데이트
                    for month in newMonths {
                        state.setCachedMonth(month)
                    }
                    
                    // 현재 월 업데이트
                    if newMonths.count >= 2 {
                        let currentMonth = newMonths[1]
                        state.currentYear = currentMonth.year
                        state.currentMonth = currentMonth.month
                        state.currentMonthData = currentMonth
                    }
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
        state.cachedMonths.removeValue(forKey: key)
    }
    
    private func clearOldCache() {
        state.clearOldCache()
    }
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default
            .publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.clearOldCache()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Date Utilities
    
    /// 특정 날짜의 CalendarDay 조회
    func getCalendarDay(for date: Date) -> CalendarDay? {
        // 먼저 현재 월에서 찾기
        if let day = state.currentMonthData?.day(for: date) {
            return day
        }
        
        // 3개월 윈도우에서 찾기
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
            calendarId: nil
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
        print("Cached Months: \(state.cachedMonths.keys.sorted())")
        print("Month Window: \(monthWindow.map { "\($0.year)/\($0.month)" })")
        print("Current Window Index: \(currentWindowIndex)")
        print("Is Data Ready: \(isDataReady)")
        print("=====================")
    }
    
    /// 테스트용 더미 데이터 로드
    func loadDummyData() {
        let dummyMonths = [
            CalendarMonth(year: state.currentYear, month: state.currentMonth == 1 ? 12 : state.currentMonth - 1, days: []),
            CalendarMonth(year: state.currentYear, month: state.currentMonth, days: []),
            CalendarMonth(year: state.currentYear, month: state.currentMonth == 12 ? 1 : state.currentMonth + 1, days: [])
        ]
        
        monthWindow = dummyMonths
        currentWindowIndex = 1
        state.currentMonthData = dummyMonths[1]
        
        for month in dummyMonths {
            state.setCachedMonth(month)
        }
        
        isDataReady = true
    }
}
#endif
