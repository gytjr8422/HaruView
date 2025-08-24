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
        TypeDisplayRepresentation(name: "Widget Type")
    }
    
    static var caseDisplayRepresentations: [WidgetType: DisplayRepresentation] {
        [
            .events: DisplayRepresentation(title: "Events", subtitle: "Display today's calendar events"),
            .reminders: DisplayRepresentation(title: "Reminders", subtitle: "Display today's reminders")
        ]
    }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Haru Settings" }
    static var description: IntentDescription { "Widget that displays today's events and reminders." }

    // 위젯 타입 (Small 위젯에서만 사용)
    @Parameter(title: "Widget Type", default: .events)
    var widgetType: WidgetType
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
}
