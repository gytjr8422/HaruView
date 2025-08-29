//
//  TimeFormatter.swift
//  HaruViewWidget
//
//  Created by Claude on 8/27/25.
//

import Foundation

struct WidgetTimeFormatter {
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let currentLanguage = SharedUserDefaults.selectedLanguage
        
        switch currentLanguage {
        case "ko":
            formatter.locale = Locale(identifier: "ko_KR")
        case "en":
            formatter.locale = Locale(identifier: "en_US")
        case "ja":
            formatter.locale = Locale(identifier: "ja_JP")
        default:
            formatter.locale = Locale(identifier: "ko_KR")
        }
        
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    static func isSameTime(start: Date, end: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let startTime = formatter.string(from: start)
        let endTime = formatter.string(from: end)
        return startTime == endTime
    }
}