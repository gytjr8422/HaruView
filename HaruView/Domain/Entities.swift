//
//  Entities.swift
//  HaruView
//
//  Created by 김효석 on 4/30/25.
//

import EventKit
import SwiftUI
import WeatherKit

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
            case .display: return String(localized: "알림")
            case .email: return String(localized: "이메일")
            case .sound: return String(localized: "소리")
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
            return String(localized: "이벤트 시간")
        } else if relativeOffset < 0 {
            if days > 0 {
                return String(format: NSLocalizedString("%d일 전", comment: ""), days)
            } else if hours > 0 {
                return String(format: NSLocalizedString("%d시간 전", comment: ""), hours)
            } else {
                return String(format: NSLocalizedString("%d분 전", comment: ""), minutes)
            }
        } else {
            if days > 0 {
                return String(format: NSLocalizedString("%d일 후", comment: ""), days)
            } else if hours > 0 {
                return String(format: NSLocalizedString("%d시간 후", comment: ""), hours)
            } else {
                return String(format: NSLocalizedString("%d분 후", comment: ""), minutes)
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
            case .daily: return String(localized: "매일")
            case .weekly: return String(localized: "매주")
            case .monthly: return String(localized: "매월")
            case .yearly: return String(localized: "매년")
            }
        }
    }
    
    struct RecurrenceWeekday: Equatable {
        let dayOfWeek: Int  // 1=일요일, 2=월요일, ..., 7=토요일
        let weekNumber: Int? // nil이면 모든 주, 양수면 첫째/둘째 등, 음수면 마지막/마지막 전 등
        
        var localizedDescription: String {
            let dayNames = [
                String(localized: "일요일"),
                String(localized: "월요일"),
                String(localized: "화요일"),
                String(localized: "수요일"),
                String(localized: "목요일"),
                String(localized: "금요일"),
                String(localized: "토요일")
            ]
            
            guard dayOfWeek >= 1 && dayOfWeek <= 7 else { return "" }
            let dayName = dayNames[dayOfWeek - 1]
            
            if let weekNumber = weekNumber {
                if weekNumber > 0 {
                    return String(format: NSLocalizedString("매월 %d번째 %@", comment: ""), weekNumber, dayName)
                } else {
                    return String(format: NSLocalizedString("매월 마지막 %@", comment: ""), dayName)
                }
            } else {
                return dayName
            }
        }
    }
    
    var description: String {
        var components: [String] = []
        
        if interval > 1 {
            components.append(String(format: NSLocalizedString("%d%@ 마다", comment: ""), interval, frequency.localizedDescription))
        } else {
            components.append(frequency.localizedDescription)
        }
        
        if let daysOfWeek = daysOfWeek, !daysOfWeek.isEmpty {
            let dayNames = daysOfWeek.map { $0.localizedDescription }
            components.append(dayNames.joined(separator: ", "))
        }
        
        if let endDate = endDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            components.append(String(format: NSLocalizedString("%@까지", comment: ""), formatter.string(from: endDate)))
        } else if let count = occurrenceCount {
            components.append(String(format: NSLocalizedString("%d회", comment: ""), count))
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
            case .local: return String(localized: "로컬")
            case .calDAV: return String(localized: "CalDAV")
            case .exchange: return String(localized: "Exchange")
            case .subscription: return String(localized: "구독")
            case .birthday: return String(localized: "생일")
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
            return String(localized: "위치 정보 없음")
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
            return String(localized: "이 이벤트만")
        case .futureEvents:
            return String(localized: "이후 모든 이벤트")
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


// MARK: - 미리알림
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
            case .display: return String(localized: "알림")
            case .email: return String(localized: "이메일")
            case .sound: return String(localized: "소리")
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
            return String(localized: "이벤트 시간")
        } else if relativeOffset < 0 {
            if days > 0 {
                return String(format: NSLocalizedString("%d일 전", comment: ""), days)
            } else if hours > 0 {
                return String(format: NSLocalizedString("%d시간 전", comment: ""), hours)
            } else {
                return String(format: NSLocalizedString("%d분 전", comment: ""), minutes)
            }
        } else {
            if days > 0 {
                return String(format: NSLocalizedString("%d일 후", comment: ""), days)
            } else if hours > 0 {
                return String(format: NSLocalizedString("%d시간 후", comment: ""), hours)
            } else {
                return String(format: NSLocalizedString("%d분 후", comment: ""), minutes)
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
            case .local: return String(localized: "로컬")
            case .calDAV: return String(localized: "CalDAV")
            case .exchange: return String(localized: "Exchange")
            case .subscription: return String(localized: "구독")
            case .birthday: return String(localized: "생일")
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


// MARK: - 날씨
struct HourlyForecast: Identifiable, Codable, Equatable {
    var id = UUID()
    let date: Date         // 예: 오후 3시
    let symbol: String     // SF Symbol 이름
    let temperature: Double
}

struct WeatherSnapshot: Codable, Equatable {
    let temperature:     Double               // °C
    let humidity:        Double               // 0–1
    let precipitation:   Double               // mm/h
    let windSpeed:       Double               // m/s
    let condition:       Condition            // 상위 카테고리
    let symbolName:      String               // WeatherKit 원본
    let updatedAt:       Date
    let hourlies: [HourlyForecast]       // 6개
    let tempMax: Double                  // 일 최고
    let tempMin: Double                  // 일 최저
    
    enum Condition: String, Codable {
        case clear, mostlyClear, partlyCloudy, mostlyCloudy, cloudy
        case rain, drizzle, showers
        case snow, flurries
        case thunderstorms
        case foggy, haze, smoke
        case windy, breezy
        case hot, cold
        case blizzard, hurricane, tropicalStorm
        
        init(apiName: String) {
            switch apiName {
                // 맑음/구름
            case "Clear":                    self = .clear
            case "MostlyClear":              self = .mostlyClear
            case "PartlyCloudy":             self = .partlyCloudy
            case "MostlyCloudy":             self = .mostlyCloudy
            case "Cloudy":                   self = .cloudy
                
                // 비
            case "Rain":                     self = .rain
            case "Drizzle":                  self = .drizzle
            case "Showers", "SunShowers",
                "HeavyRain", "Hail":         self = .showers
                
                // 눈
            case "Snow", "HeavySnow",
                "SunFlurries":               self = .snow
            case "Flurries", "WintryMix",
                "Sleet":                     self = .flurries
                
                // 뇌우
            case "Thunderstorms",
                "IsolatedThunderstorms",
                "ScatteredThunderstorms",
                "StrongStorms":              self = .thunderstorms
                
                // 가시성 저하
            case "Foggy":                    self = .foggy
            case "Haze":                     self = .haze
            case "Smoky":                    self = .smoke
                
                // 바람
            case "Windy", "BlowingDust",
                "BlowingSnow":               self = .windy
            case "Breezy":                   self = .breezy
                
                // 온도
            case "Hot":                      self = .hot
            case "Frigid", "FreezingDrizzle",
                "FreezingRain":              self = .cold
                
                // 극한
            case "Blizzard":                 self = .blizzard
            case "Hurricane":                self = .hurricane
            case "TropicalStorm":            self = .tropicalStorm
                
            default:                         self = .clear
            }
        }
        
        var localizedDescription: String {
            if Locale.current.language.languageCode?.identifier == "ko" {
                switch self {
                case .clear:            return "맑음"
                case .mostlyClear:      return "대체로 맑음"
                case .partlyCloudy:     return "부분적으로 흐림"
                case .mostlyCloudy:     return "대체로 흐림"
                case .cloudy:           return "흐림"

                case .rain:             return "비"
                case .drizzle:          return "이슬비"
                case .showers:          return "소나기"

                case .snow:             return "눈"
                case .flurries:         return "눈 날림"

                case .thunderstorms:    return "뇌우"

                case .foggy:            return "안개"
                case .haze:             return "실안개"
                case .smoke:            return "연기"

                case .windy:            return "강한 바람"
                case .breezy:           return "산들바람"

                case .hot:              return "무더위"
                case .cold:             return "한파"

                case .blizzard:         return "눈보라"
                case .hurricane:        return "허리케인"
                case .tropicalStorm:    return "열대폭풍"
                }
            } else {
                switch self {
                case .clear:            return "Clear"
                case .mostlyClear:      return "Mostly Clear"
                case .partlyCloudy:     return "Partly Cloudy"
                case .mostlyCloudy:     return "Mostly Cloudy"
                case .cloudy:           return "Cloudy"

                case .rain:             return "Rain"
                case .drizzle:          return "Drizzle"
                case .showers:          return "Showers"

                case .snow:             return "Snow"
                case .flurries:         return "Flurries"

                case .thunderstorms:    return "Thunderstorms"

                case .foggy:            return "Fog"
                case .haze:             return "Haze"
                case .smoke:            return "Smoke"

                case .windy:            return "Windy"
                case .breezy:           return "Breezy"

                case .hot:              return "Hot"
                case .cold:             return "Cold"

                case .blizzard:         return "Blizzard"
                case .hurricane:        return "Hurricane"
                case .tropicalStorm:    return "Tropical Storm"
                }
            }
        }
    }
    
}

extension WeatherSnapshot.Condition {
    /// 상태 + 현재 시간 → 배경
    func background(for date: Date = Date()) -> LinearGradient {
        // 고정된 시간 범위로 주간/야간 판단 (6:00 ~ 18:00를 주간으로 설정)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        let isDay = hour >= 6 && hour < 18
        
        // 일출/일몰 주변 시간 (아침 6~7시, 저녁 17~18시)
        let isEdge = (hour >= 6 && hour < 7) || (hour >= 17 && hour < 18)
        
        func hex(_ v: String) -> Color { Color(hexCode: v) }
        
        switch self {
        // 맑음 관련 케이스
        case .clear, .mostlyClear:
            if isEdge {
                return LinearGradient(colors: [hex("FFD6A5"), hex("FFB5A7")], startPoint: .top, endPoint: .bottom)
            }
            return isDay ? LinearGradient(colors: [hex("E1F3FF"), hex("A0D8EF")], startPoint: .top, endPoint: .bottom)
                         : LinearGradient(colors: [hex("1C1F33")], startPoint: .top, endPoint: .bottom)
        
        // 구름 관련 케이스
        case .partlyCloudy, .mostlyCloudy:
            return isDay ? LinearGradient(colors: [hex("E8ECEF")], startPoint: .top, endPoint: .bottom)
                         : LinearGradient(colors: [hex("3A3F52")], startPoint: .top, endPoint: .bottom)
        case .cloudy:
            return LinearGradient(colors: [hex("BFC5C9")], startPoint: .top, endPoint: .bottom)
        
        // 비 관련 케이스
        case .rain, .drizzle, .showers:
            return isDay ? LinearGradient(colors: [hex("A9C5D3")], startPoint: .top, endPoint: .bottom)
                         : LinearGradient(colors: [hex("4C5C68")], startPoint: .top, endPoint: .bottom)
        
        // 눈 관련 케이스
        case .snow, .flurries:
            return LinearGradient(colors: [hex("F4F9FF")], startPoint: .top, endPoint: .bottom)
        
        // 뇌우 관련 케이스
        case .thunderstorms:
            return LinearGradient(colors: [hex("2F2F2F")], startPoint: .top, endPoint: .bottom)
        
        // 가시성 관련 케이스
        case .foggy, .haze, .smoke:
            return LinearGradient(colors: [hex("DCDCDC")], startPoint: .top, endPoint: .bottom)
        
        // 바람 관련 케이스
        case .windy, .breezy:
            return LinearGradient(colors: [hex("D6EADF")], startPoint: .top, endPoint: .bottom)
        
        // 온도 관련 케이스
        case .hot:
            return LinearGradient(colors: [hex("FFE2B0")], startPoint: .top, endPoint: .bottom)
        case .cold:
            return LinearGradient(colors: [hex("D2E6F3")], startPoint: .top, endPoint: .bottom)
            
        // 극한 날씨 케이스
        case .blizzard:
            return LinearGradient(colors: [hex("E1E5EA")], startPoint: .top, endPoint: .bottom)
        case .hurricane, .tropicalStorm:
            return LinearGradient(colors: [hex("52616B")], startPoint: .top, endPoint: .bottom)
        }
    }
}

extension WeatherSnapshot.Condition {
    func symbolName(for date: Date = Date()) -> String {
        let isDay = Calendar.current.component(.hour, from: date) >= 6 &&
                    Calendar.current.component(.hour, from: date) < 18

        switch self {
        case .clear, .mostlyClear:
            return isDay ? "sun.max" : "moon.stars"

        case .partlyCloudy, .mostlyCloudy:
            return isDay ? "cloud.sun" : "cloud.moon"

        case .cloudy:
            return "cloud"

        case .rain, .showers, .drizzle:
            return "cloud.rain"

        case .snow, .flurries:
            return "cloud.snow"

        case .thunderstorms:
            return "cloud.bolt.rain"

        case .foggy:
            return "cloud.fog"

        case .haze:
            return isDay ? "sun.haze" : "moon.haze"

        case .smoke:
            return "smoke"

        case .windy, .breezy:
            return "wind"

        case .hot:
            return "thermometer.sun"

        case .cold:
            return "thermometer.snowflake"

        case .blizzard:
            return "wind.snow"

        case .hurricane, .tropicalStorm:
            return "hurricane"
        }
    }
}

struct SymbolColorTheme {
    let renderingMode: SymbolRenderingMode
    let styles: [Color] // 순서대로 계층에 대응됨
}

extension WeatherSnapshot.Condition {
    func symbolTheme(for date: Date = Date()) -> SymbolColorTheme {
        switch self {
        case .clear, .mostlyClear:
            return .init(renderingMode: .monochrome,
                         styles: [Color(hexCode: "FDB813")]) // 햇빛 노란색

        case .partlyCloudy, .mostlyCloudy:
            return .init(renderingMode: .palette,
                         styles: [Color.gray, Color(hexCode: "FDB813")]) // 구름 + 해

        case .cloudy:
            return .init(renderingMode: .monochrome,
                         styles: [Color(hexCode: "9CA3AF")])

        case .rain, .drizzle, .showers:
            return .init(renderingMode: .monochrome,
                         styles: [Color(hexCode: "5DADE2")])

        case .snow, .flurries:
            return .init(renderingMode: .monochrome,
                         styles: [Color(hexCode: "6EC1E4")])

        case .thunderstorms:
            return .init(renderingMode: .palette,
                         styles: [Color.gray, Color(hexCode: "F4D03F"), Color(hexCode: "3498DB")]) // 구름, 번개, 비

        case .foggy:
            return .init(renderingMode: .monochrome,
                         styles: [Color(hexCode: "AAB2BD")])

        case .haze:
            return .init(renderingMode: .monochrome,
                         styles: [Color(hexCode: "F4C27A")])

        case .smoke:
            return .init(renderingMode: .monochrome,
                         styles: [Color(hexCode: "B0B0B0")])

        case .windy, .breezy:
            return .init(renderingMode: .monochrome,
                         styles: [Color(hexCode: "58D68D")])

        case .hot:
            return .init(renderingMode: .monochrome,
                         styles: [Color(hexCode: "FF5733")]) // 붉은 오렌지

        case .cold:
            return .init(renderingMode: .monochrome,
                         styles: [Color(hexCode: "3498DB")]) // 차가운 파랑

        case .blizzard:
            return .init(renderingMode: .monochrome,
                         styles: [Color(hexCode: "AED6F1")])

        case .hurricane, .tropicalStorm:
            return .init(renderingMode: .monochrome,
                         styles: [Color(hexCode: "5DADE2")])
        }
    }
}

extension String {
    func withFillIfAvailable() -> String {
        let fillableSymbols: Set<String> = [
            "sun.max",
            "moon.stars",
            "cloud",
            "cloud.sun",
            "cloud.moon",
            "cloud.rain",
            "cloud.snow",
            "cloud.bolt.rain",
            "cloud.fog",
            "cloud.drizzle",
            "cloud.sun.rain",
            "cloud.moon.rain",
            "sun.haze",
            "moon.haze",
            "thermometer.sun",
            "thermometer.snowflake",
            "wind.snow",
            "hurricane",
            "smoke",
            "wind"
        ]
        
        guard !self.hasSuffix(".fill") else { return self }
        let fillable: Set<String> = fillableSymbols
        return fillable.contains(self) ? self + ".fill" : self
    }
}


// MARK: - 한눈 요약(일정/미리알림)
struct TodayOverview: Equatable {
    let events: [Event]
    var reminders: [Reminder]
    
    static let placeholder = TodayOverview(
        events: [],
        reminders: []
    )
}

struct TodayWeather {
    let snapshot:  WeatherSnapshot
    let placeName: String
}


extension Date {
    /// 주어진 날짜(기본: 오늘)의 특정 시각을 생성
    static func at(hour: Int, minute: Int,
                   on base: Date = Date(),
                   calendar: Calendar = .current) -> Date? {
        let baseComps = calendar.dateComponents([.year, .month, .day], from: base)
        var comps = DateComponents()
        comps.year   = baseComps.year
        comps.month  = baseComps.month
        comps.day    = baseComps.day
        comps.hour   = hour
        comps.minute = minute
        return calendar.date(from: comps)
    }
}
