//
//  EventKitService+Reminder.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import EventKit

extension EventKitService {
    // MARK: - 미리알림 CRUD
    func addReminder(_ input: ReminderInput) -> Result<Void, TodayBoardError> {
        let reminder = EKReminder(eventStore: store)
        applyReminderInput(input, to: reminder)
        
        do {
            try store.save(reminder, commit: true)
            Task { @MainActor in
                WidgetRefreshService.shared.refreshWithDebounce()
            }
            return .success(())
        } catch {
            return .failure(.saveFailed)
        }
    }
    
    func updateReminder(_ edit: ReminderEdit) -> Result<Void, TodayBoardError> {
        guard let reminder = store.calendarItem(withIdentifier: edit.id) as? EKReminder else {
            return .failure(.notFound)
        }
        
        applyReminderEdit(edit, to: reminder)
        
        do {
            try store.save(reminder, commit: true)
            Task { @MainActor in
                WidgetRefreshService.shared.refreshWithDebounce()
            }
            return .success(())
        } catch {
            return .failure(.saveFailed)
        }
    }
    
    func deleteReminder(id: String) -> Result<Void, TodayBoardError> {
        guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
            return .failure(.notFound)
        }
        do {
            try store.remove(reminder, commit: true)
            // 위젯 새로고침
            Task { @MainActor in
                WidgetRefreshService.shared.refreshWithDebounce()
            }
            return .success(())
        } catch {
            return .failure(.saveFailed)
        }
    }
    
    func toggleReminder(id: String) -> Result<Void, TodayBoardError> {
        guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
            return .failure(.notFound)
        }
        reminder.isCompleted.toggle()
        do {
            try store.save(reminder, commit: true)
            // 위젯 새로고침
            Task { @MainActor in
                WidgetRefreshService.shared.refreshWithDebounce()
            }
            return .success(())
        } catch {
            return .failure(.saveFailed)
        }
    }
    
    private func applyReminderInput(_ input: ReminderInput, to reminder: EKReminder) {
        reminder.title = input.title
        reminder.notes = input.finalNotes // 사용자 노트만 저장 (메타데이터 없음)
        reminder.url = input.finalURL // ReminderType이 인코딩된 URL 사용
        reminder.location = input.location
        reminder.priority = input.priority
        
        // 마감일 설정
        reminder.dueDateComponents = nil
        if let due = input.due {
            if input.includesTime {
                reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
            } else {
                reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: due)
            }
        }
        
        // 캘린더 설정
        if let calendarId = input.calendarId,
           let calendar = store.calendar(withIdentifier: calendarId) {
            reminder.calendar = calendar
        } else {
            reminder.calendar = store.defaultCalendarForNewReminders()
        }
        
        // 알람 설정 (프리셋 + 커스텀 알림)
        applyAlarmsToReminder(input.finalAlarms, to: reminder)
    }
    
    private func applyReminderEdit(_ edit: ReminderEdit, to reminder: EKReminder) {
        reminder.title = edit.title
        reminder.notes = edit.finalNotes // 사용자 노트만 저장 (메타데이터 없음)
        reminder.url = edit.finalURL // ReminderType이 인코딩된 URL 사용
        reminder.location = edit.location
        reminder.priority = edit.priority
        
        // 마감일 설정
        reminder.dueDateComponents = nil
        if let due = edit.due {
            if edit.includesTime {
                reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
            } else {
                reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: due)
            }
        }
        
        // 캘린더 설정
        if let calendarId = edit.calendarId,
           let calendar = store.calendar(withIdentifier: calendarId) {
            reminder.calendar = calendar
        }
        
        // 알람 설정 (기존 알람 제거 후 새로 추가, 프리셋 + 커스텀 알림)
        applyAlarmsToReminder(edit.finalAlarms, to: reminder)
    }
    
    private func applyAlarmsToReminder(_ alarms: [AlarmInput], to reminder: EKReminder) {
        // 기존 알람 제거
        if let existingAlarms = reminder.alarms {
            for alarm in existingAlarms {
                reminder.removeAlarm(alarm)
            }
        }
        
        // 새 알람 추가
        for alarmInput in alarms {
            let alarm = EKAlarm()
            
            switch alarmInput.trigger {
            case .relative(let interval):
                alarm.relativeOffset = interval
            case .absolute(let date):
                alarm.absoluteDate = date
            }
            
            reminder.addAlarm(alarm)
        }
    }
}
