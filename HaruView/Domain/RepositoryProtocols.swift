//
//  RepositoryProtocols.swift
//  HaruView
//
//  Created by 김효석 on 4/30/25.
//

import Foundation

// MARK: ‑ Repository Protocols
protocol EventRepositoryProtocol {
    func fetchEvent() async -> Result<[Event], TodayBoardError>
    func add(_ input: EventInput) async -> Result<Void, TodayBoardError>
    func update(_ edit: EventEdit) async -> Result<Void, TodayBoardError>
    func deleteEvent(id: String) async -> Result<Void, TodayBoardError>
}

protocol ReminderRepositoryProtocol {
    func fetchReminder() async -> Result<[Reminder], TodayBoardError>
    func add(_ input: ReminderInput) async -> Result<Void, TodayBoardError>
    func toggle(id: String) async -> Result<Void, TodayBoardError>
    func deleteReminder(id: String) async -> Result<Void, TodayBoardError>
}

protocol WeatherRepositoryProtocol {
    func fetchWeather() async -> Result<TodayWeather, TodayBoardError>
}

// MARK: - DTOs
struct EventInput {
    let title: String
    let start: Date
    let end: Date
}

struct EventEdit {
    let id: String
    let title: String
    let start: Date
    let end: Date
}

struct ReminderInput {
    let title: String
    let due: Date?
    let includesTime: Bool
}

struct ReminderEdit {
    let title: String
    let due: Date?
}
