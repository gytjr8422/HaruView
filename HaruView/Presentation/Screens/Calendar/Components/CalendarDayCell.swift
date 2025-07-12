//
//  CalendarDayCell.swift
//  HaruView
//
//  Created by 김효석 on 7/8/25.
//

import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let calendarDay: CalendarDay?
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    private var dayNumber: String {
        String(Calendar.current.component(.day, from: date))
    }
    
    private var displayItems: [CalendarDisplayItem] {
        calendarDay?.displayItems ?? []
    }
    
    // 표시할 아이템 개수 로직 변경
    private var itemsToShow: [CalendarDisplayItem] {
        if displayItems.count <= 4 {
            // 4개 이하면 모두 표시
            return Array(displayItems)
        } else {
            // 5개 이상이면 3개만 표시
            return Array(displayItems.prefix(3))
        }
    }
    
    private var extraItemCount: Int {
        calendarDay?.extraItemCount ?? 0
    }
    
    var body: some View {
        VStack(spacing: 2) {
            // 날짜 숫자
            ZStack {
                // 선택된 날짜 배경
                if isSelected {
                    Circle()
                        .fill(Color(hexCode: "A76545"))
                        .frame(width: 28, height: 28)
                }
                
                // 오늘 날짜 배경 (선택되지 않은 경우)
                if isToday && !isSelected {
                    Circle()
                        .stroke(Color(hexCode: "A76545"), lineWidth: 2)
                        .frame(width: 28, height: 28)
                }
                
                Text(dayNumber)
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundStyle(
                        isSelected ? .white :
                        isToday ? Color(hexCode: "A76545") :
                        !isCurrentMonth ? Color(hexCode: "6E5C49").opacity(0.3) :
                        Color(hexCode: "40392B")
                    )
            }
            .frame(height: 32)
            .padding(.top, 2)
            
            // 일정 표시 바들 (고정 높이)
            VStack(spacing: 3) {
                ForEach(Array(itemsToShow.enumerated()), id: \.element.id) { index, item in
                    EventBar(
                        item: item,
                        isCompact: true
                    )
                    .frame(height: eventBarHeight)
                }
                
                // 5개 이상일 때는 3개만 표시하므로 1개 빈 공간, 4개 이하일 때는 4개까지 채움
                let maxSlots = displayItems.count > 4 ? 3 : 4
                ForEach(itemsToShow.count..<maxSlots, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: eventBarHeight)
                }
            }
            
            Spacer(minLength: 0)
            
            // 추가 개수 표시 (하단에 작게)
            if extraItemCount > 0 {
                extraCountView
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: fixedCellHeight) // 고정 높이 사용
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    isSelected ? Color(hexCode: "A76545").opacity(0.05) :
                    Color.clear
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
        .opacity(isCurrentMonth ? 1.0 : 0.4)
    }
    
    // 고정 셀 높이 (높이 증가)
    private let fixedCellHeight: CGFloat = 98 // 40(날짜) + 54(일정 4개) + 14(여백)
    
    // 일정 바 고정 높이 (원래 적당했던 크기)
    private let eventBarHeight: CGFloat = 12 // 원래 크기로 복원
    
    // 전체 일정 영역 높이 (4개 × 12pt + 3개 간격(2pt) = 54pt)
    private let totalEventAreaHeight: CGFloat = 54
    
    // +N개 더 표시를 위한 작은 텍스트 뷰 (필요시)
    @ViewBuilder
    private var extraCountView: some View {
        if extraItemCount > 0 {
            Text("+\(extraItemCount)")
                .font(.pretendardRegular(size: 8))
                .foregroundStyle(Color(hexCode: "6E5C49").opacity(0.8))
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(
                    Capsule()
                        .fill(Color(hexCode: "6E5C49").opacity(0.15))
                )
                .padding(.bottom, 2)
        }
    }
    
    // 기존 동적 높이 계산 (참고용으로 보존)
    private var calendarCellHeight: CGFloat {
        let baseHeight: CGFloat = 40 // 날짜 + 여백
        let itemCount = min(displayItems.count, 4)
        let extraHeight = itemCount > 0 ? CGFloat(itemCount) * 16 + 8 : 0 // 일정 바 높이
        let extraCountHeight = extraItemCount > 0 ? 16 : 0 // +N 표시 높이
        
        return baseHeight + extraHeight + CGFloat(extraCountHeight)
    }
}

// MARK: - 일정 표시 바 컴포넌트
struct EventBar: View {
    let item: CalendarDisplayItem
    let isCompact: Bool
    
    var body: some View {
        HStack(spacing: 2) {
            // 왼쪽 색상 인디케이터
            switch item {
            case .event(_:):
                Rectangle()
                    .fill(Color(item.color))
                    .frame(width: 2)
            case .reminder(_):
                EmptyView()
            }
            
            // 제목 텍스트
            Text(item.title)
                .font(.pretendardRegular(size: isCompact ? 9 : 11))
                .foregroundStyle(
                    item.isCompleted ?
                    Color(hexCode: "6E5C49").opacity(0.5) :
                    Color(hexCode: "40392B")
                )
                .strikethrough(item.isCompleted)
                .lineLimit(1)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 1)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(item.color).opacity(0.1))
        )
    }
}

// MARK: - Preview
#Preview("Empty Day") {
    CalendarDayCell(
        date: Date(),
        calendarDay: nil,
        isSelected: false,
        isToday: false,
        isCurrentMonth: true,
        onTap: {},
        onLongPress: {}
    )
    .frame(width: 50, height: 80)
}

#Preview("Today with Events") {
    let testCalendar = EventCalendar(
        id: "test",
        title: "테스트",
        color: CGColor(red: 0.2, green: 0.6, blue: 0.8, alpha: 1.0),
        type: .local,
        isReadOnly: false,
        allowsContentModifications: true,
        source: EventCalendar.CalendarSource(title: "로컬", type: .local)
    )
    
    let testReminderCalendar = ReminderCalendar(
        id: "test-reminder",
        title: "테스트 리마인더",
        color: CGColor(red: 0.8, green: 0.4, blue: 0.2, alpha: 1.0),
        type: .local,
        isReadOnly: false,
        allowsContentModifications: true,
        source: ReminderCalendar.CalendarSource(title: "로컬", type: .local)
    )
    
    let events = [
        Event(
            id: "1",
            title: "팀 회의",
            start: Date(),
            end: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!,
            calendarTitle: "업무",
            calendarColor: CGColor(red: 0.2, green: 0.6, blue: 0.8, alpha: 1.0),
            location: nil,
            notes: nil,
            url: nil,
            hasAlarms: false,
            alarms: [],
            hasRecurrence: false,
            recurrenceRule: nil,
            calendar: testCalendar,
            structuredLocation: nil
        )
    ]
    
    let reminders = [
        Reminder(
            id: "r1",
            title: "장보기",
            due: Date(),
            isCompleted: false,
            priority: 1,
            notes: nil,
            url: nil,
            location: nil,
            hasAlarms: false,
            alarms: [],
            calendar: testReminderCalendar
        )
    ]
    
    CalendarDayCell(
        date: Date(),
        calendarDay: CalendarDay(date: Date(), events: events, reminders: reminders),
        isSelected: false,
        isToday: true,
        isCurrentMonth: true,
        onTap: {},
        onLongPress: {}
    )
    .frame(width: 50, height: 100)
}
