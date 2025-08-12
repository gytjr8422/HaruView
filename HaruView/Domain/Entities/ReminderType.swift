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
    /// haruview-reminder-type://ON?includeTime=true 또는 사용자URL?haruview_type=ON&haruview_time=true 형태로 저장
    static func parse(from url: URL?) -> ReminderType {
        guard let url = url else { return .onDate }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        // 1. 기존 방식: haruview-reminder-type:// 체크
        if url.scheme == "haruview-reminder-type", let host = url.host {
            return ReminderType(rawValue: host) ?? .onDate
        }
        
        // 2. 새 방식: 쿼리 파라미터에서 추출
        if let typeValue = components?.queryItems?.first(where: { $0.name == "haruview_type" })?.value {
            return ReminderType(rawValue: typeValue) ?? .onDate
        }
        
        return .onDate // 기본값
    }
    
    /// URL에서 includeTime 정보를 파싱
    static func parseIncludeTime(from url: URL?) -> Bool {
        guard let url = url else { return true }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        // 1. 기존 방식: haruview-reminder-type:// 체크
        if url.scheme == "haruview-reminder-type" {
            let includeTimeValue = components?.queryItems?.first(where: { $0.name == "includeTime" })?.value
            return includeTimeValue == "true"
        }
        
        // 2. 새 방식: 쿼리 파라미터에서 추출
        if let timeValue = components?.queryItems?.first(where: { $0.name == "haruview_time" })?.value {
            return timeValue == "true"
        }
        
        return true // 기본값
    }
    
    /// ReminderType을 URL 형태로 인코딩
    func encodedURL(includeTime: Bool) -> URL? {
        var components = URLComponents()
        components.scheme = "haruview-reminder-type"
        components.host = rawValue
        components.queryItems = [URLQueryItem(name: "includeTime", value: "\(includeTime)")]
        return components.url
    }
    
    /// 기존 호환성을 위한 메서드 (기본값: includeTime = true)
    var encodedURL: URL? {
        return encodedURL(includeTime: true)
    }
    
    /// 실제 사용자 URL과 ReminderType URL을 분리하는 헬퍼 메서드들
    static func extractUserURL(from storedURL: URL?) -> URL? {
        guard let url = storedURL else { return nil }
        
        // haruview-reminder-type:// 스킴이면 사용자 URL이 아님
        if url.scheme == "haruview-reminder-type" { return nil }
        
        // 일반 URL에서 메타데이터 쿼리 제거
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let originalQueryItems = components?.queryItems
        
        components?.queryItems = originalQueryItems?.filter { 
            $0.name != "haruview_type" && $0.name != "haruview_time" 
        }
        
        // 쿼리가 모두 제거되면 nil로 설정
        if components?.queryItems?.isEmpty == true {
            components?.queryItems = nil
        }
        
        return components?.url
    }
    
    static func createStoredURL(userURL: URL?, reminderType: ReminderType, includeTime: Bool) -> URL? {
        if let userURL = userURL {
            // 사용자 URL에 메타데이터 쿼리 추가
            var components = URLComponents(url: userURL, resolvingAgainstBaseURL: false)
            var queryItems = components?.queryItems ?? []
            
            // 기존 메타데이터 쿼리 제거 (중복 방지)
            queryItems = queryItems.filter { $0.name != "haruview_type" && $0.name != "haruview_time" }
            
            // 메타데이터 쿼리 추가
            queryItems.append(URLQueryItem(name: "haruview_type", value: reminderType.rawValue))
            queryItems.append(URLQueryItem(name: "haruview_time", value: "\(includeTime)"))
            
            components?.queryItems = queryItems
            return components?.url
        } else {
            // 사용자 URL이 없으면 기존대로 메타데이터 URL만
            return reminderType.encodedURL(includeTime: includeTime)
        }
    }
    
    /// 기존 호환성을 위한 메서드
    static func createStoredURL(userURL: URL?, reminderType: ReminderType) -> URL? {
        return createStoredURL(userURL: userURL, reminderType: reminderType, includeTime: true)
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
            return String(localized: "매일 아침 9시")
        case .dailyEvening6PM:
            return String(localized: "매일 저녁 6시")
        case .sameDayMorning9AM:
            return String(localized: "당일 아침 9시")
        case .sameDayMorning8AM:
            return String(localized: "당일 아침 8시")
        case .dayBeforeEvening9PM:
            return String(localized: "전날 저녁 9시")
        case .custom:
            return String(localized: "직접 알림 시간을 설정")
        case .none:
            return String(localized: "알림 없음")
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
