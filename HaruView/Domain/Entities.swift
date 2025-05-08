//
//  Entities.swift
//  HaruView
//
//  Created by 김효석 on 4/30/25.
//

import SwiftUI

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

// MARK: - 미리 알림(To do)
struct Reminder: Identifiable, Equatable {
    let id: String       // EKReminder.calendarItemIdentifier
    let title: String
    let due: Date?
    var isCompleted: Bool
    let priority: Int
}


// MARK: - 날씨
struct Weather: Equatable {
    enum Condition: String {
        case clear, cloudy, rain, snow, thunder
    }
    
    let temperature: Measurement<UnitTemperature>
    let condition: Condition
    let updatedAt: Date
}

// MARK: - 한눈 요약
struct TodayOverview: Equatable {
    let events: [Event]
    var reminders: [Reminder]
    let weather: Weather
    
    static let placeholder = TodayOverview(
        events: [Event(id: "1111", title: "WWDC 컨퍼런스 참석", start: Calendar.current.startOfDay(for: Date()), end: Date.at(hour: 23, minute: 59)!, calendarTitle: "집", calendarColor: CGColor(gray: 0.9, alpha: 0.9), location: "Apple Campus"),
                 Event(id: "1113", title: "운동", start: Date(), end: Date(), calendarTitle: "운동장", calendarColor: CGColor(gray: 0.9, alpha: 0.9), location: ""),
                 Event(id: "1115", title: "코딩", start: Date(), end: Date(), calendarTitle: "집", calendarColor: CGColor(gray: 0.9, alpha: 0.9), location: ""),
                 Event(id: "1116", title: "공부하기", start: Date(), end: Date(), calendarTitle: "집", calendarColor: CGColor(gray: 0.9, alpha: 0.9), location: ""),
                 Event(id: "1117", title: "친구 만나기", start: Date(), end: Date(), calendarTitle: "카페", calendarColor: CGColor(gray: 0.9, alpha: 0.9), location: ""),
                 Event(id: "1118", title: "재택근무", start: Date(), end: Date(), calendarTitle: "집", calendarColor: CGColor(gray: 0.9, alpha: 0.9), location: "")],
        reminders: [Reminder(id: "1112", title: "원두 주문하기", due: nil, isCompleted: false, priority: 0),
                    Reminder(id: "1114", title: "약국 가기", due: Date(), isCompleted: true, priority: 1),
                    Reminder(id: "1119", title: "미리보기", due: Date(), isCompleted: false, priority: 9),
                    Reminder(id: "1120", title: "책 읽기", due: nil, isCompleted: false, priority: 0),
                    Reminder(id: "1121", title: "병원 가기", due: Date(), isCompleted: false, priority: 5),
                    Reminder(id: "1122", title: "설거지 하기", due: nil, isCompleted: false, priority: 0)],
        weather: .init(temperature: .init(value: 0, unit: .celsius), condition: .clear, updatedAt: .distantPast)
    )
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
