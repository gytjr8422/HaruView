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
