//
//  MediumWidgetView.swift
//  MediumWidgetView
//
//  Created by 김효석 on 6/20/25.
//

import SwiftUI
import AppIntents

struct MediumWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // 일정 섹션
                VStack(alignment: .leading, spacing: 6) {
                    
                    if entry.events.isEmpty {
                        Text("일정이 없습니다")
                            .font(.pretendardRegular(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(Array(entry.events.prefix(4).enumerated()), id: \.offset) { index, event in
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
                }
                
                // 구분선
                Rectangle()
                    .fill(Color(hexCode: "6E5C49").opacity(0.2))
                    .frame(width: 1, height: .infinity)
                
                // 할 일 섹션
                VStack(alignment: .leading, spacing: 6) {
                    
                    if entry.reminders.isEmpty {
                        Text("할 일이 없습니다")
                            .font(.pretendardRegular(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(Array(entry.reminders.prefix(4).enumerated()), id: \.offset) { index, reminder in
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
                            
                            if index < entry.reminders.prefix(4).count - 1 {
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
