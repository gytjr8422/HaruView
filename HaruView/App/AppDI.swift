//
//  AppDI.swift
//  HaruView
//
//  Created by 김효석 on 5/2/25.
//

import Foundation
import SwiftUI
import EventKit
import WidgetKit


final class DIContainer {
    static let shared = DIContainer()
    private init() {}
    
    lazy var eventKitService = EventKitService()
    private lazy var eventKitRepository = EventKitRepository(service: eventKitService)
    
    private lazy var weatherRepository: WeatherRepositoryProtocol = {
        WeatherKitRepository(service: WeatherKitService(),
                             locationProvider: { try await LocationProvider.shared.current() })
    }()
    
    
    // MARK: - 권한 요청
    @MainActor
    func bootstrapPermissions() async {
        // 1. 캘린더 writeOnly 권한 요청
        switch await eventKitService.requestAccess(.writeOnly) {
        case .success:
            // 2. 캘린더 full 권한 요청
            switch await eventKitService.requestAccess(.full) {
            case .success:
                // 권한 획득 후 위젯 새로고침
                WidgetRefreshService.shared.refreshWithDebounce()
            case .failure(let error):
                print("Full access request failed: \(error)")
            }
        case .failure(let error):
            print("Write-only access request failed: \(error)")
        }
    }
    
    // MARK: - Use Cases
    func makeFetchTodayOverViewUseCase() -> FetchTodayOverviewUseCase {
        FetchTodayOverviewUseCase(events: eventKitRepository,
                                  reminders: eventKitRepository)
    }
    
    func makeAddEventUseCase() -> AddEventUseCase {
        AddEventUseCase(repo: eventKitRepository)
    }

    func makeEditEventUseCase() -> EditEventUseCase {
        EditEventUseCase(repo: eventKitRepository)
    }
    
    func makeAddReminderUseCase() -> AddReminderUseCase {
        AddReminderUseCase(repo: eventKitRepository)
    }

    func makeEditReminderUseCase() -> EditReminderUseCase {
        EditReminderUseCase(repo: eventKitRepository)
    }
    
    func makeDeleteEventUseCase() -> DeleteObjectUseCase {
        DeleteObjectUseCase(events: eventKitRepository,
                            reminders: eventKitRepository)
    }
    
    func makeToggleReminderUseCase() -> ToggleReminderUseCase {
        ToggleReminderUseCase(repo: eventKitRepository)
    }
    
    func makeFetchTodayWeatherUseCase() -> FetchTodayWeatherUseCase {
        FetchTodayWeatherUseCase(repo: weatherRepository)
    }

    
    // MARK: - ViewModels
    @MainActor
    func makeHomeVM() -> HomeViewModel {
        HomeViewModel(fetchData: makeFetchTodayOverViewUseCase(),
                      fetchWeather: makeFetchTodayWeatherUseCase(),
                      deleteObject: makeDeleteEventUseCase(),
                      reminderRepo: eventKitRepository,
                      service: eventKitService)
    }
    
    @MainActor
    func makeEventListVM() -> EventListViewModel {
        EventListViewModel(fetchToday: makeFetchTodayOverViewUseCase(),
                           deleteObject: makeDeleteEventUseCase())
    }
    
    @MainActor
    func makeReminderListVM() -> ReminderListViewModel {
        ReminderListViewModel(fetchToday: makeFetchTodayOverViewUseCase(),
                              toggleReminder: makeToggleReminderUseCase(),
                              deleteObject: makeDeleteEventUseCase())
    }
    
    @MainActor
    func makeAddSheetVM() -> AddSheetViewModel {
        AddSheetViewModel(addEvent: makeAddEventUseCase(),
                          addReminder: makeAddReminderUseCase())
    }

    @MainActor
    func makeEditSheetVM(event: Event) -> EditSheetViewModel {
        EditSheetViewModel(event: event,
                           editEvent: makeEditEventUseCase(),
                           editReminder: makeEditReminderUseCase())
    }

    @MainActor
    func makeEditSheetVM(reminder: Reminder) -> EditSheetViewModel {
        EditSheetViewModel(reminder: reminder,
                           editEvent: makeEditEventUseCase(),
                           editReminder: makeEditReminderUseCase())
    }
}

private struct DIKey: EnvironmentKey {
    static let defaultValue: DIContainer = .shared
}

extension EnvironmentValues {
    var di: DIContainer {
        get { self[DIKey.self] }
        set { self[DIKey.self] = newValue }
    }
}


// MARK: - Mock WeatherRepository (placeholder)

private struct MockWeatherRepository: WeatherRepositoryProtocol {
    func fetchWeather() async -> Result<TodayWeather, TodayBoardError> {
        .success(TodayWeather(snapshot: WeatherSnapshot(
            temperature: 23.5,           // 섭씨 23.5도
            humidity: 0.65,              // 65% 습도
            precipitation: 0.0,          // 강수량 0mm
            windSpeed: 3.2,              // 초속 3.2m 바람
            condition: .mostlyClear,     // 대체로 맑음
            symbolName: "sun.max",       // SF Symbol 이름
            updatedAt: Date(),
            hourlies: [],
            tempMax: 27,
            tempMin: 17),          // 현재 시간
            placeName: "")
        )
    }
}
