//
//  LargeWidgetView.swift
//  LargeWidgetView
//
//  Created by 김효석 on 6/20/25.
//


import SwiftUI

struct LargeWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // 일정 섹션
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color(hexCode: "A76545"))
                            .font(.system(size: 10))
                        Text("일정")
                            .font(.pretendardBold(size: 11))
                            .foregroundStyle(Color(hexCode: "40392B"))
                    }
                    
                    if entry.events.isEmpty {
                        Text("일정이 없습니다")
                            .font(.pretendardRegular(size: 11))
                            .foregroundStyle(.gray)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(Array(entry.events.prefix(9).enumerated()), id: \.offset) { index, event in
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
                                        .foregroundStyle(Color(hexCode: "40392B"))
                                        .strikethrough(isPast)
                                        .opacity(isPast ? 0.5 : 1)
                                    
                                    if !event.isAllDay {
                                        Text(event.startDate, style: .time)
                                            .font(.jakartaRegular(size: 11))
                                            .foregroundStyle(.gray)
                                            .opacity(isPast ? 0.5 : 1)
                                    } else {
                                        Text("하루 종일")
                                            .font(.jakartaRegular(size: 9))
                                            .foregroundStyle(.gray)
                                            .opacity(isPast ? 0.5 : 1)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 구분선
                Rectangle()
                    .fill(Color(hexCode: "6E5C49").opacity(0.2))
                    .frame(width: 1, height: .infinity)
                
                // 할 일 섹션
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "checklist")
                            .foregroundStyle(Color(hexCode: "C2966B"))
                            .font(.system(size: 10))
                        Text("할 일")
                            .font(.pretendardSemiBold(size: 10))
                            .foregroundStyle(Color(hexCode: "40392B"))
                    }
                    
                    if entry.reminders.isEmpty {
                        Text("할 일이 없습니다")
                            .font(.pretendardRegular(size: 11))
                            .foregroundStyle(.gray)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(Array(entry.reminders.prefix(9).enumerated()), id: \.element.id) { index, reminder in
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
                                            .foregroundStyle(reminder.isCompleted ? Color(hexCode: "A76545") : .gray)
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
                                    .foregroundStyle(reminder.isCompleted ? .gray : Color(hexCode: "40392B"))
                                    .invalidatableContent()
                            }
                            
                            if index < entry.reminders.prefix(9).count - 1 {
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

