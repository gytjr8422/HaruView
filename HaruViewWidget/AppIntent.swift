//
//  AppIntent.swift
//  HaruViewWidget
//
//  Created by 김효석 on 6/17/25.
//

import SwiftUI
import WidgetKit
import AppIntents

enum WidgetType: String, CaseIterable, AppEnum {
    case events = "events"
    case reminders = "reminders"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "위젯 타입")
    }
    
    static var caseDisplayRepresentations: [WidgetType: DisplayRepresentation] {
        [
            .events: DisplayRepresentation(title: "일정", subtitle: "오늘의 캘린더 일정을 표시합니다"),
            .reminders: DisplayRepresentation(title: "할 일", subtitle: "오늘의 미리알림을 표시합니다")
        ]
    }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "하루뷰 설정" }
    static var description: IntentDescription { "오늘의 일정과 미리알림을 표시하는 위젯입니다." }

    // 위젯 타입 (Small 위젯에서만 사용)
    @Parameter(title: "위젯 타입", default: .events)
    var widgetType: WidgetType
    
    // 즐겨찾는 이모지 (일정이 없을 때 표시)
    @Parameter(title: "즐겨찾는 이모지", default: "😊")
    var favoriteEmoji: String
}

// MARK: - Convenience Initializers
extension Color {
    init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(
            red: Double(red) / 255.0,
            green: Double(green) / 255.0,
            blue: Double(blue) / 255.0
        )
    }
    
    init(hex: Int) {
        self.init(
            red: (hex >> 16) & 0xFF,
            green: (hex >> 8) & 0xFF,
            blue: hex & 0xFF
        )
    }
    
    init(hexCode: String) {
        var formattedHex = hexCode.trimmingCharacters(in: .whitespacesAndNewlines)
        formattedHex = formattedHex.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: formattedHex).scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}
