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
    
    var body: some View {
        HStack {
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(reminder.isCompleted ? Color(hexCode: "A76545") : .secondary)
                .font(.custom("", size: 22))
                .onTapGesture { onToggle() }
                .animation(.smooth, value: 1)
                .padding(.trailing, 2)
            
            if reminder.priority > 0 {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(priorityColor)
                    .opacity(reminder.isCompleted ? 0.5 : 1)
            }
            
            Text(reminder.title)
                .lineLimit(1)
                .font(.pretendardRegular(size: 17))
                .strikethrough(reminder.isCompleted)
                .opacity(reminder.isCompleted ? 0.5 : 1)
            Spacer()
            
            if let due = reminder.due {
                Text(DateFormatter.localizedString(from: due, dateStyle: .none, timeStyle: .short))
                    .lineLimit(1)
                    .font(.jakartaRegular(size: 15))
                    .foregroundStyle(Color(hexCode: "2E2514").opacity(0.8))
            }
        }
        .padding()
    }
}

//#Preview {
//    ReminderCard()
//}
