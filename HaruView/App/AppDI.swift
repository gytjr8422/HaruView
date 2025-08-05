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
        switch await eventKitService.requestAccess(.writeOnly) {
        case .success:
            switch await eventKitService.requestAccess(.full) {
            case .success:
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
    
    // MARK: - AddSheet & EditSheet ViewModels
    @MainActor
    func makeAddSheetVM() -> AddSheetViewModel {
        let availableCalendars = eventKitRepository.getAvailableCalendars()
        let availableReminderCalendars = eventKitRepository.getAvailableReminderCalendars()
        
        return AddSheetViewModel(
            addEvent: makeAddEventUseCase(),
            addReminder: makeAddReminderUseCase(),
            availableCalendars: availableCalendars,
            availableReminderCalendars: availableReminderCalendars
        )
    }

    @MainActor
    func makeEditSheetVM(event: Event) -> EditSheetViewModel {
        let availableCalendars = eventKitRepository.getAvailableCalendars()
        let availableReminderCalendars = eventKitRepository.getAvailableReminderCalendars()
        
        return EditSheetViewModel(
            event: event,
            editEvent: makeEditEventUseCase(),
            editReminder: makeEditReminderUseCase(),
            deleteObject: makeDeleteEventUseCase(),
            availableCalendars: availableCalendars,
            availableReminderCalendars: availableReminderCalendars
        )
    }

    @MainActor
    func makeEditSheetVM(reminder: Reminder) -> EditSheetViewModel {
        let availableCalendars = eventKitRepository.getAvailableCalendars()
        let availableReminderCalendars = eventKitRepository.getAvailableReminderCalendars()
        
        return EditSheetViewModel(
            reminder: reminder,
            editEvent: makeEditEventUseCase(),
            editReminder: makeEditReminderUseCase(),
            deleteObject: makeDeleteEventUseCase(),
            availableCalendars: availableCalendars,
            availableReminderCalendars: availableReminderCalendars
        )
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

// MARK: - 달력 관련
extension DIContainer {
    
    /// 달력 월 데이터 조회 Use Case
    func makeFetchCalendarMonthUseCase() -> FetchCalendarMonthUseCase {
        FetchCalendarMonthUseCase(
            eventRepo: eventKitRepository,
            reminderRepo: eventKitRepository
        )
    }
    
    /// 달력 특정 날짜 상세 조회 Use Case
    func makeFetchCalendarDayUseCase() -> FetchCalendarDayUseCase {
        FetchCalendarDayUseCase(
            eventRepo: eventKitRepository,
            reminderRepo: eventKitRepository
        )
    }
    
    /// 달력 날짜 범위 조회 Use Case
    func makeFetchEventsByDateRangeUseCase() -> FetchEventsByDateRangeUseCase {
        FetchEventsByDateRangeUseCase(
            eventRepo: eventKitRepository,
            reminderRepo: eventKitRepository
        )
    }
    
    /// 달력 7개월 윈도우 조회 Use Case
    func makeFetchCalendarWindowUseCase() -> FetchCalendarWindowUseCase {
        FetchCalendarWindowUseCase(
            eventRepo: eventKitRepository,
            reminderRepo: eventKitRepository
        )
    }
    
    /// 달력 캐시 관리 Use Case
    func makeCalendarCacheUseCase() -> CalendarCacheUseCase {
        CalendarCacheUseCase(eventRepo: eventKitRepository)
    }
    
    /// 달력 ViewModel 생성
    @MainActor
    func makeCalendarViewModel() -> CalendarViewModel {
        CalendarViewModel(
            fetchMonth: makeFetchCalendarMonthUseCase(),
            fetchDay: makeFetchCalendarDayUseCase(),
            fetchWindow: makeFetchCalendarWindowUseCase(),
            cacheManager: makeCalendarCacheUseCase(),
            addEvent: makeAddEventUseCase(),
            addReminder: makeAddReminderUseCase(),
            deleteObject: makeDeleteEventUseCase(),
            eventKitService: eventKitService
        )
    }
    
    
    @MainActor
    func makeAddSheetVMWithDate(_ date: Date) -> AddSheetViewModel {
        let vm = makeAddSheetVM()
        
        // 선택된 날짜로 미리 설정
        let calendar = Calendar.current
        vm.startDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        vm.endDate = calendar.date(byAdding: .hour, value: 1, to: vm.startDate) ?? vm.startDate
        vm.setInitialDueDate(date)  // 초기값으로 설정 (변경사항으로 카운트하지 않음)
        
        return vm
    }
}
