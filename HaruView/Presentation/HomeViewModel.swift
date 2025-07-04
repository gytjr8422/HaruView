//
//  HomeViewModel.swift
//  HaruView
//
//  Created by 김효석 on 5/1/25.
//

import SwiftUI
import Combine
import CoreLocation
import WidgetKit

// 프로토콜 수정
protocol HomeViewModelProtocol: ObservableObject {
    var state: HomeState { get }
    var today: Date { get }
    var weather: TodayWeather? { get }
    var weatherError: TodayBoardError? { get }
    var showRecurringDeletionOptions: Bool { get set }
    var currentDeletingEvent: Event? { get }
    var isDeletingEvent: Bool { get }
    var deletionError: TodayBoardError? { get set }
    
    func load()
    func refresh(_ kind: RefreshKind)
    func toggleReminder(id: String) async
    func deleteObject(_ kind: DeleteObjectUseCase.ObjectKind) async
    func requestEventDeletion(_ event: Event)
    func deleteEventWithSpan(_ span: EventDeletionSpan)
    func cancelEventDeletion()
}

enum RefreshKind {
    case userTap, storeChange
}


@MainActor
final class HomeViewModel: ObservableObject, @preconcurrency HomeViewModelProtocol {

    // MARK: - Published State
    @Published private(set) var state = HomeState()
    @Published private(set) var today = Date()
    @Published var weather: TodayWeather?
    @Published var weatherError: TodayBoardError?
    
    @Published var showRecurringDeletionOptions: Bool = false
    @Published var currentDeletingEvent: Event?
    @Published var isDeletingEvent: Bool = false
    @Published var deletionError: TodayBoardError?

    // MARK: - DI
    private let fetchData:    FetchTodayOverviewUseCase
    private let fetchWeather: FetchTodayWeatherUseCase
    private let deleteObjectUseCase: DeleteObjectUseCase
    private let reminderRepo: ReminderRepositoryProtocol
    private let service:      EventKitService

    // MARK: - Tasks & Combine
    private var dataTask:    Task<Void,Never>?
    private var weatherTask: Task<Void,Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(fetchData: FetchTodayOverviewUseCase,
         fetchWeather: FetchTodayWeatherUseCase,
         deleteObject: DeleteObjectUseCase,
         reminderRepo: ReminderRepositoryProtocol,
         service: EventKitService) {

        self.fetchData = fetchData
        self.fetchWeather = fetchWeather
        self.deleteObjectUseCase = deleteObject
        self.reminderRepo = reminderRepo
        self.service = service

        startDateWatcher()
        bindStoreChange()
        bindLocationStatus()
    }

    // MARK: - Load
    func load() {
        loadOverview()
        loadWeather()
    }

    func refresh(_ kind: RefreshKind = .userTap) {
        loadOverview()
        loadWeather()
        WidgetRefreshService.shared.forceRefresh()
    }

    // MARK: - 삭제 관련 메서드 (새로운 메서드로 기존 것 대체)
    
    /// 이벤트 삭제 요청 (스마트 삭제)
    func requestEventDeletion(_ event: Event) {
        currentDeletingEvent = event
        
        if event.hasRecurrence {
            // 반복 일정이면 옵션 선택 표시
            showRecurringDeletionOptions = true
        } else {
            // 일반 일정이면 바로 삭제
            Task {
                await deleteEvent(event.id, span: .thisEventOnly)
            }
        }
    }
    
    /// 선택된 범위로 이벤트 삭제
    func deleteEventWithSpan(_ span: EventDeletionSpan) {
        guard let event = currentDeletingEvent else { return }
        
        showRecurringDeletionOptions = false
        
        Task {
            await deleteEvent(event.id, span: span)
        }
    }
    
    /// 삭제 취소
    func cancelEventDeletion() {
        showRecurringDeletionOptions = false
        currentDeletingEvent = nil
    }
    
    /// 실제 삭제 실행
    private func deleteEvent(_ id: String, span: EventDeletionSpan) async {
        isDeletingEvent = true
        deletionError = nil
        
        let result = await deleteObjectUseCase(.eventWithSpan(id, span))
        
        await MainActor.run {
            isDeletingEvent = false
            
            switch result {
            case .success:
                currentDeletingEvent = nil
                refresh(.storeChange)
            case .failure(let error):
                deletionError = error
            }
        }
    }
    
    /// 일반 삭제 (기존 호환성 유지)
    func deleteObject(_ kind: DeleteObjectUseCase.ObjectKind) async {
        let result = await deleteObjectUseCase(kind)
        if case .success = result {
            WidgetRefreshService.shared.refreshWithDebounce()
            await MainActor.run {
                self.refresh(.storeChange)
            }
        }
    }

    // MARK: - Reminder Toggle (기존 유지)
    func toggleReminder(id: String) async {
        let res = await reminderRepo.toggle(id: id)
        switch res {
        case .success:
            if let idx = state.overview.reminders.firstIndex(where: { $0.id == id }) {
                let original = state.overview.reminders[idx]
                let updated = Reminder(
                    id: original.id,
                    title: original.title,
                    due: original.due,
                    isCompleted: !original.isCompleted,
                    priority: original.priority,
                    notes: original.notes,
                    url: original.url,
                    location: original.location,
                    hasAlarms: original.hasAlarms,
                    alarms: original.alarms,
                    calendar: original.calendar
                )
                
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    state.overview.reminders[idx] = updated
                    state.overview.reminders.sort(by: reminderSortRule)
                }
            }
            WidgetRefreshService.shared.refreshWithDebounce()
        case .failure(let error):
            state.error = error
        }
    }

    // MARK: - Private Methods (기존 유지)
    private func loadOverview() {
        dataTask?.cancel()
        dataTask = Task {
            state.isLoading = true
            defer { state.isLoading = false }

            switch await fetchData() {
            case .success(let ov): state.overview = ov
            case .failure(let err): state.error  = err
            }
        }
    }

    func loadWeather() {
        weatherTask?.cancel()
        weatherTask = Task {
            switch await fetchWeather() {
            case .success(let tw):
                await MainActor.run {
                    weather = tw
                    weatherError = nil
                }
            case .failure(let err):
                await MainActor.run { weatherError = err }
            }
        }
    }

    private func bindLocationStatus() {
        LocationProvider.shared.$status
            .removeDuplicates()
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .authorizedAlways, .authorizedWhenInUse,
                     .denied, .restricted:
                    self.loadWeather()
                default: break
                }
            }
            .store(in: &cancellables)
    }

    private func startDateWatcher() {
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if !Calendar.current.isDate(Date(), inSameDayAs: today) {
                    today = Date(); refresh(.storeChange)
                }
            }
            .store(in: &cancellables)
    }

    private func bindStoreChange() {
        service.changePublisher
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.refresh(.storeChange)
                WidgetRefreshService.shared.refreshWithDebounce()
            }
            .store(in: &cancellables)
    }
    
    private func reminderSortRule(_ a: Reminder, _ b: Reminder) -> Bool {
        if a.isCompleted != b.isCompleted { return !a.isCompleted }
        let da = a.due ?? .distantFuture, db = b.due ?? .distantFuture
        return da != db ? da < db : a.title < b.title
    }
}
