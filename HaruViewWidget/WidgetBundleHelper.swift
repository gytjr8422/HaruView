//
//  WidgetBundleHelper.swift
//  HaruViewWidget
//
//  Created for widget localization support.
//

import Foundation

// Bundle helper for widget localization
class WidgetBundleHelper {}

extension Bundle {
    static var widgetBundle: Bundle {
        return Bundle(for: WidgetBundleHelper.self)
    }
}

// Custom localization function for widgets
func localizedString(key: String, comment: String) -> String {
    let currentLanguage = SharedUserDefaults.selectedLanguage
    
    let translations: [String: [String: String]] = [
        "ko": [
            "no_events_today": "오늘 일정이 없습니다",
            "no_reminders_today": "오늘 할 일이 없습니다",
            "하루 종일": "하루 종일",
            "일정": "일정",
            "할 일": "할 일"
        ],
        "en": [
            "no_events_today": "No events today",
            "no_reminders_today": "No reminders today",
            "하루 종일": "All day",
            "일정": "Events",
            "할 일": "Reminders"
        ],
        "ja": [
            "no_events_today": "今日の予定はありません",
            "no_reminders_today": "今日のリマインダーはありません",
            "하루 종일": "終日",
            "일정": "予定",
            "할 일": "リマインダー"
        ]
    ]
    
    return translations[currentLanguage]?[key] ?? translations["ko"]?[key] ?? key
}