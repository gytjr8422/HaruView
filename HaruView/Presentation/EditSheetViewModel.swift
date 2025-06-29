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
    @Published var dueDate: Date? = nil
    @Published var isAllDay: Bool = false
    @Published var includeTime: Bool = false
    @Published var error: TodayBoardError?
    @Published var isSaving: Bool = false
    
    // 확장된 Published 프로퍼티들
    @Published var location: String = ""
    @Published var notes: String = ""
    @Published var url: String = ""
    @Published var alarms: [AlarmInput] = []
    @Published var recurrenceRule: RecurrenceRuleInput? = nil
    @Published var selectedCalendar: EventCalendar? = nil
    @Published var availableCalendars: [EventCalendar] = []

    var isEdit: Bool { true }
    var hasChanges: Bool {
        switch mode {
        case .event:
            guard let original = originalEvent else { return false }
            if currentTitle != original.title { return true }
            if startDate != original.start { return true }
            if endDate != original.end { return true }
            if location != (original.location ?? "") { return true }
            if notes != (original.notes ?? "") { return true }
            if url != (original.url?.absoluteString ?? "") { return true }
            if alarms.count != original.alarms.count { return true }
            if (recurrenceRule != nil) != original.hasRecurrence { return true }
            
            let cal = Calendar.current
            let compsStart = cal.dateComponents([.hour, .minute], from: original.start)
            let compsEnd = cal.dateComponents([.hour, .minute], from: original.end)
            let origAllDay = cal.isDate(original.start, inSameDayAs: original.end) &&
                           compsStart.hour == 0 && compsStart.minute == 0 &&
                           compsEnd.hour == 23 && compsEnd.minute == 59
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

    private var titles: [AddSheetMode: String] = [.event: "", .reminder: ""]

    private let editEvent: EditEventUseCase
    private let editReminder: EditReminderUseCase
    private let objectId: String
    private let originalEvent: Event?
    private let originalReminder: Reminder?

    // Event 편집용 초기화
    init(event: Event, editEvent: EditEventUseCase, editReminder: EditReminderUseCase, availableCalendars: [EventCalendar] = []) {
        self.editEvent = editEvent
        self.editReminder = editReminder
        self.objectId = event.id
        self.originalEvent = event
        self.originalReminder = nil
        self.mode = .event
        self.availableCalendars = availableCalendars
        
        // 기존 이벤트 데이터로 초기화
        initializeWithEvent(event)
    }

    // Reminder 편집용 초기화
    init(reminder: Reminder, editEvent: EditEventUseCase, editReminder: EditReminderUseCase, availableCalendars: [EventCalendar] = []) {
        self.editEvent = editEvent
        self.editReminder = editReminder
        self.objectId = reminder.id
        self.originalEvent = nil
        self.originalReminder = reminder
        self.mode = .reminder
        self.availableCalendars = availableCalendars
        
        // 기존 리마인더 데이터로 초기화
        initializeWithReminder(reminder)
    }

    func save() async {
        isSaving = true
        error = nil

        if mode == .event { clampEndIfNeeded() }

        switch mode {
        case .event:
            let eventEdit = EventEdit(
                id: objectId,
                title: titles[.event] ?? "",
                start: startDate,
                end: endDate,
                location: location.isEmpty ? nil : location,
                notes: notes.isEmpty ? nil : notes,
                url: url.isEmpty ? nil : URL(string: url),
                alarms: alarms,
                recurrenceRule: recurrenceRule
            )
            let res = await editEvent(eventEdit)
            handle(res)
            
        case .reminder:
            let reminderEdit = ReminderEdit(
                id: objectId,
                title: titles[.reminder] ?? "",
                due: dueDate,
                includesTime: includeTime
            )
            let res = await editReminder(reminderEdit)
            handle(res)
        }
        isSaving = false
    }
    
    // MARK: - 알람 관리
    func addAlarm(_ alarm: AlarmInput) {
        alarms.append(alarm)
    }
    
    func removeAlarm(at index: Int) {
        guard alarms.indices.contains(index) else { return }
        alarms.remove(at: index)
    }
    
    // MARK: - 반복 규칙 관리
    func setRecurrenceRule(_ rule: RecurrenceRuleInput?) {
        recurrenceRule = rule
    }

    // MARK: - Private Methods
    private func initializeWithEvent(_ event: Event) {
        currentTitle = event.title
        startDate = event.start
        endDate = event.end
        location = event.location ?? ""
        notes = event.notes ?? ""
        url = event.url?.absoluteString ?? ""
        
        // 현재 이벤트의 캘린더 찾기
        selectedCalendar = availableCalendars.first { $0.id == event.calendar.id }
        
        // 기존 알람을 AlarmInput으로 변환
        alarms = event.alarms.map { alarm in
            let type: AlarmInput.AlarmType = .display
            let trigger: AlarmInput.AlarmTrigger
            
            if let absoluteDate = alarm.absoluteDate {
                trigger = .absolute(absoluteDate)
            } else {
                trigger = .relative(alarm.relativeOffset)
            }
            
            return AlarmInput(type: type, trigger: trigger)
        }
        
        // 기존 반복 규칙을 RecurrenceRuleInput으로 변환
        if let rule = event.recurrenceRule {
            recurrenceRule = convertToRecurrenceRuleInput(rule)
        }
        
        // 하루 종일 이벤트 판별
        let cal = Calendar.current
        let compsStart = cal.dateComponents([.hour, .minute], from: event.start)
        let compsEnd = cal.dateComponents([.hour, .minute], from: event.end)
        if cal.isDate(event.start, inSameDayAs: event.end) &&
           compsStart.hour == 0 && compsStart.minute == 0 &&
           compsEnd.hour == 23 && compsEnd.minute == 59 {
            isAllDay = true
        }
        
        titles[.event] = event.title
    }
    
    private func initializeWithReminder(_ reminder: Reminder) {
        currentTitle = reminder.title
        dueDate = reminder.due
        includeTime = reminder.due != nil
        titles[.reminder] = reminder.title
    }
    
    private func convertToRecurrenceRuleInput(_ rule: EventRecurrenceRule) -> RecurrenceRuleInput {
        let frequency: RecurrenceRuleInput.RecurrenceFrequency
        switch rule.frequency {
        case .daily: frequency = .daily
        case .weekly: frequency = .weekly
        case .monthly: frequency = .monthly
        case .yearly: frequency = .yearly
        }
        
        let endCondition: RecurrenceRuleInput.EndCondition
        if let endDate = rule.endDate {
            endCondition = .endDate(endDate)
        } else if let count = rule.occurrenceCount {
            endCondition = .occurrenceCount(count)
        } else {
            endCondition = .never
        }
        
        let daysOfWeek = rule.daysOfWeek?.map { weekday in
            RecurrenceRuleInput.WeekdayInput(
                dayOfWeek: weekday.dayOfWeek,
                weekNumber: weekday.weekNumber
            )
        }
        
        return RecurrenceRuleInput(
            frequency: frequency,
            interval: rule.interval,
            endCondition: endCondition,
            daysOfWeek: daysOfWeek,
            daysOfMonth: rule.daysOfMonth
        )
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
