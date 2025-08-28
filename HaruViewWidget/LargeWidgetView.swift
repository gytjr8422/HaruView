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
        // 월간 달력 표시 여부 확인 (나중에 설정으로 추가 가능)
        if shouldShowMonthlyCalendar {
            LargeMonthlyCalendarWidget(entry: entry)
        } else {
            originalLargeView
        }
    }
    
    // MARK: - 월간 달력 표시 여부
    private var shouldShowMonthlyCalendar: Bool {
        // 기본값은 기존 Large 위젯 (false)
        return false
    }
    
    // MARK: - 기존 Large 위젯 뷰
    @ViewBuilder
    private var originalLargeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // 일정 섹션
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.haruPrimary)
                            .font(.system(size: 10))
                        Text(localizedWidgetContent(key: "일정", comment: "Events section title"))
                            .font(.pretendardBold(size: 11))
                            .foregroundStyle(.haruWidgetText)
                    }
                    
                    if entry.events.isEmpty {
                        Text(localizedWidgetContent(key: "no_events_today", comment: "No events message"))
                            .font(.pretendardRegular(size: 11))
                            .foregroundStyle(.haruWidgetSecondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(Array(entry.events.prefix(8).enumerated()), id: \.offset) { index, event in
                            let isPast = event.endDate < Date()
                            
                            HStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color(cgColor: event.calendarColor))
                                    .frame(width: 4)
                                    .frame(maxHeight: 25)
                                    .opacity(isPast ? 0.5 : 1)
                                
                                VStack(alignment: .leading) {
                                    Text(event.title)
                                        .font(.pretendardBold(size: 12))
                                        .lineLimit(1)
                                        .foregroundStyle(.haruWidgetText)
                                        .strikethrough(isPast)
                                        .opacity(isPast ? 0.5 : 1)
                                    
                                    if !event.isAllDay {
                                        if WidgetTimeFormatter.isSameTime(start: event.startDate, end: event.endDate) {
                                            Text(WidgetTimeFormatter.formatTime(event.startDate))
                                                .font(.jakartaRegular(size: 10))
                                                .foregroundStyle(.haruWidgetSecondary)
                                                .opacity(isPast ? 0.5 : 1)
                                        } else {
                                            HStack(spacing: 2) {
                                                Text(WidgetTimeFormatter.formatTime(event.startDate))
                                                    .font(.jakartaRegular(size: 10))
                                                    .foregroundStyle(.haruWidgetSecondary)
                                                    .opacity(isPast ? 0.5 : 1)
                                                
                                                Text("-")
                                                    .font(.jakartaRegular(size: 10))
                                                    .foregroundStyle(.haruWidgetSecondary)
                                                    .opacity(isPast ? 0.5 : 1)
                                                
                                                Text(WidgetTimeFormatter.formatTime(event.endDate))
                                                    .font(.jakartaRegular(size: 10))
                                                    .foregroundStyle(.haruWidgetSecondary)
                                                    .opacity(isPast ? 0.5 : 1)
                                            }
                                        }
                                    } else {
                                        Text(localizedWidgetContent(key: "하루 종일", comment: "All day event"))
                                            .font(.jakartaRegular(size: 8))
                                            .foregroundStyle(.haruWidgetSecondary)
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
                        Text(localizedWidgetContent(key: "할 일", comment: "Reminders section title"))
                            .font(.pretendardSemiBold(size: 10))
                            .foregroundStyle(.haruWidgetText)
                    }
                    
                    if entry.reminders.isEmpty {
                        Text(localizedWidgetContent(key: "no_reminders_today", comment: "No reminders message"))
                            .font(.pretendardRegular(size: 11))
                            .foregroundStyle(.haruWidgetSecondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(Array(entry.reminders.prefix(8).enumerated()), id: \.element.id) { index, reminder in
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
                                    .font(.pretendardSemiBold(size: 12))
                                    .lineLimit(1)
                                    .strikethrough(reminder.isCompleted)
                                    .foregroundStyle(reminder.isCompleted ? .gray : .haruTextPrimary)
                                    .invalidatableContent()
                            }
                            
                            if index < entry.reminders.prefix(8).count - 1 {
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

