//
//  HomeViewModel.swift
//  HaruView
//
//  Created by 김효석 on 5/1/25.
//

import SwiftUI
import Combine

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
    @Published private(set) var state = HomeState()
    @Published private(set) var today: Date = Date()
    @Published var weather: TodayWeather?
    @Published var weatherError: TodayBoardError?
    
    private var cancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private let fetchData: FetchTodayOverviewUseCase
    private let fetchWeather: FetchTodayWeatherUseCase
    private let deleteObject: DeleteObjectUseCase
    private let reminderRepo: ReminderRepositoryProtocol
    private let service:   EventKitService
    private var task: Task<Void, Never>?
    
    
    init(fetchData: FetchTodayOverviewUseCase, fetchWeather: FetchTodayWeatherUseCase, deleteObject: DeleteObjectUseCase, reminderRepo: ReminderRepositoryProtocol, service: EventKitService) {
        self.fetchData = fetchData
        self.fetchWeather = fetchWeather
        self.deleteObject = deleteObject
        self.reminderRepo = reminderRepo
        self.service = service
        startDateWatcher()
        bindStoreChange()
    }
    
    /// 최초 또는 full reload
    func load() {
        task?.cancel() // 기존 task 취소
        task = Task {
            state.isLoading = true
            defer { state.isLoading = false }
            
            switch await fetchData() {
            case .success(let ov):
                state.overview = ov
            case .failure(let err):
                state.error = err
            }
        }
        loadWeather()
    }
    
    func loadWeather() {
        task?.cancel() // 기존 task 취소
        task = Task {
            switch await fetchWeather() {
            case .success(let tw):
                await MainActor.run { self.weather = tw }
            case .failure(let err):
                await MainActor.run { self.weatherError = err }
            }
        }
    }
    
    /// 시스템 EventKit 변경 등 외부 알림으로 호출
    func refresh(_ kind: RefreshKind = .userTap) {
        Task {
            switch await fetchData() {
            case .success(let ov):
                state.overview = ov
            case .failure(let err):
                state.error = err
            }
        }
    }
    
    /// 날짜 감시 함수
    private func startDateWatcher() {
        cancellable = Timer
            .publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                let now = Date()
                if !Calendar.current.isDate(now, inSameDayAs: self.today) {
                    self.today = now
                    self.refresh()
                }
            }
    }
    
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
    
    /// 데이터 변경 알림 함수
    private func bindStoreChange() {
        service.changePublisher
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main) // 과다 알림 완충
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.refresh(.storeChange) }
            .store(in: &cancellables)
    }
}
