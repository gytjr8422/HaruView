//
//  LargeMonthlyCalendarWidget.swift
//  HaruViewWidget
//
//  Created by Claude on 8/28/25.
//

import SwiftUI
import Foundation

// MARK: - Display Item
struct DisplayItem: Identifiable {
    let id: String
    let title: String
    let color: CGColor
    let isCompleted: Bool
    let isContinuous: Bool
    let isStart: Bool
    let isEnd: Bool
    let showTitle: Bool
    
    init(id: String, title: String, color: CGColor, isCompleted: Bool = false, isContinuous: Bool = false, isStart: Bool = false, isEnd: Bool = false, showTitle: Bool = true) {
        self.id = id
        self.title = title
        self.color = color
        self.isCompleted = isCompleted
        self.isContinuous = isContinuous
        self.isStart = isStart
        self.isEnd = isEnd
        self.showTitle = showTitle
    }
}

struct LargeMonthlyCalendarWidget: View {
    let entry: Provider.Entry
    
    private let calendar = Calendar.withUserWeekStartPreference()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    var body: some View {
        VStack(spacing: 2) {
            // 월 헤더
            monthHeader
            
            // 요일 헤더  
            weekdayHeader
            
            // 달력 그리드
            calendarGrid
            
        }
    }
    
    // MARK: - Month Header
    private var monthHeader: some View {
        Text(monthString)
            .font(monthHeaderFont)
            .foregroundStyle(Color.primary)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity)
            .frame(height: 22)
    }
    
    // MARK: - Weekday Header
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { weekday in
                Text(weekday)
                    .font(.pretendardRegular(size: 9))
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 14)
            }
        }
        .frame(height: 20)
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 0) { // spacing을 0으로 변경
            ForEach(monthDates, id: \.self) { date in
                CompactDayCell(
                    date: date,
                    events: eventsFor(date),
                    reminders: remindersFor(date),
                    isToday: calendar.isDateInToday(date),
                    isCurrentMonth: isCurrentMonth(date)
                )
                .frame(height: 47) // 셀 높이 고정 (텍스트 잘림 방지를 위해 충분한 높이)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// 월 표시 문자열
    private var monthString: String {
        let currentLanguage = SharedUserDefaults.selectedLanguage
        let formatter = DateFormatter()
        let today = Date()
        
        switch currentLanguage {
        case "ko":
            formatter.dateFormat = "yyyy년 M월"
            formatter.locale = Locale(identifier: "ko_KR")
        case "ja":
            formatter.dateFormat = "yyyy年M月"
            formatter.locale = Locale(identifier: "ja_JP")
        default:
            formatter.dateFormat = "MMMM yyyy"
            formatter.locale = Locale(identifier: "en_US")
        }
        
        return formatter.string(from: today)
    }
    
    /// 언어별 최적화된 헤더 폰트
    private var monthHeaderFont: Font {
        let currentLanguage = SharedUserDefaults.selectedLanguage
        
        switch currentLanguage {
        case "ja":
            // 일본어는 시스템 폰트 사용 (더 컴팩트함)
            return .system(size: 13, weight: .semibold)
        default:
            // 다른 언어는 기존 Pretendard 폰트
            return .pretendardSemiBold(size: 13)
        }
    }
    
    /// 요일 심볼 배열 (앱의 주 시작일 설정 반영)
    private var weekdaySymbols: [String] {
        let currentLanguage = SharedUserDefaults.selectedLanguage
        let weekStartsOnMonday = SharedUserDefaults.weekStartDay == 1 // 1=월요일, 0=일요일
        
        let symbols: [String]
        switch currentLanguage {
        case "ko":
            symbols = weekStartsOnMonday ? 
                ["월", "화", "수", "목", "금", "토", "일"] : 
                ["일", "월", "화", "수", "목", "금", "토"]
        case "ja":
            symbols = weekStartsOnMonday ? 
                ["月", "火", "水", "木", "金", "土", "日"] : 
                ["日", "月", "火", "水", "木", "金", "土"]
        case "en":
            symbols = weekStartsOnMonday ? 
                ["M", "T", "W", "T", "F", "S", "S"] : 
                ["S", "M", "T", "W", "T", "F", "S"]
        default:
            symbols = weekStartsOnMonday ? 
                ["월", "화", "수", "목", "금", "토", "일"] : 
                ["일", "월", "화", "수", "목", "금", "토"]
        }
        
        return symbols
    }
    
    /// 월간 날짜 배열 (42개 - 6주 × 7일)
    private var monthDates: [Date] {
        let today = Date()
        let calendar = Calendar.withUserWeekStartPreference()
        
        // 현재 월의 첫 번째 날
        guard let monthStart = calendar.dateInterval(of: .month, for: today)?.start else {
            return []
        }
        
        // 첫 번째 날이 속한 주의 시작일
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: monthStart)?.start else {
            return []
        }
        
        // 42일 생성 (6주)
        var dates: [Date] = []
        for i in 0..<42 {
            if let date = calendar.date(byAdding: .day, value: i, to: weekStart) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    // MARK: - Helper Methods
    
    /// 특정 날짜의 일정 반환 (연속 일정 포함)
    private func eventsFor(_ date: Date) -> [CalendarEvent] {
        let calendar = Calendar.withUserWeekStartPreference()
        let targetDay = calendar.startOfDay(for: date)
        
        return entry.events.filter { event in
            let eventStartDay = calendar.startOfDay(for: event.startDate)
            let eventEndDay = calendar.startOfDay(for: event.endDate)
            
            // 해당 날짜가 이벤트 기간에 포함되는지 확인 (연속 일정 지원)
            return targetDay >= eventStartDay && targetDay <= eventEndDay
        }.sorted { event1, event2 in
            // 시간순 정렬
            event1.startDate < event2.startDate
        }.prefix(4).map { $0 }
    }
    
    /// 특정 날짜의 할일 반환
    private func remindersFor(_ date: Date) -> [ReminderItem] {
        let calendar = Calendar.withUserWeekStartPreference()
        let targetDay = calendar.startOfDay(for: date)
        
        return entry.reminders.filter { reminder in
            guard let dueDate = reminder.dueDate else { return false }
            let reminderDay = calendar.startOfDay(for: dueDate)
            
            // ReminderType에 따른 필터링
            switch reminder.reminderType {
            case .onDate:
                // 정확한 날짜 매칭
                return calendar.isDate(reminderDay, inSameDayAs: targetDay)
            case .untilDate:
                // 마감일까지 계속 표시
                return reminderDay >= targetDay && !reminder.isCompleted
            }
        }.sorted { reminder1, reminder2 in
            // 중요도순, 그 다음 시간순
            if reminder1.priority != reminder2.priority {
                return reminder1.priority > reminder2.priority
            }
            return (reminder1.dueDate ?? Date.distantFuture) < (reminder2.dueDate ?? Date.distantFuture)
        }.prefix(4).map { $0 }
    }
    
    /// 현재 월에 속하는 날짜인지 확인
    private func isCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.withUserWeekStartPreference()
        let today = Date()
        return calendar.isDate(date, equalTo: today, toGranularity: .month)
    }
}

// MARK: - Compact Day Cell
struct CompactDayCell: View {
    let date: Date
    let events: [CalendarEvent]
    let reminders: [ReminderItem]
    let isToday: Bool
    let isCurrentMonth: Bool
    
    private let calendar = Calendar.withUserWeekStartPreference()
    
    var body: some View {
        VStack(spacing: 1) {
            // 날짜 숫자
            Text(dayNumber)
                .font(.system(size: 11, weight: isToday ? .bold : .medium))
                .foregroundStyle(dayNumberColor)
                .frame(height: 14)
            
            // 일정/할일 리스트 영역
            itemsListView
                .frame(maxHeight: 30)
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(isToday ? .blue.opacity(0.1) : .clear)
        )
        .opacity(isCurrentMonth ? 1.0 : 0.5)
    }
    
    // MARK: - Computed Properties
    
    private var dayNumber: String {
        String(calendar.component(.day, from: date))
    }
    
    private var itemsListView: some View {
        VStack(spacing: 0) { // spacing을 0으로 변경하여 연속 이벤트가 끊김없이 연결되도록
            // 실제 일정/할일 표시
            ForEach(Array(displayItems.prefix(3).enumerated()), id: \.element.id) { index, item in
                itemRowView(item: item)
            }
            
            // 빈 슬롯 채우기 (일관된 높이 유지)  
            ForEach(displayItems.prefix(3).count..<3, id: \.self) { _ in
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 9)
            }
            
            // +N개 더 표시 (제거)
        }
    }
    
    @ViewBuilder
    private func itemRowView(item: DisplayItem) -> some View {
        if item.isContinuous {
            // 연속 일정
            ContinuousEventBarWidget(item: item)
                .frame(height: 9)
        } else {
            // 일반 일정/할일
            HStack(spacing: 2) {
                // 왼쪽 색상 인디케이터 (앱과 동일)
                Rectangle()
                    .fill(Color(item.color))
                    .frame(width: 2)
                
                // 제목 텍스트 - Canvas로 앱과 동일하게 처리
                if !item.title.isEmpty {
                    Canvas { context, size in
                        let text = Text(item.title)
                            .font(.pretendardRegular(size: 7))
                            .foregroundStyle(
                                item.isCompleted ?
                                Color.secondary.opacity(0.5) :
                                Color.primary
                            )
                        
                        context.draw(text, at: CGPoint(x: 0, y: size.height / 2), anchor: .leading)
                    }
                    .clipped()
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(item.color).opacity(0.1))
            )
            .frame(height: 9)
        }
    }
    
    
    private var dayNumberColor: Color {
        if isToday {
            return .blue
        } else if !isCurrentMonth {
            return Color.secondary.opacity(0.4)
        } else {
            return weekdayColor
        }
    }
    
    private var weekdayColor: Color {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        switch weekday {
        case 1: return .red               // 일요일
        case 7: return .blue              // 토요일
        default: return Color.primary     // 평일
        }
    }
    
    /// 표시할 아이템들 (일정 + 할일 통합, 연속 일정 처리)
    private var displayItems: [DisplayItem] {
        var items: [DisplayItem] = []
        
        // 일정 추가 (연속 일정 처리 포함)
        for (index, event) in events.enumerated() {
            let startDate = calendar.startOfDay(for: event.startDate)
            let endDate = calendar.startOfDay(for: event.endDate)
            let currentDate = calendar.startOfDay(for: date)
            
            // 여러 날에 걸친 일정인지 확인
            if startDate < endDate && calendar.dateComponents([.day], from: startDate, to: endDate).day! > 0 {
                // 연속 일정
                let isStart = calendar.isDate(currentDate, inSameDayAs: startDate)
                let isEnd = calendar.isDate(currentDate, inSameDayAs: endDate)
                
                // 주 내 위치 계산 (사용자 설정에 따른 주 시작일 반영)
                let weekday = calendar.component(.weekday, from: currentDate)
                let weekPosition = (weekday - calendar.firstWeekday + 7) % 7
                
                // 제목 표시 여부 결정: 시작일이거나 주의 시작일
                let showTitle = isStart || weekPosition == 0
                
                items.append(DisplayItem(
                    id: "continuous_\(event.title)_\(index)",
                    title: event.title,
                    color: event.calendarColor,
                    isContinuous: true,
                    isStart: isStart,
                    isEnd: isEnd,
                    showTitle: showTitle
                ))
            } else {
                // 단일 날짜 일정
                items.append(DisplayItem(
                    id: "single_\(event.title)_\(index)",
                    title: event.title,
                    color: event.calendarColor
                ))
            }
        }
        
        // 할일 추가
        for reminder in reminders {
            items.append(DisplayItem(
                id: reminder.id,
                title: reminder.title,
                color: CGColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1.0), // 할일 기본 색상
                isCompleted: reminder.isCompleted
            ))
        }
        
        // 연속 일정을 상단으로 우선 정렬
        let sortedItems = items.sorted { item1, item2 in
            let isContinuous1 = item1.isContinuous
            let isContinuous2 = item2.isContinuous
            
            // 연속 일정이 우선
            if isContinuous1 != isContinuous2 {
                return isContinuous1
            }
            
            // 둘 다 연속 이벤트이거나 둘 다 일반 아이템인 경우 기존 순서 유지
            return false
        }
        
        // 최대 3개로 제한 (위젯이므로 적게)
        return Array(sortedItems.prefix(3))
    }
}

// MARK: - 연속 이벤트 바 위젯 컴포넌트
struct ContinuousEventBarWidget: View {
    let item: DisplayItem
    
    var body: some View {
        GeometryReader { geometry in
            let cellWidth = geometry.size.width
            let barHeight = geometry.size.height
            
            // 연속 배경의 시작/끝에 따라 확장
            let extraWidth: CGFloat = 8 // 셀 경계를 넘어서는 너비
            let xOffset: CGFloat = item.isStart ? 0 : -extraWidth
            let barWidth: CGFloat = cellWidth + (item.isStart ? 0 : extraWidth) + (item.isEnd ? 0 : extraWidth)
            
            ZStack(alignment: .leading) {
                // 연결된 배경
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(item.color).opacity(0.1))
                    .frame(width: barWidth, height: barHeight)
                    .offset(x: xOffset)
                
                // 왼쪽 색상 인디케이터 (시작일이거나 제목을 표시하는 날)
                if item.isStart || item.showTitle {
                    Rectangle()
                        .fill(Color(item.color))
                        .frame(width: 2, height: barHeight)
                        .offset(x: 2) // 일반 일정의 padding과 맞춤
                }
                
                // 텍스트 (제목 표시할 때만)
                if item.showTitle && !item.title.isEmpty {
                    HStack {
                        if item.isStart || item.showTitle {
                            Spacer().frame(width: 4) // 색상바 오프셋(2) + spacing(2) 
                        }
                        
                        Canvas { context, size in
                            let text = Text(item.title)
                                .font(.pretendardRegular(size: 7))
                                .foregroundStyle(Color.primary)
                            
                            context.draw(text, at: CGPoint(x: 0, y: size.height / 2), anchor: .leading)
                        }
                        .clipped()
                        
                        Spacer()
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .frame(height: 9)
        .clipped()
    }
}

#Preview {
    LargeMonthlyCalendarWidget(
        entry: SimpleEntry(
            date: .now,
            configuration: ConfigurationAppIntent(),
            events: [],
            reminders: []
        )
    )
    .frame(width: 364, height: 379)
    .background(.haruWidgetBackground)
}
