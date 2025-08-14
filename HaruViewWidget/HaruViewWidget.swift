//
//  HaruViewWidget.swift
//  HaruViewWidget
//
//  Created by 김효석 on 6/17/25.
//

import WidgetKit
import SwiftUI
import UIKit
import EventKit
import AppIntents

// MARK: - Font Extensions
extension Font {
    static func robotoSerifBold(size: CGFloat) -> Font {
        .custom("RobotoSerif28pt-Bold", size: size)
    }

    static func pretendardBold(size: CGFloat) -> Font {
        .custom("Pretendard-Bold", size: size)
    }

    static func pretendardSemiBold(size: CGFloat) -> Font {
        .custom("Pretendard-SemiBold", size: size)
    }

    static func pretendardRegular(size: CGFloat) -> Font {
        .custom("Pretendard-Regular", size: size)
    }
    
    static func museumBold(size: CGFloat) -> Font {
        .custom("MuseumClassicBold", size: size)
    }
    
    static func museumMedium(size: CGFloat) -> Font {
        .custom("MuseumClassicMedium", size: size)
    }
    
    static func jakartaRegular(size: CGFloat) -> Font {
        .custom("PlusJakartaSans-Regular", size: size)
    }
    
    static func jakartaBold(size: CGFloat) -> Font {
        .custom("PlusJakartaSans-Bold", size: size)
    }
    
    static func bookkMyungjoBold(size: CGFloat) -> Font {
        .custom("BookkMyungjo-Bd", size: size)
    }
}



// MARK: - Widget Views

struct HaruViewWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            // 앱과 동일한 배경색
            Color.haruWidgetBackground
            
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
    }
}

// MARK: - Widget Configuration

struct HaruViewWidget: Widget {
    let kind: String = "HaruViewWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            HaruViewWidgetEntryView(entry: entry)
                .containerBackground(Color.haruWidgetBackground, for: .widget)
        }
        .configurationDisplayName("하루뷰 Widget")
        .description("오늘의 캘린더 일정과 미리알림을 한눈에 확인하세요")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
//        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
//        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemMedium) {
    HaruViewWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley,
                events: [
                    CalendarEvent(title: "팀 미팅", startDate: Date(), endDate: Date().addingTimeInterval(3600), isAllDay: false, calendarColor: UIColor.systemBlue.cgColor),
                    CalendarEvent(title: "점심 약속", startDate: Date().addingTimeInterval(3600), endDate: Date().addingTimeInterval(7200), isAllDay: false, calendarColor: UIColor.systemGreen.cgColor),
                    CalendarEvent(title: "업무 회의", startDate: Date(), endDate: Date().addingTimeInterval(3600), isAllDay: false, calendarColor: UIColor.systemRed.cgColor),
                    CalendarEvent(title: "개인 일정", startDate: Date().addingTimeInterval(3600), endDate: Date().addingTimeInterval(7200), isAllDay: false, calendarColor: UIColor.systemPurple.cgColor)
                ],
                reminders: [
                    ReminderItem(id: "1", title: "프로젝트 마감", dueDate: Date(), priority: 1, isCompleted: false, reminderType: .onDate),
                    ReminderItem(id: "2", title: "프로젝트2 시작", dueDate: Date(), priority: 1, isCompleted: false, reminderType: .untilDate)
                ])
    SimpleEntry(date: .now, configuration: .starEyes, events: [], reminders: [])
}
