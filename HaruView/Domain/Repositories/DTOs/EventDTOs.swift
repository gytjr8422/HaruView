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
    let editSpan: EventEditSpan
    let calendarId: String?
    
    init(id: String, title: String, start: Date, end: Date, location: String?, notes: String?, url: URL?, alarms: [AlarmInput], recurrenceRule: RecurrenceRuleInput?, editSpan: EventEditSpan = .thisEventOnly, calendarId: String? = nil) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.location = location
        self.notes = notes
        self.url = url
        self.alarms = alarms
        self.recurrenceRule = recurrenceRule
        self.editSpan = editSpan
        self.calendarId = calendarId
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
                result = "\(interval)일마다".localized(with: interval)
            case .weekly:
                result = "\(interval)주마다".localized(with: interval)
            case .monthly:
                result = "\(interval)개월마다".localized(with: interval)
            case .yearly:
                result = "\(interval)년마다".localized(with: interval)
            }
        } else {
            switch frequency {
            case .daily:
                result = "매일".localized()
            case .weekly:
                // 평일(월-금)인지 확인
                if let daysOfWeek,
                   daysOfWeek.count == 5,
                   daysOfWeek.contains(where: { $0.dayOfWeek == 2 }) && // 월요일
                   daysOfWeek.contains(where: { $0.dayOfWeek == 3 }) && // 화요일
                   daysOfWeek.contains(where: { $0.dayOfWeek == 4 }) && // 수요일
                   daysOfWeek.contains(where: { $0.dayOfWeek == 5 }) && // 목요일
                   daysOfWeek.contains(where: { $0.dayOfWeek == 6 }) {  // 금요일
                    result = "평일만".localized()
                } else {
                    result = "매주".localized()
                }
            case .monthly:
                result = "매월".localized()
            case .yearly:
                result = "매년".localized()
            }
        }
        
        if let daysOfWeek = daysOfWeek, !daysOfWeek.isEmpty {
            // 사용자 설정에 따른 요일 이름 매핑
            let dayNames = ["", "일", "월", "화", "수", "목", "금", "토"]
            let selectedDays = daysOfWeek.compactMap {
                dayNames.indices.contains($0.dayOfWeek) ? dayNames[$0.dayOfWeek] : nil
            }
            
            // 사용자의 주 시작일 설정에 따라 정렬
            let weekStartsOnMonday = UserDefaults.standard.object(forKey: "weekStartsOnMonday") as? Bool ?? false
            let sortedDays = selectedDays.sorted { day1, day2 in
                guard let index1 = dayNames.firstIndex(of: day1),
                      let index2 = dayNames.firstIndex(of: day2) else {
                    return false
                }
                
                let adjustedIndex1 = weekStartsOnMonday ? (index1 == 1 ? 7 : index1 - 1) : index1 - 1
                let adjustedIndex2 = weekStartsOnMonday ? (index2 == 1 ? 7 : index2 - 1) : index2 - 1
                
                return adjustedIndex1 < adjustedIndex2
            }
            
            result += " (\(sortedDays.joined(separator: ",")))"
        }
        
        switch endCondition {
        case .never:
            break
        case .endDate(let date):
            let formatter = DateFormatterFactory.formatter(for: .mediumDate)
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
