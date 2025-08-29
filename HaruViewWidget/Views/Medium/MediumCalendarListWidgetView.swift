//
//  MediumCalendarListWidgetView.swift
//  HaruViewWidget
//
//  Created by Claude on 8/27/25.
//

import SwiftUI
import UIKit

struct MediumCalendarListWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        HStack(spacing: 8) {
            // 왼쪽: 달력 뷰 (크기 고정)
            SmallCalendarWidgetView(entry: entry)
                .frame(width: 130, height: 125)
                .layoutPriority(1) // 달력 크기 우선순위 설정
            
            // 구분선
            Rectangle()
                .fill(.haruCardBorder)
                .padding(.vertical, 5)
                .frame(width: 1, height: .infinity)
            
            // 오른쪽: 일정과 할일 리스트
            EventReminderListView(entry: entry)
                .padding(.top, 10)
                .frame(maxWidth: .infinity)
        }
    }
}

struct EventReminderListView: View {
    let entry: Provider.Entry
    
    private var displayItems: (events: [CalendarEvent], reminders: [ReminderItem]) {
        let calendar = Calendar.withUserWeekStartPreference()
        let today = Date()
        
        // 오늘 일정만 필터링
        let todayEvents = entry.events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: today) ||
            calendar.isDate(event.endDate, inSameDayAs: today) ||
            (event.startDate < today && event.endDate > today)
        }
        
        // 오늘 할일 + 날짜 없는 할일 필터링
        let todayReminders = entry.reminders.filter { reminder in
            guard let dueDate = reminder.dueDate else { return true }
            return calendar.isDate(dueDate, inSameDayAs: today)
        }
        
        let eventCount = todayEvents.count
        let reminderCount = todayReminders.count
        let maxTotal = 4
        
        var eventsToShow = 0
        var remindersToShow = 0
        
        // 조건에 따른 표시 개수 결정
        if eventCount >= 2 && reminderCount >= 2 {
            // 조건 1: 일정 2개 이상, 할일 2개 이상
            eventsToShow = 2
            remindersToShow = 2
        } else if eventCount == 1 && reminderCount >= 3 {
            // 조건 2: 일정 1개, 할일 3개 이상
            eventsToShow = 1
            remindersToShow = 3
        } else if eventCount == 1 && reminderCount == 1 {
            // 조건 3: 일정 1개, 할일 1개
            eventsToShow = 1
            remindersToShow = 1
        } else if eventCount >= 3 && reminderCount == 1 {
            // 조건 4: 일정 3개 이상, 할일 1개
            eventsToShow = 3
            remindersToShow = 1
        } else if eventCount >= 4 && reminderCount == 0 {
            // 조건 5: 일정 4개 이상, 할일 0개
            eventsToShow = 4
            remindersToShow = 0
        } else {
            // 기본 로직: 최대 4개까지 비율에 맞게 분배
            let totalItems = eventCount + reminderCount
            if totalItems == 0 {
                eventsToShow = 0
                remindersToShow = 0
            } else if totalItems <= maxTotal {
                eventsToShow = eventCount
                remindersToShow = reminderCount
            } else {
                // 비율에 따라 분배하되, 최소 1개씩은 보장
                if eventCount > 0 && reminderCount > 0 {
                    let eventRatio = Double(eventCount) / Double(totalItems)
                    eventsToShow = max(1, Int(Double(maxTotal) * eventRatio))
                    remindersToShow = maxTotal - eventsToShow
                    
                    // 조정: 실제 데이터 개수를 초과하지 않도록
                    eventsToShow = min(eventsToShow, eventCount)
                    remindersToShow = min(remindersToShow, reminderCount)
                } else if eventCount > 0 {
                    eventsToShow = min(maxTotal, eventCount)
                    remindersToShow = 0
                } else {
                    eventsToShow = 0
                    remindersToShow = min(maxTotal, reminderCount)
                }
            }
        }
        
        return (
            events: Array(todayEvents.prefix(eventsToShow)),
            reminders: Array(todayReminders.prefix(remindersToShow))
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            let items = displayItems
            
            // 일정 표시
            ForEach(Array(items.events.enumerated()), id: \.offset) { index, event in
                EventRowView(event: event)
            }
            
            // 일정과 할일 사이의 구분선 (둘 다 있는 경우에만)
            if !items.events.isEmpty && !items.reminders.isEmpty {
                Divider()
            }
            
            // 할일 표시
            ForEach(Array(items.reminders.enumerated()), id: \.element.id) { index, reminder in
                ReminderRowView(reminder: reminder)
            }
            
            // 데이터가 모두 없는 경우
            if items.events.isEmpty && items.reminders.isEmpty {
                VStack(spacing: 8) {
                    Text(localizedWidgetContent(key: "no_events_today", comment: "No events message"))
                        .font(.pretendardRegular(size: 11))
                        .foregroundStyle(.haruWidgetSecondary)
                    
                    Text(localizedWidgetContent(key: "no_reminders_today", comment: "No reminders message"))
                        .font(.pretendardRegular(size: 11))
                        .foregroundStyle(.haruWidgetSecondary)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            
            Spacer()
        }
    }
    
}

struct EventRowView: View {
    let event: CalendarEvent
    
    var body: some View {
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
                    .foregroundStyle(.haruWidgetText)
                    .strikethrough(isPast)
                    .opacity(isPast ? 0.5 : 1)
                
                if !event.isAllDay {
                    TimeDisplayView(event: event, isPast: isPast)
                } else {
                    Text(localizedWidgetContent(key: "하루 종일", comment: "All day event"))
                        .font(.jakartaRegular(size: 9))
                        .foregroundStyle(.haruWidgetSecondary)
                        .opacity(isPast ? 0.5 : 1)
                }
            }
            
            Spacer()
        }
    }
}

struct TimeDisplayView: View {
    let event: CalendarEvent
    let isPast: Bool
    
    var body: some View {
        if WidgetTimeFormatter.isSameTime(start: event.startDate, end: event.endDate) {
            // 시작 시간과 끝 시간이 같으면 시작 시간만 표시
            Text(WidgetTimeFormatter.formatTime(event.startDate))
                .font(.jakartaRegular(size: 11))
                .foregroundStyle(.haruWidgetSecondary)
                .opacity(isPast ? 0.5 : 1)
        } else {
            // 시작 시간과 끝 시간이 다르면 기존처럼 표시
            HStack(spacing: 2) {
                Text(WidgetTimeFormatter.formatTime(event.startDate))
                    .font(.jakartaRegular(size: 11))
                    .foregroundStyle(.haruWidgetSecondary)
                    .opacity(isPast ? 0.5 : 1)
                
                Text("-")
                    .font(.jakartaRegular(size: 11))
                    .foregroundStyle(.haruWidgetSecondary)
                    .opacity(isPast ? 0.5 : 1)
                
                Text(WidgetTimeFormatter.formatTime(event.endDate))
                    .font(.jakartaRegular(size: 11))
                    .foregroundStyle(.haruWidgetSecondary)
                    .opacity(isPast ? 0.5 : 1)
            }
        }
    }
}

struct ReminderRowView: View {
    let reminder: ReminderItem
    
    var body: some View {
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
                        .foregroundStyle(reminder.isCompleted ? .haruCompleted : .secondary)
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
                .foregroundStyle(reminder.isCompleted ? .secondary : .primary)
                .invalidatableContent()
            
            Spacer()
        }
    }
}

#Preview("Medium Calendar List Widget") {
    let sampleEntry = SimpleEntry(
        date: Date(),
        configuration: {
            let config = ConfigurationAppIntent()
            config.viewType = .calendar
            return config
        }(),
        events: [
            CalendarEvent(title: "팀 미팅", startDate: Date(), endDate: Date().addingTimeInterval(3600), isAllDay: false, calendarColor: UIColor.systemBlue.cgColor),
            CalendarEvent(title: "점심 약속", startDate: Date().addingTimeInterval(3600), endDate: Date().addingTimeInterval(7200), isAllDay: false, calendarColor: UIColor.systemGreen.cgColor),
            CalendarEvent(title: "프로젝트 회의", startDate: Date().addingTimeInterval(7200), endDate: Date().addingTimeInterval(10800), isAllDay: false, calendarColor: UIColor.systemRed.cgColor)
        ],
        reminders: [
            ReminderItem(id: "1", title: "프로젝트 마감", dueDate: Date(), priority: 1, isCompleted: false, reminderType: .onDate),
            ReminderItem(id: "2", title: "보고서 작성", dueDate: Date(), priority: 2, isCompleted: true, reminderType: .untilDate),
            ReminderItem(id: "3", title: "회의 준비", dueDate: Date(), priority: 3, isCompleted: false, reminderType: .onDate)
        ]
    )
    
    MediumCalendarListWidgetView(entry: sampleEntry)
        .frame(height: 158)
        .background(.haruWidgetBackground)
}
