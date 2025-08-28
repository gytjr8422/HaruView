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
        VStack(spacing: 3) {
            // 구버전 알림 배너
            HStack {
                Text("→ 새 위젯 권장")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.orange)
                    .cornerRadius(3)
                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.top, 4)
            
            // 기존 위젯 내용 (높이 제한)
            Group {
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
            .clipped() // 넘치는 내용 잘라내기
            
            Spacer(minLength: 0)
        }
        .background(Color.haruWidgetBackground)
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
        .configurationDisplayName("Haru Widget (구버전)")
        .description("새로운 개별 위젯들을 사용하시기 바랍니다")
        .supportedFamilies([.systemMedium, .systemLarge]) // 기존 사용자를 위해 복원
    }
}

// MARK: - Small Widget Configurations

struct HaruCalendarWidget: Widget {
    let kind: String = "HaruCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            SmallCalendarWidgetView(entry: entry)
                .containerBackground(Color.haruWidgetBackground, for: .widget)
        }
        .configurationDisplayName(NSLocalizedString("haru_calendar", comment: "Calendar widget name"))
        .description(NSLocalizedString("haru_calendar_desc", comment: "Calendar widget description"))
        .supportedFamilies([.systemSmall])
    }
}

struct HaruEventsWidget: Widget {
    let kind: String = "HaruEventsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EventsProvider()) { entry in
            SmallEventsWidget(entry: entry)
                .containerBackground(Color.haruWidgetBackground, for: .widget)
        }
        .configurationDisplayName(NSLocalizedString("haru_events", comment: "Events widget name"))
        .description(NSLocalizedString("haru_events_desc", comment: "Events widget description"))
        .supportedFamilies([.systemSmall])
    }
}

struct HaruRemindersWidget: Widget {
    let kind: String = "HaruRemindersWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RemindersProvider()) { entry in
            SmallRemindersWidget(entry: entry)
                .containerBackground(Color.haruWidgetBackground, for: .widget)
        }
        .configurationDisplayName(NSLocalizedString("haru_reminders", comment: "Reminders widget name"))
        .description(NSLocalizedString("haru_reminders_desc", comment: "Reminders widget description"))
        .supportedFamilies([.systemSmall])
    }
}

struct HaruCalendarListWidget: Widget {
    let kind: String = "HaruCalendarListWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarListProvider()) { entry in
            MediumCalendarListWidgetView(entry: entry)
                .containerBackground(Color.haruWidgetBackground, for: .widget)
        }
        .configurationDisplayName(NSLocalizedString("haru_calendar_list", comment: "Calendar + List widget name"))
        .description(NSLocalizedString("haru_calendar_list_desc", comment: "Calendar + List widget description"))
        .supportedFamilies([.systemMedium])
    }
}

struct HaruWeeklyWidget: Widget {
    let kind: String = "HaruWeeklyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyScheduleProvider()) { entry in
            WeeklyScheduleWidgetView(entry: entry)
                .containerBackground(Color.haruWidgetBackground, for: .widget)
        }
        .configurationDisplayName(NSLocalizedString("haru_weekly_schedule", comment: "Weekly Schedule widget name"))
        .description(NSLocalizedString("haru_weekly_schedule_desc", comment: "Weekly Schedule widget description"))
        .supportedFamilies([.systemMedium])
    }
}

struct HaruMonthlyCalendarWidget: Widget {
    let kind: String = "HaruMonthlyCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthlyCalendarProvider()) { entry in
            LargeMonthlyCalendarWidget(entry: entry)
                .containerBackground(Color.haruWidgetBackground, for: .widget)
        }
        .configurationDisplayName(NSLocalizedString("haru_monthly_calendar", comment: "Monthly Calendar widget name"))
        .description(NSLocalizedString("haru_monthly_calendar_desc", comment: "Monthly Calendar widget description"))
        .supportedFamilies([.systemLarge])
    }
}

struct HaruMediumWidget: Widget {
    let kind: String = "HaruMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MediumListProvider()) { entry in
            MediumWidgetView(entry: entry)
                .containerBackground(Color.haruWidgetBackground, for: .widget)
        }
        .configurationDisplayName(NSLocalizedString("haru_medium_widget", comment: "Medium Widget name"))
        .description(NSLocalizedString("haru_medium_widget_desc", comment: "Medium Widget description"))
        .supportedFamilies([.systemMedium])
    }
}

struct HaruLargeWidget: Widget {
    let kind: String = "HaruLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LargeListProvider()) { entry in
            LargeWidgetView(entry: entry)
                .containerBackground(Color.haruWidgetBackground, for: .widget)
        }
        .configurationDisplayName(NSLocalizedString("haru_large_widget", comment: "Large Widget name"))
        .description(NSLocalizedString("haru_large_widget_desc", comment: "Large Widget description"))
        .supportedFamilies([.systemLarge])
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
