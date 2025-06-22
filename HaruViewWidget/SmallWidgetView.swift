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
            HStack(spacing: 3) {
                Image(systemName: "calendar")
                    .foregroundColor(Color(hexCode: "A76545"))
                    .font(.system(size: 10))
                Text("일정")
                    .font(.pretendardBold(size: 11))
                    .foregroundColor(Color(hexCode: "40392B"))
            }
            
            if entry.events.isEmpty {
                Text("일정이 없습니다")
                    .font(.pretendardRegular(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(entry.events.prefix(3).enumerated()), id: \.offset) { index, event in
                    HStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(hexCode: "A76545"))
                            .frame(width: 4)
                            .frame(maxHeight: 25)
                        
                        VStack(alignment: .leading) {
                            Text(event.title)
                                .font(.pretendardBold(size: 13))
                                .lineLimit(1)
                                .foregroundColor(Color(hexCode: "40392B"))
                            
                            if !event.isAllDay {
                                Text(event.startDate, style: .time)
                                    .font(.jakartaRegular(size: 11))
                                    .foregroundColor(.gray)
                            } else {
                                Text("하루 종일")
                                    .font(.jakartaRegular(size: 9))
                                    .foregroundColor(.gray)
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
            HStack(spacing: 3) {
                Image(systemName: "checklist")
                    .foregroundColor(Color(hexCode: "C2966B"))
                    .font(.system(size: 10))
                Text("할 일")
                    .font(.pretendardSemiBold(size: 10))
                    .foregroundColor(Color(hexCode: "40392B"))
            }
            
            if entry.reminders.isEmpty {
                Text("할 일이 없습니다")
                    .font(.pretendardRegular(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(entry.reminders.prefix(3).enumerated()), id: \.offset) { index, reminder in
                    HStack {
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
                    
                    if index < entry.reminders.prefix(3).count - 1 {
                        Divider()
                    }
                }
            }
            
            Spacer()
        }
    }
} 
