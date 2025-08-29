//
//  MediumRemindersWidget.swift
//  HaruViewWidget
//
//  Created by Claude on 8/29/25.
//

import SwiftUI
import UIKit

struct MediumRemindersWidget: View {
    let entry: Provider.Entry
    
    var body: some View {
        HStack(spacing: 8) {
            // 왼쪽: 할일 섹션
            RemindersSection(reminders: leftReminders, showTitle: false)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 구분선
            Rectangle()
                .fill(.haruCardBorder)
                .frame(width: 1, height: .infinity)
            
            // 오른쪽: 할일 섹션 (계속)
            RemindersSection(reminders: rightReminders, showTitle: false)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // 할일을 두 섹션으로 나누기
    private var leftReminders: [ReminderItem] {
        Array(todayReminders.prefix(4))
    }
    
    private var rightReminders: [ReminderItem] {
        Array(todayReminders.dropFirst(4).prefix(4))
    }
    
    private var todayReminders: [ReminderItem] {
        let calendar = Calendar.current
        let today = Date()
        
        // 오늘 할일 필터링
        let filtered = entry.reminders.filter { reminder in
            guard let dueDate = reminder.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: today)
        }
        
        // 우선순위 정렬
        return filtered.sorted { first, second in
            // 완료되지 않은 할일 우선
            if first.isCompleted != second.isCompleted {
                return !first.isCompleted
            }
            
            // 우선순위 순 (낮은 숫자가 높은 우선순위)
            let priority1 = first.priority == 0 ? Int.max : first.priority
            let priority2 = second.priority == 0 ? Int.max : second.priority
            
            if priority1 != priority2 {
                return priority1 < priority2
            }
            
            return first.title < second.title
        }
    }
}

struct RemindersSection: View {
    let reminders: [ReminderItem]
    let showTitle: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 섹션 제목 (선택적)
            if showTitle {
                HStack(spacing: 3) {
                    Image(systemName: "checklist")
                        .foregroundStyle(.haruAccent)
                        .font(.system(size: 10))
                    Text(localizedWidgetContent(key: "할 일", comment: "Reminders section title"))
                        .font(.pretendardSemiBold(size: 10))
                        .foregroundStyle(.haruWidgetText)
                }
            }
            
            // 할일 리스트
            if reminders.isEmpty {
                Text(localizedWidgetContent(key: "no_reminders_today", comment: "No reminders message"))
                    .font(.pretendardRegular(size: 11))
                    .foregroundStyle(.haruWidgetSecondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(reminders.enumerated()), id: \.element.id) { index, reminder in
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
                                    .foregroundStyle(reminder.isCompleted ? .haruCompleted : .primary)
                                    .font(.system(size: 18))
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            .buttonStyle(.plain)
                            .invalidatableContent()
                            .frame(width: 24, height: 24)
                        }
                        
                        Text(reminder.title)
                            .font(.pretendardSemiBold(size: 12))
                            .lineLimit(1)
                            .strikethrough(reminder.isCompleted)
                            .foregroundStyle(reminder.isCompleted ? .secondary : .primary)
                            .invalidatableContent()
                    }
                    
                    if index < reminders.count - 1 {
                        Divider()
                    }
                }
            }
            
            Spacer()
        }
    }
}

#Preview("Medium Reminders Widget") {
    let sampleEntry = SimpleEntry(
        date: Date(),
        configuration: ConfigurationAppIntent(),
        events: [],
        reminders: [
            ReminderItem(id: "1", title: "프로젝트 마감", dueDate: Date(), priority: 1, isCompleted: false, reminderType: .onDate),
            ReminderItem(id: "2", title: "보고서 작성", dueDate: Date(), priority: 2, isCompleted: true, reminderType: .untilDate),
            ReminderItem(id: "3", title: "회의 준비", dueDate: Date(), priority: 3, isCompleted: false, reminderType: .onDate),
            ReminderItem(id: "4", title: "이메일 확인", dueDate: Date(), priority: 1, isCompleted: false, reminderType: .untilDate),
            ReminderItem(id: "5", title: "운동하기", dueDate: Date(), priority: 2, isCompleted: false, reminderType: .onDate),
            ReminderItem(id: "6", title: "장보기", dueDate: Date(), priority: 1, isCompleted: true, reminderType: .onDate),
            ReminderItem(id: "7", title: "청소하기", dueDate: Date(), priority: 3, isCompleted: false, reminderType: .onDate),
            ReminderItem(id: "8", title: "독서하기", dueDate: Date(), priority: 2, isCompleted: false, reminderType: .onDate)
        ]
    )
    
    MediumRemindersWidget(entry: sampleEntry)
        .frame(height: 158)
        .background(.haruWidgetBackground)
}