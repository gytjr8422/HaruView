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
    private let originalTitle: String
    private let originalStart: Date
    private let originalEnd: Date
    private let originalDue: Date?
    private let originalAllDay: Bool
    private let originalIncludeTime: Bool
    var hasChanges: Bool {
        switch mode {
        case .event:
            return currentTitle != originalTitle ||
                   startDate != originalStart ||
                   endDate != originalEnd ||
                   isAllDay != originalAllDay
        case .reminder:
            if currentTitle != originalTitle { return true }
            if includeTime != originalIncludeTime { return true }
            if includeTime {
                if let origDue = originalDue { return dueDate != origDue }
                return true
            } else {
                return originalIncludeTime
            }
        }
    }

    private var titles: [AddSheetMode:String] = [.event:"", .reminder:""]

    private let editEvent: EditEventUseCase
    private let editReminder: EditReminderUseCase
    private let objectId: String

    init(event: Event, editEvent: EditEventUseCase, editReminder: EditReminderUseCase) {
        self.editEvent = editEvent
        self.editReminder = editReminder
        self.objectId = event.id
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
        self.originalTitle = event.title
        self.originalStart = event.start
        self.originalEnd = event.end
        self.originalAllDay = self.isAllDay
        self.originalDue = nil
        self.originalIncludeTime = false
    }

    init(reminder: Reminder, editEvent: EditEventUseCase, editReminder: EditReminderUseCase) {
        self.editEvent = editEvent
        self.editReminder = editReminder
        self.objectId = reminder.id
        self.mode = .reminder
        self.currentTitle = reminder.title
        if let due = reminder.due { self.dueDate = due }
        self.includeTime = reminder.due != nil
        titles[.reminder] = reminder.title
        self.originalTitle = reminder.title
        self.originalStart = .now
        self.originalEnd = .now
        self.originalAllDay = false
        self.originalDue = reminder.due
        self.originalIncludeTime = reminder.due != nil
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

