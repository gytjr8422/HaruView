//
//  DateFormatterFactory.swift
//  HaruView
//
//  Created by 김효석 on 5/4/25.
//

import Foundation

enum DateFormatterFactory {
    static func koreanDateWithDayFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "M월 d일, EEEE"
        return formatter
    }
    
    static func englishDateWithDayFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
    
    // 커스텀 포맷
    static func customFormatter(format: String, locale: Locale = .current) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = format
        return formatter
    }
}
