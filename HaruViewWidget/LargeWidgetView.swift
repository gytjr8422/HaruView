//
//  LargeWidgetView.swift
//  LargeWidgetView
//
//  Created by 김효석 on 6/20/25.
//


import SwiftUI
import UIKit

struct LargeWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // 일정 섹션
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.haruPrimary)
                            .font(.system(size: 10))
                        Text("일정")
                            .font(.pretendardBold(size: 11))
                            .foregroundStyle(.haruTextPrimary)
                    }
                    
                    if entry.events.isEmpty {
                        Text("일정이 없습니다")
                            .font(.pretendardRegular(size: 11))
                            .foregroundStyle(.gray)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(Array(entry.events.prefix(9).enumerated()), id: \.offset) { index, event in
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
                                        Text("하루 종일")
                                            .font(.jakartaRegular(size: 9))
                                            .foregroundStyle(.gray)
                                            .opacity(isPast ? 0.5 : 1)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 구분선
                Rectangle()
                    .fill(.haruCardBorder)
                    .frame(width: 1, height: .infinity)
                
                // 할 일 섹션
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "checklist")
                            .foregroundStyle(.haruAccent)
                            .font(.system(size: 10))
                        Text("할 일")
                            .font(.pretendardSemiBold(size: 10))
                            .foregroundStyle(.haruTextPrimary)
                    }
                    
                    if entry.reminders.isEmpty {
                        Text("할 일이 없습니다")
                            .font(.pretendardRegular(size: 11))
                            .foregroundStyle(.gray)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(Array(entry.reminders.prefix(9).enumerated()), id: \.element.id) { index, reminder in
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
                                            .foregroundStyle(reminder.isCompleted ? .haruPrimary : .gray)
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
                            
                            if index < entry.reminders.prefix(9).count - 1 {
                                Divider()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview("Large Widget") {
    let sampleEntry = SimpleEntry(
        date: Date(),
        configuration: ConfigurationAppIntent(),
        events: [
            CalendarEvent(title: "팀 미팅", startDate: Date(), endDate: Date().addingTimeInterval(3600), isAllDay: false, calendarColor: UIColor.systemBlue.cgColor),
            CalendarEvent(title: "점심 약속", startDate: Date().addingTimeInterval(3600), endDate: Date().addingTimeInterval(7200), isAllDay: false, calendarColor: UIColor.systemGreen.cgColor),
            CalendarEvent(title: "프로젝트 회의", startDate: Date().addingTimeInterval(7200), endDate: Date().addingTimeInterval(10800), isAllDay: false, calendarColor: UIColor.systemRed.cgColor),
            CalendarEvent(title: "운동", startDate: Date().addingTimeInterval(10800), endDate: Date().addingTimeInterval(14400), isAllDay: false, calendarColor: UIColor.systemPurple.cgColor),
            CalendarEvent(title: "저녁 식사", startDate: Date().addingTimeInterval(14400), endDate: Date().addingTimeInterval(18000), isAllDay: false, calendarColor: UIColor.systemOrange.cgColor)
        ],
        reminders: [
            ReminderItem(id: "1", title: "프로젝트 마감", dueDate: Date(), priority: 1, isCompleted: false, reminderType: .onDate),
            ReminderItem(id: "2", title: "보고서 작성", dueDate: Date(), priority: 2, isCompleted: true, reminderType: .untilDate),
            ReminderItem(id: "3", title: "회의 준비", dueDate: Date(), priority: 3, isCompleted: false, reminderType: .onDate),
            ReminderItem(id: "4", title: "이메일 확인", dueDate: Date(), priority: 1, isCompleted: false, reminderType: .untilDate)
        ]
    )
    
    LargeWidgetView(entry: sampleEntry)
        .background(.haruWidgetBackground)
}

