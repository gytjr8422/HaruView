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
            return "특정 날짜에"
        case .untilDate:
            return "마감일까지"
        }
    }
    
    /// 상세 설명
    var description: String {
        switch self {
        case .onDate:
            return "해당 날짜에만 표시됩니다"
        case .untilDate:
            return "마감일까지 매일 표시됩니다"
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
    
    /// notes 필드에 저장할 메타데이터 형태
    var metadataString: String {
        return "HARUVIEW_TYPE:\(rawValue)"
    }
    
    /// notes에서 타입 파싱
    static func parse(from notes: String?) -> ReminderType {
        guard let notes = notes else { return .onDate }
        
        if notes.contains("HARUVIEW_TYPE:UNTIL") {
            return .untilDate
        } else if notes.contains("HARUVIEW_TYPE:ON") {
            return .onDate
        }
        
        // 기본값은 기존 동작과 동일하게
        return .onDate
    }
}