//
//  RepositoryProtocols.swift
//  HaruView
//
//  Created by 김효석 on 4/30/25.
//

import Foundation
import EventKit

// MARK: ‑ Repository Protocols
protocol EventRepositoryProtocol {
    func fetchEvent() async -> Result<[Event], TodayBoardError>
    func add(_ input: EventInput) async -> Result<Void, TodayBoardError>
    func update(_ edit: EventEdit) async -> Result<Void, TodayBoardError>
    func deleteEvent(id: String) async -> Result<Void, TodayBoardError>
}

protocol ReminderRepositoryProtocol {
    func fetchReminder() async -> Result<[Reminder], TodayBoardError>
    func add(_ input: ReminderInput) async -> Result<Void, TodayBoardError>
    func update(_ edit: ReminderEdit) async -> Result<Void, TodayBoardError>
    func toggle(id: String) async -> Result<Void, TodayBoardError>
    func deleteReminder(id: String) async -> Result<Void, TodayBoardError>
}

protocol WeatherRepositoryProtocol {
    func fetchWeather() async -> Result<TodayWeather, TodayBoardError>
}

// MARK: - DTOs
struct EventInput {
    let title: String
    let start: Date
    let end: Date
    let location: String?
    let notes: String?
    let url: URL?
    let alarms: [AlarmInput]
    let recurrenceRule: RecurrenceRuleInput?
    let calendarId: String?  // 특정 캘린더에 저장하고 싶을 때
}

struct EventEdit {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let location: String?
    let notes: String?
    let url: URL?
    let alarms: [AlarmInput]
    let recurrenceRule: RecurrenceRuleInput?
}

// MARK: - 알람 입력 DTO
struct AlarmInput {
    let type: AlarmType
    let trigger: AlarmTrigger
    
    enum AlarmType {
        case display, email, sound
    }
    
    enum AlarmTrigger {
        case relative(TimeInterval)  // 초 단위 (음수: 미리, 양수: 늦게)
        case absolute(Date)          // 절대 시간
        
        var timeInterval: TimeInterval? {
            if case .relative(let interval) = self {
                return interval
            }
            return nil
        }
        
        var absoluteDate: Date? {
            if case .absolute(let date) = self {
                return date
            }
            return nil
        }
    }
    
    var description: String {
        
        switch trigger {
        case .relative(let interval):
            if interval == 0 {
                return "이벤트 시간"
            } else if interval < 0 {
                let minutes = Int(abs(interval) / 60)
                let hours = minutes / 60
                let days = hours / 24
                
                if days > 0 {
                    return "\(days)일 전"
                } else if hours > 0 {
                    return "\(hours)시간 전"
                } else {
                    return "\(minutes)분 전"
                }
            } else {
                let minutes = Int(interval / 60)
                let hours = minutes / 60
                let days = hours / 24
                
                if days > 0 {
                    return "\(days)일 후"
                } else if hours > 0 {
                    return "\(hours)시간 후"
                } else {
                    return "\(minutes)분 후"
                }
            }
        case .absolute(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "\(formatter.string(from: date))"
        }
    }
}

// MARK: - 반복 규칙 입력 DTO
struct RecurrenceRuleInput {
    let frequency: RecurrenceFrequency
    let interval: Int
    let endCondition: EndCondition
    let daysOfWeek: [WeekdayInput]?
    let daysOfMonth: [Int]?
    
    enum RecurrenceFrequency {
        case daily, weekly, monthly, yearly
        
        var ekFrequency: EKRecurrenceFrequency {
            switch self {
            case .daily: return .daily
            case .weekly: return .weekly
            case .monthly: return .monthly
            case .yearly: return .yearly
            }
        }
    }
    
    enum EndCondition: Hashable {
        case never
        case endDate(Date)
        case occurrenceCount(Int)
    }
    
    struct WeekdayInput {
        let dayOfWeek: Int  // 1=일요일, 2=월요일, ..., 7=토요일
        let weekNumber: Int? // nil이면 모든 주
        
        var ekWeekday: EKWeekday {
            switch dayOfWeek {
            case 1: return .sunday
            case 2: return .monday
            case 3: return .tuesday
            case 4: return .wednesday
            case 5: return .thursday
            case 6: return .friday
            case 7: return .saturday
            default: return .sunday
            }
        }
        
        var ekRecurrenceDayOfWeek: EKRecurrenceDayOfWeek {
            if let weekNumber = weekNumber {
                return EKRecurrenceDayOfWeek(ekWeekday, weekNumber: weekNumber)
            } else {
                return EKRecurrenceDayOfWeek(ekWeekday)
            }
        }
        
        // 편의 생성자들
        static func sunday(weekNumber: Int? = nil) -> WeekdayInput {
            WeekdayInput(dayOfWeek: 1, weekNumber: weekNumber)
        }
        
        static func monday(weekNumber: Int? = nil) -> WeekdayInput {
            WeekdayInput(dayOfWeek: 2, weekNumber: weekNumber)
        }
        
        static func tuesday(weekNumber: Int? = nil) -> WeekdayInput {
            WeekdayInput(dayOfWeek: 3, weekNumber: weekNumber)
        }
        
        static func wednesday(weekNumber: Int? = nil) -> WeekdayInput {
            WeekdayInput(dayOfWeek: 4, weekNumber: weekNumber)
        }
        
        static func thursday(weekNumber: Int? = nil) -> WeekdayInput {
            WeekdayInput(dayOfWeek: 5, weekNumber: weekNumber)
        }
        
        static func friday(weekNumber: Int? = nil) -> WeekdayInput {
            WeekdayInput(dayOfWeek: 6, weekNumber: weekNumber)
        }
        
        static func saturday(weekNumber: Int? = nil) -> WeekdayInput {
            WeekdayInput(dayOfWeek: 7, weekNumber: weekNumber)
        }
    }
    
    func toEKRecurrenceRule() -> EKRecurrenceRule {
        var ekEnd: EKRecurrenceEnd?
        
        switch endCondition {
        case .never:
            ekEnd = nil
        case .endDate(let date):
            ekEnd = EKRecurrenceEnd(end: date)
        case .occurrenceCount(let count):
            ekEnd = EKRecurrenceEnd(occurrenceCount: count)
        }
        
        var ekDaysOfWeek: [EKRecurrenceDayOfWeek]?
        if let daysOfWeek = daysOfWeek {
            ekDaysOfWeek = daysOfWeek.map { $0.ekRecurrenceDayOfWeek }
        }
        
        return EKRecurrenceRule(
            recurrenceWith: frequency.ekFrequency,
            interval: interval,
            daysOfTheWeek: ekDaysOfWeek,
            daysOfTheMonth: daysOfMonth?.map { NSNumber(value: $0) },
            monthsOfTheYear: nil,
            weeksOfTheYear: nil,
            daysOfTheYear: nil,
            setPositions: nil,
            end: ekEnd
        )
    }
    
    var description: String {
        var result = ""
        
        if interval > 1 {
            switch frequency {
            case .daily:
                result = "\(interval)일마다"
            case .weekly:
                result = "\(interval)주마다"
            case .monthly:
                result = "\(interval)개월마다"
            case .yearly:
                result = "\(interval)년마다"
            }
        } else {
            switch frequency {
            case .daily:
                result = "매일"
            case .weekly:
                result = "주중"
            case .monthly:
                result = "매월"
            case .yearly:
                result = "매년"
            }
        }
        
//        if let daysOfWeek = daysOfWeek, !daysOfWeek.isEmpty {
//            let dayNames = ["", "일", "월", "화", "수", "목", "금", "토"]
//            let selectedDays = daysOfWeek.compactMap {
//                dayNames.indices.contains($0.dayOfWeek) ? dayNames[$0.dayOfWeek] : nil
//            }
//            result += " (\(selectedDays.joined(separator: ",")))"
//        }
        
        switch endCondition {
        case .never:
            break
        case .endDate(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            result += " - \(formatter.string(from: date))까지"
        case .occurrenceCount(let count):
            result += " - \(count)회"
        }
        
        return result
    }
}

// MARK: - 사전 정의된 알람 설정
extension AlarmInput {
    static let presets: [AlarmInput] = [
        AlarmInput(type: .display, trigger: .relative(0)),           // 이벤트 시간
        AlarmInput(type: .display, trigger: .relative(-5 * 60)),     // 5분 전
        AlarmInput(type: .display, trigger: .relative(-15 * 60)),    // 15분 전
        AlarmInput(type: .display, trigger: .relative(-30 * 60)),    // 30분 전
        AlarmInput(type: .display, trigger: .relative(-60 * 60)),    // 1시간 전
        AlarmInput(type: .display, trigger: .relative(-2 * 60 * 60)), // 2시간 전
        AlarmInput(type: .display, trigger: .relative(-24 * 60 * 60)), // 1일 전
        AlarmInput(type: .display, trigger: .relative(-7 * 24 * 60 * 60)) // 1주일 전
    ]
}

// MARK: - 사전 정의된 반복 규칙
extension RecurrenceRuleInput {
    static let presets: [RecurrenceRuleInput] = [
        // 매일
        RecurrenceRuleInput(frequency: .daily, interval: 1, endCondition: .never, daysOfWeek: nil, daysOfMonth: nil),
        
        // 평일만 (월-금)
        RecurrenceRuleInput(frequency: .weekly, interval: 1, endCondition: .never,
                           daysOfWeek: [
                               .monday(),    // 월
                               .tuesday(),   // 화
                               .wednesday(), // 수
                               .thursday(),  // 목
                               .friday()     // 금
                           ], daysOfMonth: nil),
        
        // 주중
        RecurrenceRuleInput(frequency: .weekly, interval: 1, endCondition: .never, daysOfWeek: nil, daysOfMonth: nil),
        
        // 격주
        RecurrenceRuleInput(frequency: .weekly, interval: 2, endCondition: .never, daysOfWeek: nil, daysOfMonth: nil),
        
        // 매월
        RecurrenceRuleInput(frequency: .monthly, interval: 1, endCondition: .never, daysOfWeek: nil, daysOfMonth: nil),
        
        // 매년
        RecurrenceRuleInput(frequency: .yearly, interval: 1, endCondition: .never, daysOfWeek: nil, daysOfMonth: nil)
    ]
}

struct ReminderInput {
    let title: String
    let due: Date?
    let includesTime: Bool
}

struct ReminderEdit {
    let id: String
    let title: String
    let due: Date?
    let includesTime: Bool
}
