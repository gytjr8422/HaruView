//
//  SmallWidgetView.swift
//  SmallWidgetView
//
//  Created by 김효석 on 6/20/25.
//

import SwiftUI

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
                Text("일정이 없습니다")
                    .font(.pretendardRegular(size: 11))
                    .foregroundColor(.gray)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(entry.events.prefix(4).enumerated()), id: \.offset) { index, event in
                    let isPast = event.endDate < Date()
                    
                    HStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(hexCode: "A76545"))
                            .frame(width: 4)
                            .frame(maxHeight: 25)
                            .opacity(isPast ? 0.5 : 1)
                        
                        VStack(alignment: .leading) {
                            Text(event.title)
                                .font(.pretendardBold(size: 13))
                                .lineLimit(1)
                                .foregroundColor(Color(hexCode: "40392B"))
                                .strikethrough(isPast)
                                .opacity(isPast ? 0.5 : 1)
                            
                            if !event.isAllDay {
                                Text(event.startDate, style: .time)
                                    .font(.jakartaRegular(size: 11))
                                    .foregroundColor(.gray)
                                    .opacity(isPast ? 0.5 : 1)
                            } else {
                                Text("하루 종일")
                                    .font(.jakartaRegular(size: 9))
                                    .foregroundColor(.gray)
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

struct SmallRemindersWidget: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            
            if entry.reminders.isEmpty {
                Text("할 일이 없습니다")
                    .font(.pretendardRegular(size: 11))
                    .foregroundColor(.gray)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(entry.reminders.prefix(4).enumerated()), id: \.offset) { index, reminder in
                    HStack(spacing: 2) {
                        // 토글 가능한 체크박스
                        Button(intent: ToggleReminderIntent(reminderId: reminder.id)) {
                            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(reminder.isCompleted ? Color(hexCode: "A76545") : .gray)
                                .font(.system(size: 20))
                        }
                        .buttonStyle(.plain)
                        
                        Text(reminder.title)
                            .font(.pretendardSemiBold(size: 13))
                            .lineLimit(1)
                            .strikethrough(reminder.isCompleted)
                            .foregroundColor(reminder.isCompleted ? .gray : Color(hexCode: "40392B"))
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
