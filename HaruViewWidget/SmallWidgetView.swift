//
//  SmallWidgetView.swift
//  SmallWidgetView
//
//  Created by 김효석 on 6/20/25.
//

import SwiftUI
import UIKit


struct SmallWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        // 설정에 따라 일정 또는 할일 위젯 표시
        if entry.configuration.widgetType == .events {
            SmallEventsWidget(entry: entry)
        } else {
            SmallRemindersWidget(entry: entry)
        }
    }
}

struct SmallEventsWidget: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            
            if entry.events.isEmpty {
                Text(NSLocalizedString("no_events_today", bundle: .widgetBundle, comment: "No events message"))
                    .font(.pretendardRegular(size: 11))
                    .foregroundStyle(.gray)
                    .padding(.vertical, 4)
            } else {
                VStack {
                    ForEach(Array(entry.events.prefix(4).enumerated()), id: \.offset) { index, event in
                        let isPast = event.endDate < Date()
                        
                        HStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color(cgColor: event.calendarColor))
                                .frame(width: 4)
                                .frame(maxHeight: 25)
                                .opacity(isPast ? 0.5 : 1)
                            
                            VStack(alignment: .leading) {
                                Text(event.title)
                                    .font(.pretendardBold(size: 13))
                                    .lineLimit(1)
                                    .foregroundStyle(.haruTextPrimary)
                                    .strikethrough(isPast)
                                    .opacity(isPast ? 0.5 : 1)
                                
                                if !event.isAllDay {
                                    Text(event.startDate, style: .time)
                                        .font(.jakartaRegular(size: 11))
                                        .foregroundStyle(.gray)
                                        .opacity(isPast ? 0.5 : 1)
                                } else {
                                    Text(NSLocalizedString("하루 종일", comment: "All day event"))
                                        .font(.jakartaRegular(size: 9))
                                        .foregroundStyle(.gray)
                                        .opacity(isPast ? 0.5 : 1)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                }
                Spacer()
            }
        }
    }
}


struct SmallRemindersWidget: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            
            if entry.reminders.isEmpty {
                Text(NSLocalizedString("no_reminders_today", bundle: .widgetBundle, comment: "No reminders message"))
                    .font(.pretendardRegular(size: 11))
                    .foregroundStyle(.gray)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(entry.reminders.prefix(4).enumerated()), id: \.element.id) { index, reminder in
                    HStack(spacing: 2) {
                        // iOS 18에서는 Toggle, iOS 17에서는 Button 사용
                        if #available(iOS 18, *) {
                            Toggle(isOn: reminder.isCompleted, intent: ToggleReminderIntent(reminderId: reminder.id)) {
                                EmptyView()
                            }
                            .toggleStyle(CheckboxToggleStyle())
                            .invalidatableContent()
                            .frame(width: 24, height: 24)
                        } else {
                            Button(intent: ToggleReminderIntent(reminderId: reminder.id)) {
                                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(reminder.isCompleted ? .haruCompleted : .gray)
                                    .font(.system(size: 20))
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            .buttonStyle(.plain)
                            .invalidatableContent()
                            .frame(width: 24, height: 24)
                        }
                        
                        Text(reminder.title)
                            .font(.pretendardSemiBold(size: 13))
                            .lineLimit(1)
                            .strikethrough(reminder.isCompleted)
                            .foregroundStyle(reminder.isCompleted ? .gray : .haruTextPrimary)
                            .invalidatableContent()
                    }
                    .offset(x: -8)
                    
                    if index < entry.reminders.prefix(4).count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}

#Preview("Small Widget - Events") {
    let sampleEntry = SimpleEntry(
        date: Date(),
        configuration: {
            let config = ConfigurationAppIntent()
            config.widgetType = .events
            return config
        }(),
        events: [
            CalendarEvent(title: "팀 미팅", startDate: Date(), endDate: Date().addingTimeInterval(3600), isAllDay: false, calendarColor: UIColor.systemBlue.cgColor),
            CalendarEvent(title: "점심 약속", startDate: Date().addingTimeInterval(3600), endDate: Date().addingTimeInterval(7200), isAllDay: false, calendarColor: UIColor.systemGreen.cgColor),
            CalendarEvent(title: "회의", startDate: Date().addingTimeInterval(7200), endDate: Date().addingTimeInterval(10800), isAllDay: true, calendarColor: UIColor.systemRed.cgColor)
        ],
        reminders: []
    )
    
    SmallWidgetView(entry: sampleEntry)
        .background(.haruWidgetBackground)
}

#Preview("Small Widget - Reminders") {
    let sampleEntry = SimpleEntry(
        date: Date(),
        configuration: {
            let config = ConfigurationAppIntent()
            config.widgetType = .reminders
            return config
        }(),
        events: [],
        reminders: [
            ReminderItem(id: "1", title: "프로젝트 마감", dueDate: Date(), priority: 1, isCompleted: false, reminderType: .onDate),
            ReminderItem(id: "2", title: "보고서 작성", dueDate: Date(), priority: 2, isCompleted: true, reminderType: .untilDate),
            ReminderItem(id: "3", title: "회의 준비", dueDate: Date(), priority: 3, isCompleted: false, reminderType: .onDate)
        ]
    )
    
    SmallWidgetView(entry: sampleEntry)
        .background(.haruWidgetBackground)
}
