//
//  ReminderType.swift
//  HaruView
//
//  Created by Claude on 8/8/25.
//

import Foundation

/// 할일의 타입을 구분하는 열거형
enum ReminderType: String, CaseIterable, Codable {
    case onDate = "ON"        // 특정 날짜에 해야할 일
    case untilDate = "UNTIL"  // 마감일까지 해야할 일
    
    /// 사용자에게 보여줄 텍스트
    var displayText: String {
        switch self {
        case .onDate:
            return String(localized: "특정 날짜에")
        case .untilDate:
            return String(localized: "마감일까지")
        }
    }
    
    /// 상세 설명
    var description: String {
        switch self {
        case .onDate:
            return String(localized: "해당 날짜에만 표시됩니다")
        case .untilDate:
            return String(localized: "마감일까지 매일 표시됩니다")
        }
    }
    
    /// SF Symbol 아이콘
    var iconName: String {
        switch self {
        case .onDate:
            return "calendar.circle"
        case .untilDate:
            return "calendar.badge.clock"
        }
    }
    
    /// URL에서 ReminderType을 파싱 (메타데이터 대신 사용)
    /// haruview-reminder-type://ON 또는 haruview-reminder-type://UNTIL 형태로 저장
    static func parse(from url: URL?) -> ReminderType {
        guard let url = url,
              url.scheme == "haruview-reminder-type",
              let host = url.host else { return .onDate }
        
        return ReminderType(rawValue: host) ?? .onDate
    }
    
    /// ReminderType을 URL 형태로 인코딩
    var encodedURL: URL? {
        return URL(string: "haruview-reminder-type://\(rawValue)")
    }
    
    /// 실제 사용자 URL과 ReminderType URL을 분리하는 헬퍼 메서드들
    static func extractUserURL(from storedURL: URL?) -> URL? {
        guard let url = storedURL,
              url.scheme != "haruview-reminder-type" else { return nil }
        return url
    }
    
    static func createStoredURL(userURL: URL?, reminderType: ReminderType) -> URL? {
        // 사용자가 실제 URL을 입력한 경우 그것을 사용, 아니면 ReminderType URL만 저장
        return userURL ?? reminderType.encodedURL
    }
}

// MARK: - 할일 알림 프리셋
enum ReminderAlarmPreset: String, CaseIterable, Codable {
    // "없음" 선택 시 (마감일 없는 할일)
    case dailyMorning9AM = "daily_9am"        // 매일 오전 9시
    case dailyEvening6PM = "daily_6pm"        // 매일 오후 6시
    
    // "날짜만" 선택 시
    case sameDayMorning9AM = "same_day_9am"   // 당일 오전 9시
    case sameDayMorning8AM = "same_day_8am"   // 당일 오전 8시
    case dayBeforeEvening9PM = "day_before_9pm" // 전날 오후 9시
    
    // 공통
    case custom = "custom"                    // 사용자 설정 (기존 방식)
    case none = "none"                       // 알림 없음
    
    /// 사용자에게 보여줄 텍스트
    var displayText: String {
        switch self {
        case .dailyMorning9AM:
            return String(localized: "매일 오전 9시")
        case .dailyEvening6PM:
            return String(localized: "매일 오후 6시")
        case .sameDayMorning9AM:
            return String(localized: "당일 오전 9시")
        case .sameDayMorning8AM:
            return String(localized: "당일 오전 8시")
        case .dayBeforeEvening9PM:
            return String(localized: "전날 오후 9시")
        case .custom:
            return String(localized: "사용자 설정")
        case .none:
            return String(localized: "알림 없음")
        }
    }
    
    /// 상세 설명
    var description: String {
        switch self {
        case .dailyMorning9AM:
            return String(localized: "매일 아침 9시에 알림")
        case .dailyEvening6PM:
            return String(localized: "매일 저녁 6시에 알림")
        case .sameDayMorning9AM:
            return String(localized: "할일 당일 아침 9시에 알림")
        case .sameDayMorning8AM:
            return String(localized: "할일 당일 아침 8시에 알림")
        case .dayBeforeEvening9PM:
            return String(localized: "할일 전날 저녁 9시에 알림")
        case .custom:
            return String(localized: "직접 알림 시간을 설정")
        case .none:
            return String(localized: "알림을 받지 않음")
        }
    }
    
    /// SF Symbol 아이콘
    var iconName: String {
        switch self {
        case .dailyMorning9AM, .sameDayMorning9AM, .sameDayMorning8AM:
            return "sun.max"
        case .dailyEvening6PM, .dayBeforeEvening9PM:
            return "moon"
        case .custom:
            return "slider.horizontal.3"
        case .none:
            return "bell.slash"
        }
    }
    
    /// 마감일 타입별로 사용 가능한 프리셋들
    static func availablePresets(for dueDateMode: DueDateMode) -> [ReminderAlarmPreset] {
        switch dueDateMode {
        case .none:
            return [.dailyMorning9AM, .dailyEvening6PM, .custom, .none]
        case .dateOnly:
            return [.sameDayMorning9AM, .sameDayMorning8AM, .dayBeforeEvening9PM, .custom, .none]
        case .dateTime:
            return [.sameDayMorning9AM, .sameDayMorning8AM, .dayBeforeEvening9PM, .custom, .none]
        }
    }
    
    /// 프리셋에서 실제 AlarmInput 생성
    func generateAlarms(dueDate: Date?, reminderType: ReminderType?) -> [AlarmInput] {
        switch self {
        case .dailyMorning9AM:
            return createDailyAlarm(hour: 9)
        case .dailyEvening6PM:
            return createDailyAlarm(hour: 18)
        case .sameDayMorning9AM:
            return createSameDayAlarm(dueDate: dueDate, hour: 9)
        case .sameDayMorning8AM:
            return createSameDayAlarm(dueDate: dueDate, hour: 8)
        case .dayBeforeEvening9PM:
            return createDayBeforeAlarm(dueDate: dueDate, hour: 21)
        case .custom, .none:
            return []
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func createDailyAlarm(hour: Int) -> [AlarmInput] {
        // 매일 반복 알림 (상대 시간으로 구현)
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = 0
        
        guard let targetTime = calendar.date(from: components) else { return [] }
        
        return [AlarmInput(
            type: .display,
            trigger: .absolute(targetTime)
        )]
    }
    
    private func createSameDayAlarm(dueDate: Date?, hour: Int) -> [AlarmInput] {
        guard let dueDate = dueDate else { return [] }
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: dueDate)
        components.hour = hour
        components.minute = 0
        
        guard let alarmTime = calendar.date(from: components) else { return [] }
        
        return [AlarmInput(
            type: .display,
            trigger: .absolute(alarmTime)
        )]
    }
    
    private func createDayBeforeAlarm(dueDate: Date?, hour: Int) -> [AlarmInput] {
        guard let dueDate = dueDate else { return [] }
        
        let calendar = Calendar.current
        guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: dueDate) else { return [] }
        
        var components = calendar.dateComponents([.year, .month, .day], from: dayBefore)
        components.hour = hour
        components.minute = 0
        
        guard let alarmTime = calendar.date(from: components) else { return [] }
        
        return [AlarmInput(
            type: .display,
            trigger: .absolute(alarmTime)
        )]
    }
}

/// 마감일 설정 모드 (ReminderDueDatePicker에서 사용)
enum DueDateMode: CaseIterable {
    case none, dateOnly, dateTime
    
    var title: String {
        switch self {
        case .none: return String(localized: "없음")
        case .dateOnly: return String(localized: "날짜만")
        case .dateTime: return String(localized: "날짜+시간")
        }
    }
}
