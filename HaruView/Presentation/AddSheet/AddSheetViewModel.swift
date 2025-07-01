//
//  AddSheetViewModel.swift
//  HaruView
//
//  Created by 김효석 on 5/2/25.
//

import SwiftUI

enum AddSheetMode: String, CaseIterable, Identifiable {
    case event = "일정"
    case reminder = "할 일"
    var id: String { rawValue }
    var localized: String { NSLocalizedString(rawValue, comment: "") }
}

// MARK: - ViewModel Protocol
protocol AddSheetViewModelProtocol: ObservableObject {
    var mode: AddSheetMode { get set }
    var currentTitle: String { get set }

    var startDate: Date { get set }
    var endDate: Date { get set }
    var dueDate: Date? { get set }

    var isAllDay: Bool { get set }
    var includeTime: Bool { get set }

    var error: TodayBoardError? { get }
    var isSaving: Bool { get }
    var isEdit: Bool { get }
    var hasChanges: Bool { get }
    
    // Event 관련 프로퍼티들
    var location: String { get set }
    var notes: String { get set }
    var url: String { get set }
    var alarms: [AlarmInput] { get set }
    var recurrenceRule: RecurrenceRuleInput? { get set }
    var selectedCalendar: EventCalendar? { get set }
    var availableCalendars: [EventCalendar] { get }
    
    // Reminder 관련 확장 프로퍼티들
    var reminderPriority: Int { get set }
    var reminderNotes: String { get set }
    var reminderURL: String { get set }
    var reminderLocation: String { get set }
    var reminderAlarms: [AlarmInput] { get set }
    var selectedReminderCalendar: ReminderCalendar? { get set }
    var availableReminderCalendars: [ReminderCalendar] { get }

    func save() async
    func addAlarm(_ alarm: AlarmInput)
    func removeAlarm(at index: Int)
    func setRecurrenceRule(_ rule: RecurrenceRuleInput?)
    func addReminderAlarm(_ alarm: AlarmInput)
    func removeReminderAlarm(at index: Int)
    func setReminderPriority(_ priority: Int)
}


// MARK: - AddSheetViewModel (새 이벤트/리마인더 생성용)
@MainActor
final class AddSheetViewModel: ObservableObject, @preconcurrency AddSheetViewModelProtocol {

    // 기존 Published 프로퍼티들
    @Published var mode: AddSheetMode = .event {
        didSet { currentTitle = titles[mode] ?? "" }
    }
    @Published var currentTitle: String = "" {
        didSet { titles[mode] = currentTitle }
    }
    @Published var startDate: Date = .now {
        didSet { clampEndIfNeeded() }
    }
    @Published var endDate: Date = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
    @Published var dueDate: Date? = nil

    @Published var isAllDay: Bool = false {
        didSet {
            if isAllDay {
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: startDate)
                components.hour = 0
                components.minute = 0
                startDate = calendar.date(from: components)!
                
                components = calendar.dateComponents([.year, .month, .day], from: endDate)
                components.hour = 23
                components.minute = 59
                endDate = calendar.date(from: components)!
            }
        }
    }
    
    @Published var includeTime: Bool = false

    @Published var error: TodayBoardError?
    @Published var isSaving: Bool = false
    
    // 일정 추가 프로퍼티
    @Published var location: String = ""
    @Published var notes: String = ""
    @Published var url: String = ""
    @Published var alarms: [AlarmInput] = []
    @Published var recurrenceRule: RecurrenceRuleInput? = nil
    @Published var selectedCalendar: EventCalendar? = nil
    @Published var availableCalendars: [EventCalendar] = []
    
    // 미리알림 추가 프로퍼티
    @Published var reminderPriority: Int = 0
    @Published var reminderNotes: String = ""
    @Published var reminderURL: String = ""
    @Published var reminderLocation: String = ""
    @Published var reminderAlarms: [AlarmInput] = []
    @Published var selectedReminderCalendar: ReminderCalendar? = nil
    @Published var availableReminderCalendars: [ReminderCalendar] = []

    var isEdit: Bool { false }
    var hasChanges: Bool {
        switch mode {
        case .event:
            return !currentTitle.isEmpty ||
                   startDate > Date() ||
                   !location.isEmpty ||
                   !notes.isEmpty ||
                   !url.isEmpty ||
                   !alarms.isEmpty ||
                   recurrenceRule != nil
        case .reminder:
            return !currentTitle.isEmpty ||
                   dueDate != nil ||
                   reminderPriority > 0 ||
                   !reminderNotes.isEmpty ||
                   !reminderURL.isEmpty ||
                   !reminderLocation.isEmpty ||
                   !reminderAlarms.isEmpty
        }
    }

    private var titles: [AddSheetMode: String] = [.event: "", .reminder: ""]

    // Use Cases
    private let addEvent: AddEventUseCase
    private let addReminder: AddReminderUseCase

    init(addEvent: AddEventUseCase, addReminder: AddReminderUseCase, availableCalendars: [EventCalendar] = []) {
        self.addEvent = addEvent
        self.addReminder = addReminder
        self.availableCalendars = availableCalendars
        
        // 기본 캘린더 선택
        selectDefaultCalendar()
    }
    
    convenience init(
        addEvent: AddEventUseCase,
        addReminder: AddReminderUseCase,
        availableCalendars: [EventCalendar] = [],
        availableReminderCalendars: [ReminderCalendar] = []
    ) {
        self.init(addEvent: addEvent, addReminder: addReminder, availableCalendars: availableCalendars)
        self.availableReminderCalendars = availableReminderCalendars
        selectDefaultReminderCalendar()
    }

    func save() async {
        isSaving = true
        error = nil
        
        if mode == .event { clampEndIfNeeded() }
        
        switch mode {
        case .event:
            let eventInput = EventInput(
                title: titles[.event] ?? "",
                start: startDate,
                end: endDate,
                location: location.isEmpty ? nil : location,
                notes: notes.isEmpty ? nil : notes,
                url: url.isEmpty ? nil : URL(string: url),
                alarms: alarms,
                recurrenceRule: recurrenceRule,
                calendarId: selectedCalendar?.id
            )
            let res = await addEvent(eventInput)
            handle(res)
            
        case .reminder:
            let reminderInput = ReminderInput(
                title: titles[.reminder] ?? "",
                due: dueDate,
                includesTime: includeTime,
                priority: reminderPriority,
                notes: reminderNotes.isEmpty ? nil : reminderNotes,
                url: reminderURL.isEmpty ? nil : URL(string: reminderURL),
                location: reminderLocation.isEmpty ? nil : reminderLocation,
                alarms: reminderAlarms,
                calendarId: selectedReminderCalendar?.id
            )
            let res = await addReminder(reminderInput)
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
    private func selectDefaultCalendar() {
        if let defaultCalendar = availableCalendars.first(where: { $0.type == .local }) {
            selectedCalendar = defaultCalendar
        } else {
            selectedCalendar = availableCalendars.first
        }
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
    
    // MARK: - 미리알림
    func addReminderAlarm(_ alarm: AlarmInput) {
        reminderAlarms.append(alarm)
    }
    
    func removeReminderAlarm(at index: Int) {
        guard reminderAlarms.indices.contains(index) else { return }
        reminderAlarms.remove(at: index)
    }
     
     // MARK: - 우선순위 관리
    func setReminderPriority(_ priority: Int) {
        reminderPriority = priority
    }
     
     // MARK: - 리마인더 캘린더 초기화
    private func selectDefaultReminderCalendar() {
        if let defaultCalendar = availableReminderCalendars.first(where: { $0.type == .local }) {
            selectedReminderCalendar = defaultCalendar
        } else {
            selectedReminderCalendar = availableReminderCalendars.first
        }
    }
     
     // init에서 호출할 초기화 메서드
//     private func initializeReminderCalendars() {
//         // Repository에서 사용 가능한 리마인더 캘린더 가져오기
//         // availableReminderCalendars = eventKitRepository.getAvailableReminderCalendars()
//         selectDefaultReminderCalendar()
//     }
}

