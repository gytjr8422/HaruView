//
//  ReminderCard.swift
//  HaruView
//
//  Created by 김효석 on 5/14/25.
//

import SwiftUI

struct ReminderCard: View {
    let reminder: Reminder
    let onToggle: () -> Void
    
    var priorityColor: Color {
        switch reminder.priority {
        case 1:
            return Color(hexCode: "FF5722")
        case 5:
            return Color(hexCode: "FFC107")
        case 9:
            return Color(hexCode: "4CAF50")
        default:
            return .secondary
        }
    }
    
    var prioritySymbol: String {
        switch reminder.priority {
        case 1:
            return "exclamationmark.3"  // 높은 우선순위
        case 5:
            return "exclamationmark.2"  // 보통 우선순위
        case 9:
            return "exclamationmark"    // 낮은 우선순위
        default:
            return "minus"              // 우선순위 없음
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(reminder.isCompleted ? Color(hexCode: "A76545") : .secondary)
                .font(.custom("", size: 22))
                .onTapGesture { onToggle() }
                .animation(.smooth, value: 1)
                .padding(.trailing, 2)
            
            if reminder.priority > 0 {
                Image(systemName: prioritySymbol)
                    .foregroundStyle(priorityColor)
                    .opacity(reminder.isCompleted ? 0.5 : 1)
            }
            
            HStack {
                HStack(spacing: 4) {
                    Text(reminder.title)
                        .lineLimit(1)
                        .font(.pretendardRegular(size: 17))
                        .strikethrough(reminder.isCompleted)
                        .opacity(reminder.isCompleted ? 0.5 : 1)
                }
                Spacer()
                // 타입별 상태 텍스트
                if reminder.reminderType == .untilDate, let due = reminder.due {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    let dueDate = calendar.startOfDay(for: due)
                    let daysLeft = calendar.dateComponents([.day], from: today, to: dueDate).day ?? 0
                    if daysLeft > 0 {
                        Text("D-\(daysLeft)")
                            .font(.jakartaRegular(size: 15))
                            .foregroundStyle(Color(hexCode: "A76545"))
                            .opacity(reminder.isCompleted ? 0.4 : 1)
                    } else if daysLeft == 0 {
                        Text("D-Day")
                            .font(.jakartaRegular(size: 15))
                            .foregroundStyle(Color(hexCode: "FF5722"))
                            .opacity(reminder.isCompleted ? 0.4 : 1)
                    }
                }
            }
            
            Spacer()
            
            // "특정 날짜에" 설정되고 "날짜+시간"인 할일만 시간 표시
            if let due = reminder.due, reminder.reminderType == .onDate, reminder.includeTime {
                Text(DateFormatter.localizedString(from: due, dateStyle: .none, timeStyle: .short))
                    .lineLimit(1)
                    .font(.jakartaRegular(size: 15))
                    .foregroundStyle(Color(hexCode: "2E2514").opacity(0.8))
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}

#Preview {
    ReminderCard(
        reminder: Reminder(
            id: "",
            title: "타이틀",
            due: Date(),
            isCompleted: false,
            priority: 0,
            notes: nil,
            url: nil,
            location: nil,
            hasAlarms: false,
            alarms: [],
            calendar: ReminderCalendar(
                id: "preview",
                title: "미리보기",
                color: CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),
                type: .local,
                isReadOnly: false,
                allowsContentModifications: true,
                source: ReminderCalendar.CalendarSource(title: "로컬", type: .local)
            )
        ),
        onToggle: {}
    )
}
