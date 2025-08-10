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
    
    // 미리알림용 프로퍼티
    @Published var reminderType: ReminderType = .onDate
    @Published var reminderPriority: Int = 0
    @Published var reminderNotes: String = ""
    @Published var reminderURL: String = ""
    @Published var reminderLocation: String = ""
    @Published var reminderAlarms: [AlarmInput] = []
    @Published var selectedReminderCalendar: ReminderCalendar? = nil
    @Published var availableReminderCalendars: [ReminderCalendar] = []
    
    // 반복 일정 편집 범위 선택을 위한 상태
    @Published var showRecurringEditOptions: Bool = false
    @Published var pendingSaveAction: (() -> Void)? = nil
    @Published var saveCompleted: Bool = false
    
    // 삭제 관련 상태
    @Published var isDeleting: Bool = false
    @Published var showDeleteConfirmation: Bool = false
    @Published var showRecurringDeleteOptions: Bool = false
    @Published var pendingDeleteAction: (() -> Void)? = nil
    @Published var deleteCompleted: Bool = false

    var isEdit: Bool { true }
    var hasChanges: Bool {
        // showRecurringEditOptions가 true일 때는 hasChanges를 true로 유지
        if showRecurringEditOptions {
            return true
        }
        
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
            if reminderType != original.reminderType { return true }
            if reminderPriority != original.priority { return true }
            if reminderNotes != (original.notes ?? "") { return true }
            if reminderURL != (original.url?.absoluteString ?? "") { return true }
            if reminderLocation != (original.location ?? "") { return true }
            if reminderAlarms.count != original.alarms.count { return true }
            return false
        }
    }

    private var titles: [AddSheetMode: String] = [.event: "", .reminder: ""]

    private let editEvent: EditEventUseCase
    private let editReminder: EditReminderUseCase
    private let deleteObject: DeleteObjectUseCase
    private let objectId: String
    private let originalEvent: Event?
    private let originalReminder: Reminder?

    // Event 편집용 초기화
    init(event: Event, editEvent: EditEventUseCase, editReminder: EditReminderUseCase, deleteObject: DeleteObjectUseCase, availableCalendars: [EventCalendar] = []) {
        self.editEvent = editEvent
        self.editReminder = editReminder
        self.deleteObject = deleteObject
        self.objectId = event.id
        self.originalEvent = event
        self.originalReminder = nil
        self.mode = .event
        self.availableCalendars = availableCalendars
        
        // 기존 이벤트 데이터로 초기화
        initializeWithEvent(event)
    }

    // Reminder 편집용 초기화
    init(reminder: Reminder, editEvent: EditEventUseCase, editReminder: EditReminderUseCase, deleteObject: DeleteObjectUseCase, availableCalendars: [EventCalendar] = []) {
        self.editEvent = editEvent
        self.editReminder = editReminder
        self.deleteObject = deleteObject
        self.objectId = reminder.id
        self.originalEvent = nil
        self.originalReminder = reminder
        self.mode = .reminder
        self.availableCalendars = availableCalendars
        
        // 기존 리마인더 데이터로 초기화
        initializeWithReminder(reminder)
    }
    
    // Event 편집용 초기화
    convenience init(
        event: Event,
        editEvent: EditEventUseCase,
        editReminder: EditReminderUseCase,
        deleteObject: DeleteObjectUseCase,
        availableCalendars: [EventCalendar] = [],
        availableReminderCalendars: [ReminderCalendar] = []
    ) {
        self.init(event: event, editEvent: editEvent, editReminder: editReminder, deleteObject: deleteObject, availableCalendars: availableCalendars)
        self.availableReminderCalendars = availableReminderCalendars
    }
    
    // Reminder 편집용 초기화
    convenience init(
        reminder: Reminder,
        editEvent: EditEventUseCase,
        editReminder: EditReminderUseCase,
        deleteObject: DeleteObjectUseCase,
        availableCalendars: [EventCalendar] = [],
        availableReminderCalendars: [ReminderCalendar] = []
    ) {
        self.init(reminder: reminder, editEvent: editEvent, editReminder: editReminder, deleteObject: deleteObject, availableCalendars: availableCalendars)
        self.availableReminderCalendars = availableReminderCalendars
        initializeWithReminder(reminder)
    }

    // save 메서드 확장 (기존 save 메서드 교체)
     func save() async {
         saveCompleted = false
         
         // 반복 일정인 경우 사용자에게 편집 범위를 묻기
         if mode == .event, let originalEvent = originalEvent, originalEvent.hasRecurrence {
             // 다음 런루프에서 상태 변경하여 "Publishing changes from within view updates" 오류 방지
             Task { @MainActor in
                 self.pendingSaveAction = {
                     Task {
                         await self.performSave()
                     }
                 }
                 self.showRecurringEditOptions = true
             }
             return
         }
         
         await performSave()
     }
     
     /// 실제 저장 수행
     private func performSave(editSpan: EventEditSpan = .thisEventOnly) async {
         isSaving = true
         error = nil

         if mode == .event { clampEndIfNeeded() }

         switch mode {
         case .event:
             // 반복 일정에서 반복 규칙 변경 시 경고
             if let originalEvent = originalEvent, originalEvent.hasRecurrence {
                 let originalHasRecurrence = originalEvent.hasRecurrence
                 let newHasRecurrence = recurrenceRule != nil
                 
                 if originalHasRecurrence && (newHasRecurrence || (!newHasRecurrence && originalHasRecurrence)) {
                     // 반복 규칙을 변경하려는 경우 - 기존 반복 규칙 유지
                     let eventEdit = EventEdit(
                         id: objectId,
                         title: titles[.event] ?? "",
                         start: startDate,
                         end: endDate,
                         location: location.isEmpty ? nil : location,
                         notes: notes.isEmpty ? nil : notes,
                         url: url.isEmpty ? nil : URL(string: url),
                         alarms: alarms,
                         recurrenceRule: nil, // 반복 규칙 변경 방지
                         editSpan: editSpan,
                         calendarId: selectedCalendar?.id
                     )
                     let res = await editEvent(eventEdit)
                     handle(res)
                 } else {
                     let eventEdit = EventEdit(
                         id: objectId,
                         title: titles[.event] ?? "",
                         start: startDate,
                         end: endDate,
                         location: location.isEmpty ? nil : location,
                         notes: notes.isEmpty ? nil : notes,
                         url: url.isEmpty ? nil : URL(string: url),
                         alarms: alarms,
                         recurrenceRule: recurrenceRule,
                         editSpan: editSpan,
                         calendarId: selectedCalendar?.id
                     )
                     let res = await editEvent(eventEdit)
                     handle(res)
                 }
             } else {
                 let eventEdit = EventEdit(
                     id: objectId,
                     title: titles[.event] ?? "",
                     start: startDate,
                     end: endDate,
                     location: location.isEmpty ? nil : location,
                     notes: notes.isEmpty ? nil : notes,
                     url: url.isEmpty ? nil : URL(string: url),
                     alarms: alarms,
                     recurrenceRule: recurrenceRule,
                     editSpan: editSpan,
                     calendarId: selectedCalendar?.id
                 )
                 let res = await editEvent(eventEdit)
                 handle(res)
             }
             
         case .reminder:
             let reminderEdit = ReminderEdit(
                 id: objectId,
                 title: titles[.reminder] ?? "",
                 due: dueDate,
                 includesTime: includeTime,
                 priority: reminderPriority,
                 notes: reminderNotes.isEmpty ? nil : reminderNotes,
                 url: reminderURL.isEmpty ? nil : URL(string: reminderURL),
                 location: reminderLocation.isEmpty ? nil : reminderLocation,
                 alarms: reminderAlarms,
                 calendarId: selectedReminderCalendar?.id,
                 reminderType: reminderType
             )
             let res = await editReminder(reminderEdit)
             handle(res)
         }
         isSaving = false
         saveCompleted = error == nil
     }
     
     /// 반복 일정 편집 범위 선택
     func editEventWithSpan(_ span: EventEditSpan) {
         showRecurringEditOptions = false
         pendingSaveAction = nil
         
         Task {
             await performSave(editSpan: span)
         }
     }
     
     /// 반복 일정 편집 취소
     func cancelEventEdit() {
         showRecurringEditOptions = false
         pendingSaveAction = nil
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
        reminderType = reminder.reminderType
        reminderPriority = reminder.priority
        reminderNotes = reminder.notes ?? ""
        reminderURL = reminder.url?.absoluteString ?? ""
        reminderLocation = reminder.location ?? ""
        
        // 현재 리마인더의 캘린더 찾기
        selectedReminderCalendar = availableReminderCalendars.first { $0.id == reminder.calendar.id }
        
        // 기존 알람을 AlarmInput으로 변환
        reminderAlarms = reminder.alarms.map { alarm in
            let type: AlarmInput.AlarmType = .display
            let trigger: AlarmInput.AlarmTrigger
            
            if let absoluteDate = alarm.absoluteDate {
                trigger = .absolute(absoluteDate)
            } else {
                trigger = .relative(alarm.relativeOffset)
            }
            
            return AlarmInput(type: type, trigger: trigger)
        }
        
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
        
        let minInterval: TimeInterval = 0
        if endDate < startDate.addingTimeInterval(minInterval) {
            endDate = startDate.addingTimeInterval(minInterval)
        }
    }

    private func handle(_ result: Result<Void, TodayBoardError>) {
        if case .failure(let err) = result { self.error = err }
    }
    
    // MARK: - 리마인더 알람 관리 메서드들
    func addReminderAlarm(_ alarm: AlarmInput) {
        reminderAlarms.append(alarm)
    }
    
    func removeReminderAlarm(at index: Int) {
        guard reminderAlarms.indices.contains(index) else { return }
        reminderAlarms.remove(at: index)
    }
    
    func setReminderPriority(_ priority: Int) {
        reminderPriority = priority
    }
    
    // MARK: - 삭제 관련 메서드
    func requestDelete() {
        showDeleteConfirmation = true
    }
    
    func cancelDelete() {
        showDeleteConfirmation = false
    }
    
    func confirmDelete() async {
        showDeleteConfirmation = false
        
        // 반복 일정인 경우 사용자에게 삭제 범위를 묻기
        if mode == .event, let originalEvent = originalEvent, originalEvent.hasRecurrence {
            Task { @MainActor in
                self.pendingDeleteAction = {
                    Task {
                        await self.performDelete()
                    }
                }
                self.showRecurringDeleteOptions = true
            }
            return
        }
        
        await performDelete()
    }
    
    /// 실제 삭제 수행
    private func performDelete(deleteSpan: EventDeletionSpan = .thisEventOnly) async {
        isDeleting = true
        error = nil
        
        let result: Result<Void, TodayBoardError>
        
        switch mode {
        case .event:
            if let originalEvent = originalEvent, originalEvent.hasRecurrence {
                // 반복 일정인 경우 - 선택된 범위로 삭제
                result = await deleteObject(.eventWithSpan(objectId, deleteSpan))
            } else {
                // 일반 일정
                result = await deleteObject(.event(objectId))
            }
        case .reminder:
            result = await deleteObject(.reminder(objectId))
        }
        
        await MainActor.run {
            switch result {
            case .success:
                isDeleting = false
                deleteCompleted = true
            case .failure(let deleteError):
                isDeleting = false
                error = deleteError
            }
        }
    }
    
    /// 반복 일정 삭제 범위 선택
    func deleteEventWithSpan(_ span: EventDeletionSpan) {
        showRecurringDeleteOptions = false
        pendingDeleteAction = nil
        
        Task {
            await performDelete(deleteSpan: span)
        }
    }
    
    /// 반복 일정 삭제 취소
    func cancelEventDelete() {
        showRecurringDeleteOptions = false
        pendingDeleteAction = nil
    }
}
