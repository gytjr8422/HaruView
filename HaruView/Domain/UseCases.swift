//
//  UseCases.swift
//  HaruView
//
//  Created by 김효석 on 4/30/25.
//

import Foundation
import EventKit

// MARK: ‑ UseCases

/// 일정/미리알림 카드 데이터를 제공하는 유스케이스.
struct FetchTodayOverviewUseCase {
    private let events:    EventRepositoryProtocol
    private let reminders: ReminderRepositoryProtocol

    init(events: EventRepositoryProtocol,
         reminders: ReminderRepositoryProtocol) {
        self.events    = events
        self.reminders = reminders
    }

    func callAsFunction() async -> Result<TodayOverview, TodayBoardError> {
        if EKEventStore.authorizationStatus(for: .event) != .fullAccess ||
           EKEventStore.authorizationStatus(for: .reminder) != .fullAccess {
            return .success(.placeholder)
        }

        async let eRes = events.fetchEvent()
        async let rRes = reminders.fetchReminder()

        switch (await eRes, await rRes) {
        case let (.success(e), .success(r)):
            return .success(.init(events: e, reminders: r))
        case (.failure(let err), _), (_, .failure(let err)):
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

/// 미리알림 수정 유스케이스
struct EditReminderUseCase {
    private let repo: ReminderRepositoryProtocol

    init(repo: ReminderRepositoryProtocol) {
        self.repo = repo
    }

    func callAsFunction(_ edit: ReminderEdit) async -> Result<Void, TodayBoardError> {
        await repo.update(edit)
    }
}

struct FetchTodayWeatherUseCase {
    private let repo: WeatherRepositoryProtocol
    
    init(repo: WeatherRepositoryProtocol) { self.repo = repo }

    func callAsFunction() async -> Result<TodayWeather, TodayBoardError> {
        await repo.fetchWeather()
    }
}


struct ToggleReminderUseCase {
    private let repo: ReminderRepositoryProtocol
    
    init(repo: ReminderRepositoryProtocol) {
        self.repo = repo
    }
    
    func callAsFunction(_ id: String) async -> Result<Void, TodayBoardError> {
        await repo.toggle(id: id)
    }
}


/// 일정, 미리알림 삭제 유스케이스 (공통)
struct DeleteObjectUseCase {
    enum ObjectKind {
        case event(String)
        case reminder(String)
        // 새로운 케이스 추가: span 옵션 포함
        case eventWithSpan(String, EventDeletionSpan)
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
            return await events.deleteEvent(id: id)
        case .reminder(let id):
            return await reminders.deleteReminder(id: id)
        case .eventWithSpan(let id, let span):
            return await events.deleteEvent(id: id, span: span)
        }
    }
}
