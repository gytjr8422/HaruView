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
            
            // 🚀 모든 위젯을 즉시 새로고침
            await refreshAllWidgets()
            
        } catch {
            print("❌ Failed to save reminder: \(error)")
            throw IntentError.saveFailed
        }
        
        return .result()
    }
    
    // MARK: - 위젯 새로고침 로직
    @MainActor
    private func refreshAllWidgets() {
        print("🔄 Refreshing all widgets after reminder toggle...")
        
        // 1. 즉시 새로고침
        WidgetCenter.shared.reloadTimelines(ofKind: "HaruViewWidget")
        
        // 2. 조금 후 다시 새로고침 (iOS 시스템 지연 대응)
        Task {
            try? await Task.sleep(for: .seconds(0.2))
            WidgetCenter.shared.reloadTimelines(ofKind: "HaruViewWidget")
            print("🔄 Secondary widget refresh completed")
        }
        
        // 3. 모든 위젯 새로고침도 시도
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            WidgetCenter.shared.reloadAllTimelines()
            print("🔄 All widgets refresh completed")
        }
        
        // 4. 최종 새로고침 (확실하게!)
        Task {
            try? await Task.sleep(for: .seconds(1.0))
            WidgetCenter.shared.reloadTimelines(ofKind: "HaruViewWidget")
            print("🔄 Final widget refresh completed")
        }
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
