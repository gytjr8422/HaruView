//
//  CommonUseCases.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import EventKit

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
