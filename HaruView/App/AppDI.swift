//
//  AppDI.swift
//  HaruView
//
//  Created by 김효석 on 5/2/25.
//

import Foundation
import SwiftUI
import EventKit


final class DIContainer {
    static let shared = DIContainer()
    private init() {}
    
    lazy var eventKitService = EventKitService()
    private lazy var eventKitRepository = EventKitRepository(service: eventKitService)
    
    // TODO:
    private lazy var weatherRepository = MockWeatherRepository()

    
    // MARK: - 권한 요청
    @MainActor
    func bootstrapPermissions() async {
        switch await eventKitService.requestAccess(.writeOnly) {
        case .success: break
        case .failure(_): return
        }
        
        switch await eventKitService.requestAccess(.full) {
        case .success: break
        case .failure(_): return
        }
    }
    
    // MARK: - Use Cases
    func makeFetchTodayOverViewUseCase() -> FetchTodayOverviewUseCase {
        FetchTodayOverviewUseCase(events: eventKitRepository,
                                  reminders: eventKitRepository,
                                  weather: weatherRepository)
    }
    
    func makeAddEventUseCase() -> AddEventUseCase {
        AddEventUseCase(repo: eventKitRepository)
    }
    
    func makeAddReminderUseCase() -> AddReminderUseCase {
        AddReminderUseCase(repo: eventKitRepository)
    }
    
    func makeDeleteEventUseCase() -> DeleteObjectUseCase {
        DeleteObjectUseCase(events: eventKitRepository,
                            reminders: eventKitRepository)
    }
    
    func makeToggleReminderUseCase() -> ToggleReminderUseCase {
        ToggleReminderUseCase(repo: eventKitRepository)
    }
    
    // MARK: - ViewModels
    @MainActor
    func makeHomeVM() -> HomeViewModel {
        HomeViewModel(fetchToday: makeFetchTodayOverViewUseCase(),
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

    func makeDetailVM(for item: DetailItem) -> DetailSheetViewModel {
        DetailSheetViewModel(item: item,
                             deleteObject: DeleteObjectUseCase(events: eventKitRepository, reminders: eventKitRepository),
                             reminderRepository: eventKitRepository)
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
    func fetchWeather() async -> Result<Weather, TodayBoardError> {
        .success(Weather(temperature: .init(value: 23, unit: .celsius),
                         condition: .clear,
                         updatedAt: .now))
    }
}
