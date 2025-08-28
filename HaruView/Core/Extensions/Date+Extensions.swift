//
//  Date+Extensions.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import Foundation

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

extension Calendar {
    /// 사용자 설정에 따른 주 시작일이 적용된 Calendar 반환
    static func withUserWeekStartPreference() -> Calendar {
        var calendar = Calendar.current
        let weekStartsOnMonday = SharedUserDefaults.weekStartDay == 1
        calendar.firstWeekday = weekStartsOnMonday ? 2 : 1  // 1=일요일, 2=월요일
        return calendar
    }
    
    /// 요일 이름 배열을 사용자 설정에 따라 반환 (현재 로케일 기반)
    static func weekdaySymbols(startingOnMonday: Bool) -> [String] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortWeekdaySymbols // ["일", "월", "화", ...] 또는 ["Sun", "Mon", "Tue", ...]
        
        if startingOnMonday {
            // 월요일부터 시작: [월, 화, 수, 목, 금, 토, 일]
            return Array(symbols[1...]) + [symbols[0]]
        } else {
            // 일요일부터 시작: [일, 월, 화, 수, 목, 금, 토]
            return symbols
        }
    }
    
    /// 요일 이름 배열을 사용자 설정에 따라 반환 (한국어 - 호환성 유지)
    static func weekdaySymbolsKorean(startingOnMonday: Bool) -> [String] {
        return weekdaySymbols(startingOnMonday: startingOnMonday)
    }
    
    /// 요일 이름 배열을 사용자 설정에 따라 반환 (영어 - 호환성 유지)
    static func weekdaySymbolsEnglish(startingOnMonday: Bool) -> [String] {
        return weekdaySymbols(startingOnMonday: startingOnMonday)
    }
    
    /// 월 첫째 날이 그리드에서 시작할 위치 인덱스 계산
    func startingWeekdayIndex(for date: Date) -> Int {
        let weekday = component(.weekday, from: date) // 1=일, 2=월, ..., 7=토
        let adjustedWeekday = (weekday - firstWeekday + 7) % 7
        return adjustedWeekday
    }
}
