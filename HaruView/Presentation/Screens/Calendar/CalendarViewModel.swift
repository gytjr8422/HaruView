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
    
    func loadCurrentMonth()
    func moveToMonth(year: Int, month: Int)
    func moveToPreviousMonth()
    func moveToNextMonth()
    func selectDate(_ date: Date)
    func refresh()
    func moveToToday()
}

// MARK: - CalendarViewModel Implementation
@MainActor
final class CalendarViewModel: ObservableObject, @preconcurrency CalendarViewModelProtocol {
    
    // MARK: - Published State
    @Published private(set) var state = CalendarState()
    @Published private(set) var hasInitialDataLoaded = false // 초기 데이터 로딩 완료 여부
    
    // MARK: - Computed Properties
    var currentMonthData: CalendarMonth? { state.currentMonthData }
    var isLoading: Bool { state.isLoading }
    var error: TodayBoardError? { state.error }
    var selectedDate: Date? { state.selectedDate }
    
    // MARK: - Use Cases
    private let fetchMonth: FetchCalendarMonthUseCase
    private let fetchDay: FetchCalendarDayUseCase
    private let fetchWindow: FetchCalendarWindowUseCase
    private let cacheManager: CalendarCacheUseCase
    private let addEvent: AddEventUseCase
    private let addReminder: AddReminderUseCase
    private let deleteObject: DeleteObjectUseCase
    
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
        deleteObject: DeleteObjectUseCase
    ) {
        self.fetchMonth = fetchMonth
        self.fetchDay = fetchDay
        self.fetchWindow = fetchWindow
        self.cacheManager = cacheManager
        self.addEvent = addEvent
        self.addReminder = addReminder
        self.deleteObject = deleteObject
        
        // 초기 로드
        loadCurrentMonth()
        
        // 메모리 경고 시 캐시 정리
        setupMemoryWarningObserver()
    }
    
    deinit {
        loadTask?.cancel()
        preloadTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// 현재 월 데이터 로드
    func loadCurrentMonth() {
        handle(.loadCurrentMonth)
    }
    
    /// 특정 월로 이동
    func moveToMonth(year: Int, month: Int) {
        handle(.moveToMonth(year: year, month: month))
    }
    
    /// 이전 달로 이동
    func moveToPreviousMonth() {
        handle(.moveToPreviousMonth)
    }
    
    /// 다음 달로 이동
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
        loadCurrentMonth()
    }
    
    // MARK: - Action Handler
    private func handle(_ action: CalendarAction) {
        switch action {
        case .loadCurrentMonth:
            loadMonthData(year: state.currentYear, month: state.currentMonth)
            
        case .moveToMonth(let year, let month):
            state.moveToMonth(year: year, month: month)
            loadMonthData(year: year, month: month)
            
        case .moveToPreviousMonth:
            state.moveToPreviousMonth()
            loadMonthData(year: state.currentYear, month: state.currentMonth)
            
        case .moveToNextMonth:
            state.moveToNextMonth()
            loadMonthData(year: state.currentYear, month: state.currentMonth)
            
        case .selectDate(let date):
            state.selectDate(date)
            // 선택한 날짜가 다른 월이면 해당 월 로드
            if !state.isSelectedDateInCurrentMonth {
                loadMonthData(year: state.currentYear, month: state.currentMonth)
            }
            
        case .refresh:
            clearCurrentMonthCache()
            loadMonthData(year: state.currentYear, month: state.currentMonth, forceReload: true)
            
        case .changeViewMode(let mode):
            state.viewMode = mode
            
        case .clearError:
            state.error = nil
        }
    }
    
    // MARK: - Data Loading
    private func loadMonthData(year: Int, month: Int, forceReload: Bool = false) {
        // 이미 로딩 중이면 취소
        loadTask?.cancel()
        
        // 캐시에서 먼저 확인
        if !forceReload, let cachedMonth = state.getCachedMonth(year: year, month: month) {
            state.currentMonthData = cachedMonth
            state.error = nil
            startPreloadAdjacentMonths()
            return
        }
        
        loadTask = Task {
            state.isLoading = true
            state.error = nil
            
            let result = await fetchMonth(year: year, month: month)
            
            guard !Task.isCancelled else { return }
            
            switch result {
            case .success(let monthData):
                state.currentMonthData = monthData
                state.setCachedMonth(monthData)
                state.error = nil
                hasInitialDataLoaded = true // 데이터 로딩 완료 표시
                
                // 인접 월 미리 로딩 시작
                startPreloadAdjacentMonths()
                
            case .failure(let error):
                state.error = error
                print("Failed to load calendar month: \(error)")
            }
            
            state.isLoading = false
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
        return state.currentMonthData?.day(for: date)
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
        // 과거 제한이 있다면 여기서 처리
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
            // 성공 시 해당 월 새로고침
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
            // 성공 시 해당 월 새로고침
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
        print("Current Month Data: \(currentMonthData != nil ? "Available" : "nil")")
        print("=====================")
    }
    
    /// 테스트용 더미 데이터 로드
    func loadDummyData() {
        let dummyMonth = CalendarMonth(year: state.currentYear, month: state.currentMonth, days: [])
        state.currentMonthData = dummyMonth
        state.setCachedMonth(dummyMonth)
    }
}
#endif
