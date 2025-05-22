//
//  Entities.swift
//  HaruView
//
//  Created by 김효석 on 4/30/25.
//

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
}

// MARK: - 미리알림
struct Reminder: Identifiable, Equatable {
    let id: String       // EKReminder.calendarItemIdentifier
    let title: String
    let due: Date?
    var isCompleted: Bool
    let priority: Int
}


// MARK: - 날씨
struct WeatherSnapshot: Equatable {
    let temperature:     Double               // °C
    let humidity:        Double               // 0–1
    let precipitation:   Double               // mm/h
    let windSpeed:       Double               // m/s
    let condition:       Condition            // 상위 카테고리
    let symbolName:      String               // WeatherKit 원본
    let updatedAt:       Date
    
    enum Condition: String {
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
            return isDay ? LinearGradient(colors: [hex("FDF6E3")], startPoint: .top, endPoint: .bottom)
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
