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
    static var title: LocalizedStringResource = "할 일 토글"
    static var description = IntentDescription("위젯에서 할 일의 완료 상태를 토글합니다.")
    
    @Parameter(title: "Reminder ID")
    var reminderId: String
    
    init() {}
    
    init(reminderId: String) {
        self.reminderId = reminderId
    }
    
    func perform() async throws -> some IntentResult {
        print("🔄 ToggleReminderIntent started for ID: \(reminderId)")
        
        // EventKit을 사용하여 실제 미리알림 토글
        let eventStore = EKEventStore()
        
        // 권한 확인
        let status = EKEventStore.authorizationStatus(for: .reminder)
        guard status == .fullAccess else {
            print("❌ Permission denied for reminders")
            throw IntentError.permissionDenied
        }
        
        // 미리알림 찾기
        guard let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
            print("❌ Reminder not found: \(reminderId)")
            throw IntentError.reminderNotFound
        }
        
        let wasCompleted = reminder.isCompleted
        
        // 완료 상태 토글
        reminder.isCompleted.toggle()
        
        print("🔄 Toggling reminder '\(reminder.title ?? "Unknown")' from \(wasCompleted) to \(reminder.isCompleted)")
        
        // 저장
        do {
            try eventStore.save(reminder, commit: true)
            print("✅ Reminder saved successfully")
            
            // invalidatableContent를 사용하므로 부분 업데이트가 즉시 발생
            // 2초 후 전체 위젯 새로고침으로 정렬 실행
            Task {
                try? await Task.sleep(for: .seconds(2))
                await MainActor.run {
                    WidgetCenter.shared.reloadTimelines(ofKind: "HaruViewWidget")
                    print("🔄 Widget reloaded for sorting")
                }
            }
            
        } catch {
            print("❌ Failed to save reminder: \(error)")
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
