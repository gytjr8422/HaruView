//
//  ReminderDTOs.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import SwiftUI

struct ReminderInput {
    let title: String
    let due: Date?
    let includesTime: Bool
    let priority: Int
    let notes: String?
    let url: URL?
    let location: String?
    let alarms: [AlarmInput]
    let calendarId: String?  // 특정 캘린더에 저장하고 싶을 때
    let reminderType: ReminderType // 할일 타입
    let alarmPreset: ReminderAlarmPreset? // 알림 프리셋
    
    /// 사용자가 입력한 notes를 그대로 반환 (메타데이터 없음)
    var finalNotes: String? {
        return notes
    }
    
    /// URL과 ReminderType, includeTime을 조합하여 저장할 URL 생성
    var finalURL: URL? {
        return ReminderType.createStoredURL(userURL: url, reminderType: reminderType, includeTime: includesTime)
    }
    
    /// 최종 알림 목록 (프리셋 + 커스텀 알림)
    var finalAlarms: [AlarmInput] {
        var result = alarms
        
        // 프리셋이 있고 커스텀이 아닌 경우 프리셋 알림 추가
        if let preset = alarmPreset, preset != .custom && preset != .none {
            let presetAlarms = preset.generateAlarms(dueDate: due, reminderType: reminderType)
            result.append(contentsOf: presetAlarms)
        }
        
        return result
    }
}

struct ReminderEdit {
    let id: String
    let title: String
    let due: Date?
    let includesTime: Bool
    let priority: Int
    let notes: String?
    let url: URL?
    let location: String?
    let alarms: [AlarmInput]
    let calendarId: String?
    let reminderType: ReminderType // 할일 타입
    let alarmPreset: ReminderAlarmPreset? // 알림 프리셋
    
    /// 사용자가 입력한 notes를 그대로 반환 (메타데이터 없음)
    var finalNotes: String? {
        return notes
    }
    
    /// URL과 ReminderType, includeTime을 조합하여 저장할 URL 생성
    var finalURL: URL? {
        return ReminderType.createStoredURL(userURL: url, reminderType: reminderType, includeTime: includesTime)
    }
    
    /// 최종 알림 목록 (프리셋 + 커스텀 알림)
    var finalAlarms: [AlarmInput] {
        var result = alarms
        
        // 프리셋이 있고 커스텀이 아닌 경우 프리셋 알림 추가
        if let preset = alarmPreset, preset != .custom && preset != .none {
            let presetAlarms = preset.generateAlarms(dueDate: due, reminderType: reminderType)
            result.append(contentsOf: presetAlarms)
        }
        
        return result
    }
    
    init(id: String, title: String, due: Date?, includesTime: Bool, priority: Int, notes: String?, url: URL?, location: String?, alarms: [AlarmInput], calendarId: String? = nil, reminderType: ReminderType = .onDate, alarmPreset: ReminderAlarmPreset? = nil) {
        self.id = id
        self.title = title
        self.due = due
        self.includesTime = includesTime
        self.priority = priority
        self.notes = notes
        self.url = url
        self.location = location
        self.alarms = alarms
        self.calendarId = calendarId
        self.reminderType = reminderType
        self.alarmPreset = alarmPreset
    }
}

// MARK: - 우선순위 타입 정의
extension ReminderInput {
    enum Priority: Int, CaseIterable {
        case none = 0
        case high = 1
        case medium = 5
        case low = 9
        
        var localizedDescription: String {
            switch self {
            case .none: return "없음".localized()
            case .high: return "높음".localized()
            case .medium: return "보통".localized()
            case .low: return "낮음".localized()
            }
        }
        
        var color: Color {
            switch self {
            case .none: return .secondary
            case .high: return .haruPriorityHigh
            case .medium: return .haruPriorityMedium
            case .low: return .haruPriorityLow
            }
        }
        
        var symbolName: String {
            switch self {
            case .none: return "minus"
            case .high: return "exclamationmark.3"
            case .medium: return "exclamationmark.2"
            case .low: return "exclamationmark"
            }
        }
    }
    
    static let priorities: [Priority] = Priority.allCases
}
