//
//  RepositoryProtocols.swift
//  HaruView
//
//  Created by 김효석 on 4/30/25.
//

import SwiftUI
import EventKit

// MARK: ‑ Repository Protocols
protocol EventRepositoryProtocol {
    func fetchEvent() async -> Result<[Event], TodayBoardError>
    func add(_ input: EventInput) async -> Result<Void, TodayBoardError>
    func update(_ edit: EventEdit) async -> Result<Void, TodayBoardError>
    
    // 기존 메서드는 하위 호환성을 위해 유지
    func deleteEvent(id: String) async -> Result<Void, TodayBoardError>
    
    // 새로운 메서드: span 옵션 포함
    func deleteEvent(id: String, span: EventDeletionSpan) async -> Result<Void, TodayBoardError>
}
protocol ReminderRepositoryProtocol {
    func fetchReminder() async -> Result<[Reminder], TodayBoardError>
    func add(_ input: ReminderInput) async -> Result<Void, TodayBoardError>
    func update(_ edit: ReminderEdit) async -> Result<Void, TodayBoardError>
    func toggle(id: String) async -> Result<Void, TodayBoardError>
    func deleteReminder(id: String) async -> Result<Void, TodayBoardError>
}

extension ReminderRepositoryProtocol {
    func getAvailableReminderCalendars() -> [ReminderCalendar] {
        // 기본 구현체에서는 빈 배열 반환
        // EventKitRepository에서 실제 구현 제공
        return []
    }
}

protocol WeatherRepositoryProtocol {
    func fetchWeather() async -> Result<TodayWeather, TodayBoardError>
}





