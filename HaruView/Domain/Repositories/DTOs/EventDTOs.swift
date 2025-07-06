//
//  EventDTOs.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import EventKit

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
                result = String(localized: "\(interval)일마다")
            case .weekly:
                result = String(localized: "\(interval)주마다")
            case .monthly:
                result = String(localized: "\(interval)개월마다")
            case .yearly:
                result = String(localized: "\(interval)년마다")
            }
        } else {
            switch frequency {
            case .daily:
                result = String(localized: "매일")
            case .weekly:
                // 평일(월-금)인지 확인
                if let daysOfWeek,
                   daysOfWeek.count == 5,
                   daysOfWeek.contains(where: { $0.dayOfWeek == 2 }) && // 월요일
                   daysOfWeek.contains(where: { $0.dayOfWeek == 3 }) && // 화요일
                   daysOfWeek.contains(where: { $0.dayOfWeek == 4 }) && // 수요일
                   daysOfWeek.contains(where: { $0.dayOfWeek == 5 }) && // 목요일
                   daysOfWeek.contains(where: { $0.dayOfWeek == 6 }) {  // 금요일
                    result = String(localized: "평일만")
                } else {
                    result = String(localized: "매주")
                }
            case .monthly:
                result = String(localized: "매월")
            case .yearly:
                result = String(localized: "매년")
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
        
        // 매주
        RecurrenceRuleInput(frequency: .weekly, interval: 1, endCondition: .never, daysOfWeek: nil, daysOfMonth: nil),
        
        // 격주
        RecurrenceRuleInput(frequency: .weekly, interval: 2, endCondition: .never, daysOfWeek: nil, daysOfMonth: nil),
        
        // 매월
        RecurrenceRuleInput(frequency: .monthly, interval: 1, endCondition: .never, daysOfWeek: nil, daysOfMonth: nil),
        
        // 매년
        RecurrenceRuleInput(frequency: .yearly, interval: 1, endCondition: .never, daysOfWeek: nil, daysOfMonth: nil)
    ]
}
