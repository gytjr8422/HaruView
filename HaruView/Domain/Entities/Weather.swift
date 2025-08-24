//
//  Weather.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import SwiftUI
import WeatherKit

struct TodayWeather {
    let snapshot:  WeatherSnapshot
    let placeName: String
}

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
            switch self {
            case .clear:            return "맑음".localized()
            case .mostlyClear:      return "대체로 맑음".localized()
            case .partlyCloudy:     return "부분적으로 흐림".localized()
            case .mostlyCloudy:     return "대체로 흐림".localized()
            case .cloudy:           return "흐림".localized()

            case .rain:             return "비".localized()
            case .drizzle:          return "이슬비".localized()
            case .showers:          return "소나기".localized()

            case .snow:             return "눈".localized()
            case .flurries:         return "눈 날림".localized()

            case .thunderstorms:    return "뇌우".localized()

            case .foggy:            return "안개".localized()
            case .haze:             return "실안개".localized()
            case .smoke:            return "연기".localized()

            case .windy:            return "강한 바람".localized()
            case .breezy:           return "산들바람".localized()

            case .hot:              return "무더위".localized()
            case .cold:             return "한파".localized()

            case .blizzard:         return "눈보라".localized()
            case .hurricane:        return "허리케인".localized()
            case .tropicalStorm:    return "열대폭풍".localized()
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
                         styles: [.haruWeatherSun]) // 햇빛 노란색

        case .partlyCloudy, .mostlyCloudy:
            return .init(renderingMode: .palette,
                         styles: [Color.gray, .haruWeatherSun]) // 구름 + 해

        case .cloudy:
            return .init(renderingMode: .monochrome,
                         styles: [.haruWeatherGray])

        case .rain, .drizzle, .showers:
            return .init(renderingMode: .monochrome,
                         styles: [.haruWeatherBlue])

        case .snow, .flurries:
            return .init(renderingMode: .monochrome,
                         styles: [.haruWeatherLightBlue])

        case .thunderstorms:
            return .init(renderingMode: .palette,
                         styles: [Color.gray, .haruWeatherLightning, .haruWeatherRain]) // 구름, 번개, 비

        case .foggy:
            return .init(renderingMode: .monochrome,
                         styles: [.haruWeatherFog])

        case .haze:
            return .init(renderingMode: .monochrome,
                         styles: [.haruWeatherSand])

        case .smoke:
            return .init(renderingMode: .monochrome,
                         styles: [.haruWeatherAsh])

        case .windy, .breezy:
            return .init(renderingMode: .monochrome,
                         styles: [.haruWeatherTornado])

        case .hot:
            return .init(renderingMode: .monochrome,
                         styles: [.haruWeatherHot]) // 붉은 오렌지

        case .cold:
            return .init(renderingMode: .monochrome,
                         styles: [.haruWeatherRain]) // 차가운 파랑

        case .blizzard:
            return .init(renderingMode: .monochrome,
                         styles: [.haruWeatherWind])

        case .hurricane, .tropicalStorm:
            return .init(renderingMode: .monochrome,
                         styles: [.haruWeatherBlue])
        }
    }
}
