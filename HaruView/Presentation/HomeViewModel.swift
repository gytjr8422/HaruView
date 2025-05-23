//
//  HomeViewModel.swift
//  HaruView
//
//  Created by 김효석 on 5/1/25.
//

import SwiftUI
import Combine
import CoreLocation

protocol HomeViewModelProtocol: ObservableObject {
    var state: HomeState { get }
    var today: Date { get }
    var weather: TodayWeather? { get }
    var weatherError: TodayBoardError? { get }
    func load()
    func refresh(_ kind: RefreshKind)
    func toggleReminder(id: String) async
    func deleteObject(_ kind: DeleteObjectUseCase.ObjectKind) async
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

    // MARK: - DI
    private let fetchData:    FetchTodayOverviewUseCase
    private let fetchWeather: FetchTodayWeatherUseCase
    private let deleteObject: DeleteObjectUseCase
    private let reminderRepo: ReminderRepositoryProtocol
    private let service:      EventKitService

    // MARK: - Tasks & Combine
    private var dataTask:    Task<Void,Never>?
    private var weatherTask: Task<Void,Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(fetchData:    FetchTodayOverviewUseCase,
         fetchWeather: FetchTodayWeatherUseCase,
         deleteObject: DeleteObjectUseCase,
         reminderRepo: ReminderRepositoryProtocol,
         service:      EventKitService) {

        self.fetchData    = fetchData
        self.fetchWeather = fetchWeather
        self.deleteObject = deleteObject
        self.reminderRepo = reminderRepo
        self.service      = service

        startDateWatcher()
        bindStoreChange()
        bindLocationStatus()
    }

    // MARK: - Load
    /// 최초 호출
    func load() {
        loadOverview()
        loadWeather()
    }

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

    /// Pull-to-refresh, ScenePhase 등
    func refresh(_ kind: RefreshKind = .userTap) {
        loadOverview()
        loadWeather()
    }

    // MARK: - Bindings
    private func bindLocationStatus() {
        LocationProvider.shared.$status
            .removeDuplicates()
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .authorizedAlways, .authorizedWhenInUse,
                     .denied, .restricted:
                    self.loadWeather()            // 권한 변할 때마다
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
            .sink { [weak self] in self?.refresh(.storeChange) }
            .store(in: &cancellables)
    }

    // MARK: - Reminder
    func toggleReminder(id: String) async {
        let res = await reminderRepo.toggle(id: id)
        switch res {
        case .success:
            if let idx = state.overview.reminders.firstIndex(where: { $0.id == id }) {
                var updated = state.overview.reminders[idx]
                updated = Reminder(id: updated.id,
                                 title: updated.title,
                                 due: updated.due,
                                 isCompleted: !updated.isCompleted,
                                 priority: updated.priority)
                
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    state.overview.reminders[idx] = updated
                    state.overview.reminders.sort(by: reminderSortRule)
                }
            }
        case .failure(let error):
            state.error = error
        }
    }
    
    func deleteObject(_ kind: DeleteObjectUseCase.ObjectKind) async {
        switch kind {
        case .event(let id):
            let _ = await deleteObject(.event(id))
        case .reminder(let id):
            let _ = await deleteObject(.reminder(id))
        }
    }
    
    private func reminderSortRule(_ a: Reminder, _ b: Reminder) -> Bool {
        if a.isCompleted != b.isCompleted { return !a.isCompleted }       // 미완료 먼저
        let da = a.due ?? .distantFuture, db = b.due ?? .distantFuture
        return da != db ? da < db : a.title < b.title
    }
}
