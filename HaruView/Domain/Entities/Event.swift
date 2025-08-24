//
//  Event.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import EventKit

// MARK: - 반복 일정 편집 범위
enum EventEditSpan {
    case thisEventOnly
    case futureEvents
    
    var ekSpan: EKSpan {
        switch self {
        case .thisEventOnly: return .thisEvent
        case .futureEvents: return .futureEvents
        }
    }
}

// MARK: - 캘린더 일정
struct Event: Identifiable, Equatable {
    let id: String       // EKEventIdentifier
    let title: String
    let start: Date
    let end: Date
    let calendarTitle: String
    let calendarColor: CGColor
    let location: String?
    let notes: String?
    
    // 새로 추가되는 필드들
    let url: URL?
    let hasAlarms: Bool
    let alarms: [EventAlarm]
    let hasRecurrence: Bool
    let recurrenceRule: EventRecurrenceRule?
    let calendar: EventCalendar
    let structuredLocation: EventStructuredLocation?
}

// MARK: - 이벤트 알람
struct EventAlarm: Identifiable, Equatable {
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

// MARK: - 이벤트 반복 규칙
struct EventRecurrenceRule: Equatable {
    let frequency: RecurrenceFrequency
    let interval: Int
    let endDate: Date?
    let occurrenceCount: Int?
    let daysOfWeek: [RecurrenceWeekday]?
    let daysOfMonth: [Int]?
    let weeksOfYear: [Int]?
    let monthsOfYear: [Int]?
    let setPositions: [Int]?
    
    enum RecurrenceFrequency: String, CaseIterable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case yearly = "yearly"
        
        var localizedDescription: String {
            switch self {
            case .daily: return "매일".localized()
            case .weekly: return "매주".localized()
            case .monthly: return "매월".localized()
            case .yearly: return "매년".localized()
            }
        }
    }
    
    struct RecurrenceWeekday: Equatable {
        let dayOfWeek: Int  // 1=일요일, 2=월요일, ..., 7=토요일
        let weekNumber: Int? // nil이면 모든 주, 양수면 첫째/둘째 등, 음수면 마지막/마지막 전 등
        
        var localizedDescription: String {
            let dayNames = [
                "일요일".localized(),
                "월요일".localized(),
                "화요일".localized(),
                "수요일".localized(),
                "목요일".localized(),
                "금요일".localized(),
                "토요일".localized()
            ]
            
            guard dayOfWeek >= 1 && dayOfWeek <= 7 else { return "" }
            let dayName = dayNames[dayOfWeek - 1]
            
            if let weekNumber = weekNumber {
                if weekNumber > 0 {
                    return String(format: "매월 %d번째 %@".localized(), weekNumber, dayName)
                } else {
                    return String(format: "매월 마지막 %@".localized(), dayName)
                }
            } else {
                return dayName
            }
        }
    }
    
    var description: String {
        var components: [String] = []
        
        if interval > 1 {
            components.append(String(format: "%d%@ 마다".localized(), interval, frequency.localizedDescription))
        } else {
            components.append(frequency.localizedDescription)
        }
        
        if let daysOfWeek = daysOfWeek, !daysOfWeek.isEmpty {
            let dayNames = daysOfWeek.map { $0.localizedDescription }
            components.append(dayNames.joined(separator: ", "))
        }
        
        if let endDate = endDate {
            let formatter = DateFormatterFactory.formatter(for: .mediumDate)
            components.append(String(format: "%@까지".localized(), formatter.string(from: endDate)))
        } else if let count = occurrenceCount {
            components.append(String(format: "%d회".localized(), count))
        }
        
        return components.joined(separator: " ")
    }
}

// MARK: - 이벤트 캘린더 정보
struct EventCalendar: Identifiable, Equatable {
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

// MARK: - 구조화된 위치 정보
struct EventStructuredLocation: Equatable {
    let title: String?
    let geoLocation: GeoLocation?
    let radius: Double?
    
    struct GeoLocation: Equatable {
        let latitude: Double
        let longitude: Double
        
        var coordinate: String {
            return String(format: "%.6f, %.6f", latitude, longitude)
        }
    }
    
    var displayText: String {
        if let title = title, !title.isEmpty {
            if let geo = geoLocation {
                return "\(title) (\(geo.coordinate))"
            } else {
                return title
            }
        } else if let geo = geoLocation {
            return geo.coordinate
        } else {
            return "위치 정보 없음".localized()
        }
    }
}

/// 반복 일정 삭제 범위
enum EventDeletionSpan {
    case thisEventOnly      // 이 이벤트만 삭제
    case futureEvents       // 이후 모든 이벤트 삭제 (현재 포함)
    
    var localizedDescription: String {
        switch self {
        case .thisEventOnly:
            return "이 이벤트만".localized()
        case .futureEvents:
            return "이후 모든 이벤트".localized()
        }
    }
    
    /// EventKit의 EKSpan으로 변환
    var ekSpan: EKSpan {
        switch self {
        case .thisEventOnly:
            return .thisEvent
        case .futureEvents:
            return .futureEvents
        }
    }
}
