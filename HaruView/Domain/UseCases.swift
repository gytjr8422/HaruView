//
//  UseCases.swift
//  HaruView
//
//  Created by 김효석 on 4/30/25.
//

import Foundation

// MARK: ‑ UseCases

/// 통합 홈 카드 데이터를 제공하는 유스케이스.
struct FetchTodayOverviewUseCase {
    private let events: EventRepositoryProtocol
    private let reminders: ReminderRepositoryProtocol
    private let weather: WeatherRepositoryProtocol
    
    init(events: EventRepositoryProtocol, reminders: ReminderRepositoryProtocol, weather: WeatherRepositoryProtocol) {
        self.events = events
        self.reminders = reminders
        self.weather = weather
    }
    
    func callAsFunction() async -> Result<TodayOverview, TodayBoardError> {
        // 동시 작업 시작
        async let eRes = self.events.fetchEvent()
        async let rRes = self.reminders.fetchReminder()
        async let wRes = self.weather.fetchWeather()
        
        switch (await eRes, await rRes, await wRes) {
        case let (.success(e), .success(r), .success(w)):
            return .success(.init(events: e, reminders: r, weather: w))
        case (.failure(let err), _, _), (_, .failure(let err), _), (_, _, .failure(let err)):
            return .failure(err)
        }
    }
}

/// 일정 추가 유스케이스
struct AddEventUseCase {
    private let repo: EventRepositoryProtocol
    
    init(repo: EventRepositoryProtocol) {
        self.repo = repo
    }
    
    func callAsFunction(_ input: EventInput) async -> Result<Void, TodayBoardError> {
        await repo.add(input)
    }
}

/// 일정 수정 유스케이스
struct EditEventUseCase {
    private let repo: EventRepositoryProtocol
    
    init(repo: EventRepositoryProtocol) {
        self.repo = repo
    }
    
    func callAsFunction(_ edit: EventEdit) async -> Result<Void, TodayBoardError> {
        await repo.update(edit)
    }
}

/// 미리알림 추가 유스케이스
struct AddReminderUseCase {
    private let repo: ReminderRepositoryProtocol
    
    init(repo: ReminderRepositoryProtocol) {
        self.repo = repo
    }
    
    func callAsFunction(_ input: ReminderInput) async -> Result<Void, TodayBoardError> {
        await repo.add(input)
    }
}



/// 일정, 미리알림 삭제 유스케이스 (공통)
struct DeleteObjectUseCase {
    public enum ObjectKind {
        case event(String)
        case reminder(String)
    }
    
    private let events: EventRepositoryProtocol
    private let reminders: ReminderRepositoryProtocol
    
    init(events: EventRepositoryProtocol, reminders: ReminderRepositoryProtocol) {
        self.events = events
        self.reminders = reminders
    }
    
    func callAsFunction(_ object: ObjectKind) async -> Result<Void, TodayBoardError> {
        switch object {
        case .event(let id):
            await events.deleteEvent(id: id)
        case .reminder(let id):
            await reminders.deleteReminder(id: id)
        }
    }
}
