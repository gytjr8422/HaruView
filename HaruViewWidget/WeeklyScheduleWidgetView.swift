//
//  WeeklyScheduleWidgetView.swift
//  HaruViewWidget
//
//  Created by Claude on 8/27/25.
//

import SwiftUI
import UIKit

struct WeeklyScheduleWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더: 요일과 날짜
            WeekHeaderView()
            
            // 구분선
            Rectangle()
                .fill(.haruCardBorder)
                .frame(height: 1)
            
            // 일정/할일 컨텐츠
            WeekContentView(entry: entry)
        }
    }
}

struct WeekHeaderView: View {
    private let weekDays: [(day: String, date: Int)] = {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let currentLanguage = SharedUserDefaults.selectedLanguage
        
        var days: [(String, Int)] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) ?? today
            let dayNumber = calendar.component(.day, from: date)
            
            let dayName: String
            switch currentLanguage {
            case "en":
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US")
                formatter.dateFormat = "E"
                dayName = formatter.string(from: date)
            case "ja":
                let weekdayNames = ["日", "月", "火", "水", "木", "金", "土"]
                let weekday = calendar.component(.weekday, from: date)
                dayName = weekdayNames[weekday - 1]
            default: // "ko"
                let weekdayNames = ["일", "월", "화", "수", "목", "금", "토"]
                let weekday = calendar.component(.weekday, from: date)
                dayName = weekdayNames[weekday - 1]
            }
            
            days.append((dayName, dayNumber))
        }
        
        return days
    }()
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekDays.enumerated()), id: \.offset) { index, dayInfo in
                VStack(spacing: 2) {
                    Text(dayInfo.day)
                        .font(.pretendardBold(size: 9))
                        .foregroundStyle(.haruWidgetSecondary)
                    
                    Text("\(dayInfo.date)")
                        .font(.pretendardBold(size: 11))
                        .foregroundStyle(.haruWidgetText)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 24)
            }
        }
        .padding(.vertical, 4)
    }
}

struct WeekContentView: View {
    let entry: Provider.Entry
    
    private var weeklyData: [DayData] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        var weekData: [DayData] = []
        
        for i in 0..<7 {
            let currentDate = calendar.date(byAdding: .day, value: i, to: startOfWeek) ?? today
            let isToday = calendar.isDate(currentDate, inSameDayAs: today)
            
            // 해당 날짜의 일정 필터링
            let dayEvents = entry.events.filter { event in
                calendar.isDate(event.startDate, inSameDayAs: currentDate) ||
                calendar.isDate(event.endDate, inSameDayAs: currentDate) ||
                (event.startDate < currentDate && event.endDate > currentDate)
            }
            
            // 해당 날짜의 할일 필터링
            let dayReminders = entry.reminders.filter { reminder in
                guard let dueDate = reminder.dueDate else { return false }
                return calendar.isDate(dueDate, inSameDayAs: currentDate)
            }
            
            // 우선순위 정렬 및 상위 5개 선택
            let sortedItems = sortAndLimitItems(events: dayEvents, reminders: dayReminders, for: currentDate)
            
            weekData.append(DayData(
                date: currentDate,
                isToday: isToday,
                items: sortedItems
            ))
        }
        
        return weekData
    }
    
    private func sortAndLimitItems(events: [CalendarEvent], reminders: [ReminderItem], for date: Date) -> [WeeklyItem] {
        var items: [WeeklyItem] = []
        let now = Date()
        
        // 일정 변환
        for event in events {
            let isOngoing = event.startDate <= now && event.endDate > now
            let priority = isOngoing ? 0 : (event.isAllDay ? 2 : 1)
            items.append(WeeklyItem(
                title: event.title,
                type: .event,
                priority: priority,
                startTime: event.startDate,
                color: event.calendarColor,
                isCompleted: event.endDate < now
            ))
        }
        
        // 할일 변환 (완료되지 않은 것만)
        for reminder in reminders.filter({ !$0.isCompleted }) {
            items.append(WeeklyItem(
                title: reminder.title,
                type: .reminder,
                priority: 3,
                startTime: reminder.dueDate ?? date,
                color: nil,
                isCompleted: false
            ))
        }
        
        // 정렬: 우선순위 -> 시작시간 순
        items.sort { first, second in
            if first.priority != second.priority {
                return first.priority < second.priority
            }
            return first.startTime < second.startTime
        }
        
        return Array(items.prefix(5))
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(weeklyData.enumerated()), id: \.offset) { index, dayData in
                DayColumnView(dayData: dayData)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.vertical, 4)
    }
}

struct DayColumnView: View {
    let dayData: DayData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(dayData.items.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 2) {
                    // 일정인 경우 색상 점 표시
                    if item.type == .event, let color = item.color {
                        Circle()
                            .fill(Color(cgColor: color))
                            .frame(width: 3, height: 3)
                            .opacity(item.isCompleted ? 0.5 : 1)
                    }
                    
                    Canvas { context, size in
                        let text = Text(item.title)
                            .font(.pretendardRegular(size: 8))
                            .foregroundStyle(
                                item.isCompleted ?
                                (item.type == .event ? .haruWidgetText.opacity(0.5) : .haruWidgetSecondary.opacity(0.5)) :
                                (item.type == .event ? .haruWidgetText : .haruWidgetSecondary)
                            )
                        
                        context.draw(text, at: CGPoint(x: 0, y: size.height / 2), anchor: .leading)
                    }
                    .clipped()
                    
                    Spacer(minLength: 0)
                }
                .frame(height: 12)
            }
            
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .background(dayData.isToday ? Color.haruPrimary.opacity(0.1) : Color.clear)
        .cornerRadius(4)
    }
}

// 데이터 구조체들
struct DayData {
    let date: Date
    let isToday: Bool
    let items: [WeeklyItem]
}

struct WeeklyItem {
    let title: String
    let type: WeeklyItemType
    let priority: Int
    let startTime: Date
    let color: CGColor?
    let isCompleted: Bool
}

enum WeeklyItemType {
    case event
    case reminder
}

#Preview("Weekly Schedule Widget") {
    let sampleEntry = SimpleEntry(
        date: Date(),
        configuration: ConfigurationAppIntent(),
        events: [
            CalendarEvent(title: "팀 미팅", startDate: Date(), endDate: Date().addingTimeInterval(3600), isAllDay: false, calendarColor: UIColor.systemBlue.cgColor),
            CalendarEvent(title: "점심 약속", startDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, endDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!.addingTimeInterval(3600), isAllDay: false, calendarColor: UIColor.systemGreen.cgColor),
            CalendarEvent(title: "프로젝트 발표", startDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!, endDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!.addingTimeInterval(3600), isAllDay: false, calendarColor: UIColor.systemRed.cgColor),
            CalendarEvent(title: "운동", startDate: Calendar.current.date(byAdding: .day, value: 4, to: Date())!, endDate: Calendar.current.date(byAdding: .day, value: 4, to: Date())!.addingTimeInterval(3600), isAllDay: false, calendarColor: UIColor.systemPurple.cgColor)
        ],
        reminders: [
            ReminderItem(id: "1", title: "보고서 작성", dueDate: Date(), priority: 1, isCompleted: false, reminderType: .onDate),
            ReminderItem(id: "2", title: "이메일 확인", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, priority: 2, isCompleted: false, reminderType: .onDate),
            ReminderItem(id: "3", title: "회의 준비", dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!, priority: 3, isCompleted: false, reminderType: .onDate),
            ReminderItem(id: "4", title: "쇼핑 리스트", dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!, priority: 1, isCompleted: false, reminderType: .onDate)
        ]
    )
    
    WeeklyScheduleWidgetView(entry: sampleEntry)
        .frame(height: 158)
        .background(.haruWidgetBackground)
}