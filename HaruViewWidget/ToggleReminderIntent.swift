//
//  ToggleReminderIntent.swift
//  HaruViewWidgetExtension
//
//  Created by 김효석 on 6/22/25.
//

import AppIntents
import EventKit

struct ToggleReminderIntent: AppIntent {
    static var title: LocalizedStringResource = "할 일 토글"
    static var description = IntentDescription("위젯에서 할 일의 완료 상태를 토글합니다.")
    
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
            return "미리알림 접근 권한이 필요합니다."
        case .reminderNotFound:
            return "미리알림을 찾을 수 없습니다."
        case .saveFailed:
            return "미리알림 저장에 실패했습니다."
        }
    }
}
