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

// Custom localization function for widget names/descriptions using system language
func localizedString(key: String, comment: String) -> String {
    // 여러 방법으로 언어 감지 시도
    let preferredLanguages = Locale.preferredLanguages
    let bundlePreferred = Bundle.main.preferredLocalizations.first
    let currentIdentifier = Locale.current.identifier
    
    print("🔍 Widget Debug - preferredLanguages: \(preferredLanguages)")
    print("🔍 Widget Debug - bundlePreferred: \(bundlePreferred ?? "nil")")
    print("🔍 Widget Debug - currentIdentifier: \(currentIdentifier)")
    
    // Bundle의 preferredLocalizations를 우선 사용
    let detectLanguage = bundlePreferred ?? preferredLanguages.first ?? "ko"
    
    let currentLanguage: String
    
    if detectLanguage.hasPrefix("ko") {
        currentLanguage = "ko"
    } else if detectLanguage.hasPrefix("ja") {
        currentLanguage = "ja"  
    } else {
        currentLanguage = "en"
    }
    
    print("🔍 Widget Debug - final language: \(currentLanguage)")
    
    let translations: [String: [String: String]] = [
        "ko": [
            "no_events_today": "오늘 일정이 없습니다",
            "no_reminders_today": "오늘 할 일이 없습니다",
            "하루 종일": "하루 종일",
            "일정": "일정",
            "할 일": "할 일",
            // 위젯 이름
            "haru_widget": "하루 위젯",
            "haru_calendar": "하루 달력",
            "haru_events": "하루 일정",
            "haru_reminders": "하루 할 일",
            "haru_calendar_list": "하루 달력 + 목록",
            "haru_weekly_schedule": "하루 주간 일정",
            // 위젯 설명
            "haru_widget_desc": "오늘의 일정과 할 일을 한눈에 확인하세요",
            "haru_calendar_desc": "일정과 할 일이 표시된 월간 달력",
            "haru_events_desc": "오늘의 일정 목록",
            "haru_reminders_desc": "오늘의 할 일 목록",
            "haru_calendar_list_desc": "월간 달력과 오늘의 일정 및 할 일",
            "haru_weekly_schedule_desc": "이번 주 일정과 할 일 개요"
        ],
        "en": [
            "no_events_today": "No events today",
            "no_reminders_today": "No reminders today",
            "하루 종일": "All day",
            "일정": "Events",
            "할 일": "Reminders",
            // 위젯 이름
            "haru_widget": "Haru Widget",
            "haru_calendar": "Haru Calendar",
            "haru_events": "Haru Events",
            "haru_reminders": "Haru Reminders",
            "haru_calendar_list": "Haru Calendar + List",
            "haru_weekly_schedule": "Haru Weekly Schedule",
            // 위젯 설명
            "haru_widget_desc": "Check today's calendar events and reminders at a glance",
            "haru_calendar_desc": "Monthly calendar view with events and reminders",
            "haru_events_desc": "Today's calendar events list",
            "haru_reminders_desc": "Today's reminders list",
            "haru_calendar_list_desc": "Monthly calendar with today's events and reminders",
            "haru_weekly_schedule_desc": "This week's events and reminders overview"
        ],
        "ja": [
            "no_events_today": "今日の予定はありません",
            "no_reminders_today": "今日のリマインダーはありません",
            "하루 종일": "終日",
            "일정": "予定",
            "할 일": "リマインダー",
            // 위젯 이름
            "haru_widget": "ハル ウィジェット",
            "haru_calendar": "ハル カレンダー",
            "haru_events": "ハル 予定",
            "haru_reminders": "ハル リマインダー",
            "haru_calendar_list": "ハル カレンダー + リスト",
            "haru_weekly_schedule": "ハル 週間スケジュール",
            // 위젯 설명
            "haru_widget_desc": "今日の予定とリマインダーを一目で確認",
            "haru_calendar_desc": "予定とリマインダー付きの月間カレンダー",
            "haru_events_desc": "今日の予定リスト",
            "haru_reminders_desc": "今日のリマインダーリスト",
            "haru_calendar_list_desc": "月間カレンダーと今日の予定・リマインダー",
            "haru_weekly_schedule_desc": "今週の予定とリマインダーの概要"
        ]
    ]
    
    return translations[currentLanguage]?[key] ?? translations["ko"]?[key] ?? key
}

// Custom localization function for widget content using app language settings
func localizedWidgetContent(key: String, comment: String) -> String {
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