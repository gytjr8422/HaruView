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
        let calendar = Calendar.current
        
        // 일정 변환 (연속 일정 처리 포함)
        for event in events {
            let isOngoing = event.startDate <= now && event.endDate > now
            let priority = isOngoing ? 0 : (event.isAllDay ? 2 : 1)
            
            // 연속 일정 여부 확인
            let startDate = calendar.startOfDay(for: event.startDate)
            let endDate = calendar.startOfDay(for: event.endDate)
            let currentDate = calendar.startOfDay(for: date)
            let isContinuous = startDate < endDate && calendar.dateComponents([.day], from: startDate, to: endDate).day! > 0
            
            if isContinuous {
                // 연속 일정
                let isStart = calendar.isDate(currentDate, inSameDayAs: startDate)
                let isEnd = calendar.isDate(currentDate, inSameDayAs: endDate)
                
                // 주 내 위치 계산
                let weekday = calendar.component(.weekday, from: currentDate)
                let weekPosition = (weekday - calendar.firstWeekday + 7) % 7
                let showTitle = isStart || weekPosition == 0
                
                items.append(WeeklyItem(
                    title: event.title,
                    type: .continuousEvent,
                    priority: priority,
                    startTime: event.startDate,
                    color: event.calendarColor,
                    isCompleted: event.endDate < now,
                    isContinuous: true,
                    isStart: isStart,
                    isEnd: isEnd,
                    showTitle: showTitle
                ))
            } else {
                // 단일 날짜 일정
                items.append(WeeklyItem(
                    title: event.title,
                    type: .event,
                    priority: priority,
                    startTime: event.startDate,
                    color: event.calendarColor,
                    isCompleted: event.endDate < now
                ))
            }
        }
        
        // 할일 변환 (완료되지 않은 것만)
        for reminder in reminders.filter({ !$0.isCompleted }) {
            items.append(WeeklyItem(
                title: reminder.title,
                type: .reminder,
                priority: 3,
                startTime: reminder.dueDate ?? date,
                color: CGColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0), // 할일 기본 색상
                isCompleted: false
            ))
        }
        
        // 정렬: 연속 일정 우선, 우선순위 -> 시작시간 순
        items.sort { first, second in
            // 연속 일정이 우선
            if first.isContinuous != second.isContinuous {
                return first.isContinuous
            }
            
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
                WeeklyItemRow(item: item)
            }
            
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .background(dayData.isToday ? Color.haruPrimary.opacity(0.1) : Color.clear)
    }
}

struct WeeklyItemRow: View {
    let item: WeeklyItem
    
    var body: some View {
        if item.type == .continuousEvent {
            // 연속 일정 - 달력과 동일한 스타일
            continuousEventView
        } else {
            // 일반 일정과 할일 - 기존 스타일
            regularItemView
        }
    }
    
    private var continuousEventView: some View {
        GeometryReader { geometry in
            let cellWidth = geometry.size.width
            let barHeight = geometry.size.height
            
            // 연속 배경의 시작/끝에 따라 확장
            let extraWidth: CGFloat = 15 // 더 크게 확장하여 곡률 숨김
            let xOffset: CGFloat = item.isStart ? 0 : -extraWidth
            let barWidth: CGFloat = cellWidth + (item.isStart ? 0 : extraWidth) + (item.isEnd ? 0 : extraWidth)
            
            ZStack(alignment: .leading) {
                // 연결된 배경 - 곡률 없이 직사각형으로 단순화
                Rectangle()
                    .fill(Color(cgColor: item.color!).opacity(0.1))
                    .frame(width: barWidth, height: barHeight)
                    .offset(x: xOffset)
                
                // 왼쪽 색상 인디케이터 (시작일이거나 제목을 표시하는 날)
                if item.isStart || item.showTitle {
                    Rectangle()
                        .fill(Color(cgColor: item.color!))
                        .frame(width: 2, height: barHeight)
                        .offset(x: 2)
                        .opacity(item.isCompleted ? 0.5 : 1)
                }
                
                // 텍스트 (제목 표시할 때만)
                if item.showTitle && !item.title.isEmpty {
                    HStack {
                        if item.isStart || item.showTitle {
                            Spacer().frame(width: 4)
                        }
                        
                        Canvas { context, size in
                            let textColor = getTextColor()
                            let text = Text(item.title)
                                .font(.pretendardRegular(size: 8))
                                .foregroundStyle(textColor)
                            
                            context.draw(text, at: CGPoint(x: 0, y: size.height / 2), anchor: .leading)
                        }
                        .clipped()
                        
                        Spacer()
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .frame(height: 12)
        .clipped()
    }
    
    private var regularItemView: some View {
        HStack(spacing: 2) {
            // 왼쪽 색상 인디케이터/아이콘
            if item.type == .event, let color = item.color {
                Rectangle()
                    .fill(Color(cgColor: color))
                    .frame(width: 2)
                    .opacity(item.isCompleted ? 0.5 : 1)
            } else if item.type == .reminder {
                // 할일은 작은 원 표시
                Circle()
                    .stroke(Color.secondary, lineWidth: 0.8)
                    .frame(width: 6, height: 6)
                    .opacity(item.isCompleted ? 0.5 : 1)
            } else {
                Spacer().frame(width: 2)
            }
            
            // 텍스트
            Canvas { context, size in
                let textColor = getTextColor()
                let text = Text(item.title)
                    .font(.pretendardRegular(size: 8))
                    .foregroundStyle(textColor)
                
                context.draw(text, at: CGPoint(x: 0, y: size.height / 2), anchor: .leading)
            }
            .clipped()
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 1)
        .background(backgroundView)
        .frame(height: 12)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if item.type == .event, let color = item.color {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(cgColor: color).opacity(0.1))
        } else {
            Color.clear
        }
    }
    
    private func getTextColor() -> Color {
        if item.isCompleted {
            return item.type == .event || item.type == .continuousEvent ? 
                .haruWidgetText.opacity(0.5) : 
                .haruWidgetSecondary.opacity(0.5)
        } else {
            return item.type == .event || item.type == .continuousEvent ? 
                .haruWidgetText : 
                .haruWidgetSecondary
        }
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
    let isContinuous: Bool
    let isStart: Bool
    let isEnd: Bool
    let showTitle: Bool
    
    init(title: String, type: WeeklyItemType, priority: Int, startTime: Date, color: CGColor?, isCompleted: Bool, 
         isContinuous: Bool = false, isStart: Bool = false, isEnd: Bool = false, showTitle: Bool = true) {
        self.title = title
        self.type = type
        self.priority = priority
        self.startTime = startTime
        self.color = color
        self.isCompleted = isCompleted
        self.isContinuous = isContinuous
        self.isStart = isStart
        self.isEnd = isEnd
        self.showTitle = showTitle
    }
}

enum WeeklyItemType {
    case event
    case continuousEvent
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