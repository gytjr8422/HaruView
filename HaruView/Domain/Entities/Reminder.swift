//
//  Reminder.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import EventKit

struct Reminder: Identifiable, Equatable {
    let id: String       // EKReminder.calendarItemIdentifier
    let title: String
    let due: Date?
    var isCompleted: Bool
    let priority: Int
    
    // 새로 추가되는 필드들
    let notes: String?
    let url: URL?
    let location: String?
    let hasAlarms: Bool
    let alarms: [ReminderAlarm]
    let calendar: ReminderCalendar
    
    // 할일 타입 (URL에서 파싱)
    var reminderType: ReminderType {
        return ReminderType.parse(from: url)
    }
    
    // 시간 포함 여부 (URL에서 파싱)
    var includeTime: Bool {
        return ReminderType.parseIncludeTime(from: url)
    }
    
    // 사용자가 입력한 실제 URL (ReminderType URL 제외)
    var userURL: URL? {
        return ReminderType.extractUserURL(from: url)
    }
    
    /// 특정 날짜에 이 할일이 표시되어야 하는지 확인
    func shouldDisplay(on date: Date) -> Bool {
        guard let due = due else { return false }
        
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        let dueDate = calendar.startOfDay(for: due)
        
        switch reminderType {
        case .onDate:
            // 특정 날짜에만 표시: 마감일과 정확히 일치할 때만
            return targetDate == dueDate
        case .untilDate:
            // 마감일까지 표시: 오늘부터 마감일까지
            return targetDate <= dueDate
        }
    }
}

// MARK: - 리마인더 알람
struct ReminderAlarm: Identifiable, Equatable {
    let id = UUID()
    let relativeOffset: TimeInterval  // 초 단위 (음수: 미리, 양수: 늦게)
    let absoluteDate: Date?           // 절대 시간 알람
    let type: AlarmType
    
    enum AlarmType: String, CaseIterable {
        case display = "display"
        case email = "email"
        case sound = "sound"
        
        var localizedDescription: String {
            switch self {
            case .display: return "알림".localized()
            case .email: return "이메일".localized()
            case .sound: return "소리".localized()
            }
        }
    }
    
    var timeDescription: String {
        if let absoluteDate = absoluteDate {
            return DateFormatter.localizedString(from: absoluteDate, dateStyle: .short, timeStyle: .short)
        }
        
        let minutes = Int(abs(relativeOffset) / 60)
        let hours = minutes / 60
        let days = hours / 24
        
        if relativeOffset == 0 {
            return "이벤트 시간".localized()
        } else if relativeOffset < 0 {
            if days > 0 {
                return String(format: "%d일 전".localized(), days)
            } else if hours > 0 {
                return String(format: "%d시간 전".localized(), hours)
            } else {
                return String(format: "%d분 전".localized(), minutes)
            }
        } else {
            if days > 0 {
                return String(format: "%d일 후".localized(), days)
            } else if hours > 0 {
                return String(format: "%d시간 후".localized(), hours)
            } else {
                return String(format: "%d분 후".localized(), minutes)
            }
        }
    }
}

// MARK: - 리마인더 캘린더 정보
struct ReminderCalendar: Identifiable, Equatable {
    let id: String
    let title: String
    let color: CGColor
    let type: CalendarType
    let isReadOnly: Bool
    let allowsContentModifications: Bool
    let source: CalendarSource
    
    enum CalendarType: String {
        case local = "local"
        case calDAV = "calDAV"
        case exchange = "exchange"
        case subscription = "subscription"
        case birthday = "birthday"
        
        var localizedDescription: String {
            switch self {
            case .local: return "로컬".localized()
            case .calDAV: return "CalDAV".localized()
            case .exchange: return "Exchange".localized()
            case .subscription: return "구독".localized()
            case .birthday: return "생일".localized()
            }
        }
    }
    
    struct CalendarSource: Equatable {
        let title: String
        let type: SourceType
        
        enum SourceType: String {
            case local = "local"
            case exchange = "exchange"
            case calDAV = "calDAV"
            case mobileMe = "mobileMe"
            case subscribed = "subscribed"
            case birthdays = "birthdays"
        }
    }
}
