//
//  SmallCalendarWidgetView.swift
//  HaruViewWidget
//
//  Created by Claude on 8/26/25.
//

import SwiftUI
import Foundation

struct SmallCalendarWidgetView: View {
    let entry: Provider.Entry
    
    private let calendar = Calendar.current
    private let today = Date()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: adaptiveSpacing(for: geometry.size)) {
                // 월 헤더
                monthHeader(for: geometry.size)
                
                // 요일 헤더
                weekdayHeader(for: geometry.size)
                
                // 달력 그리드
                calendarGrid(for: geometry.size)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, adaptiveHorizontalPadding(for: geometry.size))
        }
    }
    
    // MARK: - 적응형 크기 조정 함수들
    private func adaptiveFontSize(_ baseSize: CGFloat, for size: CGSize) -> CGFloat {
        let scale = min(size.width / 158, size.height / 158) // iPhone 15 Pro 기준, width와 height 중 작은 값 사용
        return max(baseSize * 0.8, baseSize * scale)
    }
    
    private func adaptiveSpacing(for size: CGSize) -> CGFloat {
        let scale = min(size.width / 158, size.height / 158)
        return max(1, 2 * scale)
    }
    
    private func adaptiveHorizontalPadding(for size: CGSize) -> CGFloat {
        return 0 // 좌우 패딩 0으로 설정
    }
    
    private func adaptiveVerticalPadding(for size: CGSize) -> CGFloat {
        let scale = min(size.width / 158, size.height / 158)
        return max(4, 8 * scale) // 패딩 최소값과 비율 최적화
    }
    
    // MARK: - 월 헤더
    private func monthHeader(for size: CGSize) -> some View {
        HStack {
            Text(monthText)
                .font(.system(size: adaptiveFontSize(14, for: size), weight: .bold))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.bottom, 3)
        .padding(.leading, 5)
    }
    
    private var monthText: String {
        let currentLanguage = SharedUserDefaults.selectedLanguage
        let formatter = DateFormatter()
        
        switch currentLanguage {
        case "ko":
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "M월"
        case "en":
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "MMM"
        case "ja":
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "M月"
        default:
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "M월"
        }
        
        return formatter.string(from: today)
    }
    
    // MARK: - 요일 헤더
    private func weekdayHeader(for size: CGSize) -> some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { day in
                Text(day)
                    .font(.system(size: adaptiveFontSize(12, for: size), weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 2)
    }
    
    private var weekdaySymbols: [String] {
        let currentLanguage = SharedUserDefaults.selectedLanguage
        let weekStartDay = SharedUserDefaults.weekStartDay
        
        let symbols: [String]
        switch currentLanguage {
        case "ko":
            symbols = ["일", "월", "화", "수", "목", "금", "토"]
        case "en":
            symbols = ["S", "M", "T", "W", "T", "F", "S"]
        case "ja":
            symbols = ["日", "月", "火", "水", "木", "金", "土"]
        default:
            symbols = ["일", "월", "화", "수", "목", "금", "토"]
        }
        
        if weekStartDay == 1 {
            // 월요일 시작
            return Array(symbols[1...]) + [symbols[0]]
        } else {
            // 일요일 시작 (기본)
            return symbols
        }
    }
    
    // MARK: - 달력 그리드
    private func calendarGrid(for size: CGSize) -> some View {
        let spacing = adaptiveSpacing(for: size)
        
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: 7),
            spacing: spacing
        ) {
            ForEach(calendarDays, id: \.date) { dayInfo in
                calendarDayCell(dayInfo, size: size)
            }
        }
    }
    
    private func calendarDayCell(_ dayInfo: CalendarDayInfo, size: CGSize) -> some View {
        let cellSize = adaptiveCellSize(for: size)
        
        return VStack(spacing: dayInfo.isToday ? 1 : 0) {
            // 날짜 숫자 (빈 칸은 표시하지 않음)
            if dayInfo.day > 0 {
                Text("\(dayInfo.day)")
                    .font(.system(size: adaptiveFontSize(12.5, for: size), weight: .bold))
                    .foregroundStyle(textColor(for: dayInfo))
                    .frame(width: cellSize.width, height: cellSize.height)
                    .background(
                        RoundedRectangle(cornerRadius: cellSize.width * 0.35) // 코너 반경 조금 더 크게
                            .fill(backgroundColor(for: dayInfo))
                            .padding(.horizontal, -2) // 배경을 2pt씩 확장
                            .padding(.vertical, -1)
                    )
                    .padding(.top, dayInfo.isToday ? 1 : 0)
            } else {
                // 빈 공간
                Color.clear
                    .frame(width: cellSize.width, height: cellSize.height)
            }
            
            // 일정/할일 표시
            indicatorView(for: dayInfo, size: size)
        }
    }
    
    // MARK: - 색상 및 스타일 헬퍼
    private func textColor(for dayInfo: CalendarDayInfo) -> Color {
        if dayInfo.isToday {
            return .white
        } else if dayInfo.isWeekend {
            return .secondary
        } else {
            return .primary
        }
    }
    
    private func backgroundColor(for dayInfo: CalendarDayInfo) -> Color {
        if dayInfo.isToday {
            return Color(hexCode: "A76545") // 하루뷰 메인 갈색 (haruPrimary)
        } else {
            return .clear
        }
    }
    
    private func adaptiveCellSize(for size: CGSize) -> (width: CGFloat, height: CGFloat) {
        let spacing = adaptiveSpacing(for: size)
        
        // 사용 가능한 너비에서 셀 너비 계산 (좌우 패딩 0이므로 전체 너비 사용)
        let availableWidth = size.width
        let cellWidth = (availableWidth - (6 * spacing)) / 7 // 7개 셀, 6개 간격
        
        // 헤더들의 실제 높이 계산 (더 정확하게)
        let monthHeaderHeight = adaptiveFontSize(12, for: size) + 3
        let weekdayHeaderHeight = adaptiveFontSize(12, for: size) + 2
        let spacingBetweenElements = spacing * 2 // VStack spacing
        
        let totalHeaderHeight = monthHeaderHeight + weekdayHeaderHeight + spacingBetweenElements
        
        // 사용 가능한 높이에서 셀 높이 계산
        let availableHeight = size.height - totalHeaderHeight
        let maxRows: CGFloat = 6
        let gridSpacing = (maxRows - 1) * spacing
        let indicatorSpace: CGFloat = 4 // 인디케이터 + spacing
        
        // 실제 셀 영역 높이
        let cellAreaHeight = availableHeight - gridSpacing
        let rawCellHeight = (cellAreaHeight / maxRows) - indicatorSpace
        
        // 동적 비율 조정: 작은 화면에서는 더 작게, 큰 화면에서는 더 크게
        let sizeRatio = min(size.width / 158, size.height / 158)
        let widthMultiplier = sizeRatio > 1.0 ? 0.9 : 0.85 // 큰 화면에서는 더 여유롭게
        let heightMultiplier = sizeRatio > 1.0 ? 1.1 : 1  // 작은 화면에서는 더 컴팩트하게
        
        let finalWidth = cellWidth * widthMultiplier
        let finalHeight = rawCellHeight * heightMultiplier
        
        return (width: max(10, finalWidth), height: max(8, finalHeight))
    }
    
    private func indicatorView(for dayInfo: CalendarDayInfo, size: CGSize) -> some View {
        let indicatorWidth = adaptiveIndicatorWidth(for: size)
        
        return HStack(spacing: 1) {
            Spacer() // 왼쪽 여백
            
            // 일정 언더바
            if dayInfo.eventColor != nil {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(cgColor: dayInfo.eventColor!))
                    .frame(width: dayInfo.hasReminders ? indicatorWidth * 0.65 : indicatorWidth, 
                           height: max(1.5, 2 * min(size.width / 158, size.height / 158))) // 적응형 높이
            }
            
            // 할일 점
            if dayInfo.hasReminders {
                let dotSize = max(2.5, 3 * min(size.width / 158, size.height / 158)) // 적응형 점 크기
                Circle()
                    .fill(.secondary)
                    .frame(width: dotSize, height: dotSize)
            }
            
            Spacer() // 오른쪽 여백
        }
        .frame(height: max(3, 4 * min(size.width / 158, size.height / 158))) // 적응형 인디케이터 영역 높이
    }
    
    private func adaptiveIndicatorWidth(for size: CGSize) -> CGFloat {
        let scale = min(size.width / 158, size.height / 158)
        return max(8, 12 * scale)
    }
    
    // MARK: - 달력 데이터 생성
    private var calendarDays: [CalendarDayInfo] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: today) else {
            return []
        }
        
        let monthStart = monthInterval.start
        
        // 월의 첫 번째 날이 무슨 요일인지 확인
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        
        // 시작요일 설정에 따른 오프셋 계산
        let weekStartDay = SharedUserDefaults.weekStartDay
        
        let startOffset: Int
        if weekStartDay == 1 {
            // 월요일 시작 (1=일요일, 2=월요일, ..., 7=토요일)
            startOffset = (firstWeekday == 1) ? 6 : firstWeekday - 2
        } else {
            // 일요일 시작
            startOffset = firstWeekday - 1
        }
        
        var days: [CalendarDayInfo] = []
        
        // 이전 달 빈 공간들 (투명하게 처리)
        for _ in 0..<startOffset {
            days.append(CalendarDayInfo(
                date: Date.distantPast, // 더미 날짜
                day: 0, // 빈 칸 표시
                isCurrentMonth: false,
                isToday: false,
                isWeekend: false,
                eventColor: nil,
                hasReminders: false
            ))
        }
        
        // 현재 달 날짜들만 표시 (성능 최적화)
        let range = calendar.range(of: .day, in: .month, for: monthStart)!
        let currentMonthComponent = calendar.component(.month, from: today)
        let todayComponent = calendar.component(.day, from: today)
        
        for day in range {
            let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
            let weekday = calendar.component(.weekday, from: date)
            
            // 오늘 날짜 체크 최적화
            let isToday = (calendar.component(.month, from: date) == currentMonthComponent && 
                          day == todayComponent)
            
            // 주말 체크 (일요일=1, 토요일=7)
            let isWeekend = (weekday == 1) || (weekday == 7)
            
            days.append(CalendarDayInfo(
                date: date,
                day: day,
                isCurrentMonth: true,
                isToday: isToday,
                isWeekend: isWeekend,
                eventColor: eventColor(for: date),
                hasReminders: hasReminders(for: date)
            ))
        }
        
        // 나머지 빈 공간들도 투명하게 처리
        let totalCells = ((startOffset + range.count - 1) / 7 + 1) * 7 // 필요한 주 수 계산
        let remainingCells = totalCells - days.count
        
        for _ in 0..<remainingCells {
            days.append(CalendarDayInfo(
                date: Date.distantFuture, // 더미 날짜
                day: 0, // 빈 칸 표시
                isCurrentMonth: false,
                isToday: false,
                isWeekend: false,
                eventColor: nil,
                hasReminders: false
            ))
        }
        
        return days
    }
    
    
    // MARK: - 일정 색상 가져오기
    private func eventColor(for date: Date) -> CGColor? {
        // 더 간단한 날짜 비교 방식으로 변경
        for event in entry.events {
            // 시작일 또는 종료일이 해당 날짜에 포함되는지 확인
            if calendar.isDate(event.startDate, inSameDayAs: date) ||
               calendar.isDate(event.endDate, inSameDayAs: date) ||
               (event.startDate < date && event.endDate > date) { // 여러 날에 걸친 이벤트
                return event.calendarColor
            }
        }
        return nil
    }
    
    // MARK: - 할일 확인하기
    private func hasReminders(for date: Date) -> Bool {
        // 더 간단한 날짜 비교 방식으로 변경
        for reminder in entry.reminders {
            if let dueDate = reminder.dueDate,
               calendar.isDate(dueDate, inSameDayAs: date) {
                return true
            }
        }
        return false
    }
}

// MARK: - 달력 데이터 모델
struct CalendarDayInfo {
    let date: Date
    let day: Int
    let isCurrentMonth: Bool
    let isToday: Bool
    let isWeekend: Bool
    let eventColor: CGColor?
    let hasReminders: Bool
}

#Preview("Small Calendar Widget - iPhone 15 Pro") {
    let sampleEntry = SimpleEntry(
        date: Date(),
        configuration: {
            let config = ConfigurationAppIntent()
            config.viewType = .calendar
            return config
        }(),
        events: [
            CalendarEvent(title: "팀 미팅", startDate: Date(), endDate: Date().addingTimeInterval(3600), isAllDay: false, calendarColor: UIColor.systemBlue.cgColor),
            CalendarEvent(title: "점심 약속", startDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, endDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!.addingTimeInterval(3600), isAllDay: false, calendarColor: UIColor.systemGreen.cgColor),
            CalendarEvent(title: "회의", startDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!, endDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!.addingTimeInterval(3600), isAllDay: false, calendarColor: UIColor.systemRed.cgColor)
        ],
        reminders: [
            ReminderItem(id: "1", title: "할일 1", dueDate: Date(), priority: 1, isCompleted: false, reminderType: .onDate),
            ReminderItem(id: "2", title: "할일 2", dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!, priority: 2, isCompleted: false, reminderType: .onDate)
        ]
    )
    
    VStack(spacing: 10) {
        // iPhone 15 Pro Max
        SmallCalendarWidgetView(entry: sampleEntry)
            .frame(width: 170, height: 170)
            .background(.haruWidgetBackground)
            .cornerRadius(16)
        
        Text("iPhone 15 Pro Max (170x170)")
            .font(.caption)
        
        // iPhone 15 Pro / iPhone 15
        SmallCalendarWidgetView(entry: sampleEntry)
            .frame(width: 158, height: 158)
            .background(.haruWidgetBackground)
            .cornerRadius(16)
        
        Text("iPhone 15 Pro (158x158)")
            .font(.caption)
        
        // iPhone SE
        SmallCalendarWidgetView(entry: sampleEntry)
            .frame(width: 148, height: 148)
            .background(.haruWidgetBackground)
            .cornerRadius(16)
        
        Text("iPhone SE (148x148)")
            .font(.caption)
    }
}
