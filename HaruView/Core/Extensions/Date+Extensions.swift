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
        let weekStartsOnMonday = UserDefaults.standard.object(forKey: "weekStartsOnMonday") as? Bool ?? false
        calendar.firstWeekday = weekStartsOnMonday ? 2 : 1  // 1=일요일, 2=월요일
        return calendar
    }
    
    /// 요일 이름 배열을 사용자 설정에 따라 반환 (한국어)
    static func weekdaySymbolsKorean() -> [String] {
        let weekStartsOnMonday = UserDefaults.standard.object(forKey: "weekStartsOnMonday") as? Bool ?? false
        if weekStartsOnMonday {
            return ["월", "화", "수", "목", "금", "토", "일"]
        } else {
            return ["일", "월", "화", "수", "목", "금", "토"]
        }
    }
    
    /// 요일 이름 배열을 사용자 설정에 따라 반환 (영어)
    static func weekdaySymbolsEnglish() -> [String] {
        let weekStartsOnMonday = UserDefaults.standard.object(forKey: "weekStartsOnMonday") as? Bool ?? false
        if weekStartsOnMonday {
            return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        } else {
            return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        }
    }
    
    /// 월 첫째 날이 그리드에서 시작할 위치 인덱스 계산
    func startingWeekdayIndex(for date: Date) -> Int {
        let weekday = component(.weekday, from: date) // 1=일, 2=월, ..., 7=토
        let adjustedWeekday = (weekday - firstWeekday + 7) % 7
        return adjustedWeekday
    }
}
