//
//  EditSheetViewModel.swift
//  HaruView
//
//  Created by Codex on 2024.
//

import SwiftUI

@MainActor
final class EditSheetViewModel: ObservableObject, @preconcurrency AddSheetViewModelProtocol {
    @Published var mode: AddSheetMode = .event { didSet { currentTitle = titles[mode] ?? "" } }
    @Published var currentTitle: String = "" { didSet { titles[mode] = currentTitle } }
    @Published var startDate: Date = .now { didSet { clampEndIfNeeded() } }
    @Published var endDate: Date = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
    @Published var dueDate: Date = .now
    @Published var isAllDay: Bool = false
    @Published var includeTime: Bool = true
    @Published var error: TodayBoardError?
    @Published var isSaving: Bool = false

    var isEdit: Bool { true }
    var hasChanges: Bool {
        switch mode {
        case .event:
            guard let original = originalEvent else { return false }
            if currentTitle != original.title { return true }
            if startDate != original.start { return true }
            if endDate != original.end { return true }
            let cal = Calendar.current
            let compsStart = cal.dateComponents([.hour, .minute], from: original.start)
            let compsEnd = cal.dateComponents([.hour, .minute], from: original.end)
            let origAllDay = cal.isDate(original.start, inSameDayAs: original.end) && compsStart.hour == 0 && compsStart.minute == 0 && compsEnd.hour == 23 && compsEnd.minute == 59
            if isAllDay != origAllDay { return true }
            return false
        case .reminder:
            guard let original = originalReminder else { return false }
            if currentTitle != original.title { return true }
            let newDue: Date? = includeTime ? dueDate : nil
            if original.due != newDue { return true }
            return false
        }
    }

    private var titles: [AddSheetMode:String] = [.event:"", .reminder:""]

    private let editEvent: EditEventUseCase
    private let editReminder: EditReminderUseCase
    private let objectId: String
    private let originalEvent: Event?
    private let originalReminder: Reminder?

    init(event: Event, editEvent: EditEventUseCase, editReminder: EditReminderUseCase) {
        self.editEvent = editEvent
        self.editReminder = editReminder
        self.objectId = event.id
        self.originalEvent = event
        self.originalReminder = nil
        self.mode = .event
        self.currentTitle = event.title
        self.startDate = event.start
        self.endDate = event.end
        let cal = Calendar.current
        let compsStart = cal.dateComponents([.hour, .minute], from: event.start)
        let compsEnd = cal.dateComponents([.hour, .minute], from: event.end)
        if cal.isDate(event.start, inSameDayAs: event.end) && compsStart.hour == 0 && compsStart.minute == 0 && compsEnd.hour == 23 && compsEnd.minute == 59 {
            self.isAllDay = true
        }
        titles[.event] = event.title
    }

    init(reminder: Reminder, editEvent: EditEventUseCase, editReminder: EditReminderUseCase) {
        self.editEvent = editEvent
        self.editReminder = editReminder
        self.objectId = reminder.id
        self.originalEvent = nil
        self.originalReminder = reminder
        self.mode = .reminder
        self.currentTitle = reminder.title
        if let due = reminder.due { self.dueDate = due }
        self.includeTime = reminder.due != nil
        titles[.reminder] = reminder.title
    }

    func save() async {
        isSaving = true
        error = nil

        if mode == .event { clampEndIfNeeded() }

        switch mode {
        case .event:
            let res = await editEvent(.init(id: objectId, title: titles[.event] ?? "", start: startDate, end: endDate))
            handle(res)
        case .reminder:
            let res = await editReminder(.init(id: objectId, title: titles[.reminder] ?? "", due: dueDate, includesTime: includeTime))
            handle(res)
        }
        isSaving = false
    }

    private func clampEndIfNeeded() {
        guard !isAllDay else { return }
        let minInterval: TimeInterval = 60
        if endDate < startDate.addingTimeInterval(minInterval) {
            endDate = startDate.addingTimeInterval(minInterval)
        }
    }

    private func handle(_ result: Result<Void, TodayBoardError>) {
        if case .failure(let err) = result { self.error = err }
    }
}

