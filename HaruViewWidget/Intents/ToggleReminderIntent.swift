//
//  ToggleReminderIntent.swift
//  HaruViewWidgetExtension
//
//  Created by 김효석 on 6/22/25.
//

import AppIntents
import EventKit
import WidgetKit

struct ToggleReminderIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Reminder"
    static var description = IntentDescription("Toggle the completion status of a reminder from the widget.")
    
    @Parameter(title: "Reminder ID")
    var reminderId: String
    
    init() {}
    
    init(reminderId: String) {
        self.reminderId = reminderId
    }
    
    func perform() async throws -> some IntentResult {
        
        // EventKit을 사용하여 실제 미리알림 토글
        let eventStore = EKEventStore()
        
        // 권한 확인
        let status = EKEventStore.authorizationStatus(for: .reminder)
        guard status == .fullAccess else {
            throw IntentError.permissionDenied
        }
        
        // 미리알림 찾기
        guard let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
            throw IntentError.reminderNotFound
        }
        
        // 완료 상태 토글
        reminder.isCompleted.toggle()
        
        // 저장
        do {
            try eventStore.save(reminder, commit: true)
            
            // 즉시 모든 위젯 새로고침 (여러 위젯이 있을 때 동기화를 위해)
            await MainActor.run {
                // 1. 특정 위젯 타입만 새로고침 (더 효율적)
                WidgetCenter.shared.reloadTimelines(ofKind: "HaruViewWidget")
                
                // 2. 만약 위 방법이 충분하지 않다면, 모든 위젯 새로고침
                WidgetCenter.shared.reloadAllTimelines()
            }
            
            // EventKit 변경 알림 발송 (앱과 위젯 간 동기화)
            NotificationCenter.default.post(name: .EKEventStoreChanged, object: nil)
            
        } catch {
            throw IntentError.saveFailed
        }
        
        return .result()
    }
}

enum IntentError: Error, LocalizedError {
    case permissionDenied
    case reminderNotFound
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Reminder access permission is required."
        case .reminderNotFound:
            return "Reminder not found."
        case .saveFailed:
            return "Failed to save reminder."
        }
    }
}
