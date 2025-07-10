//
//  ReminderDetailRow.swift
//  HaruView
//
//  Created by 김효석 on 7/11/25.
//

import SwiftUI

struct ReminderDetailRow: View {
    let reminder: CalendarReminder
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundStyle(reminder.isCompleted ? Color(hexCode: "A76545") : .secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundStyle(Color(hexCode: "40392B"))
                    .strikethrough(reminder.isCompleted)
                
                if let timeText = reminder.timeDisplayText {
                    Text(timeText)
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.secondary)
                }
                
                if reminder.priority > 0 {
                    HStack(spacing: 4) {
                        if let priorityColor = reminder.priorityColor {
                            Circle()
                                .fill(Color(priorityColor))
                                .frame(width: 8, height: 8)
                        }
                        Text(priorityText(reminder.priority))
                            .font(.pretendardRegular(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hexCode: "C2966B").opacity(0.1))
        )
        .padding(.horizontal, 20)
    }
    
    private func priorityText(_ priority: Int) -> String {
        switch priority {
        case 1: return "높은 우선순위"
        case 5: return "보통 우선순위"
        case 9: return "낮은 우선순위"
        default: return ""
        }
    }
}
