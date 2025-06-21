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
        VStack(alignment: .leading, spacing: 8) {
            // 헤더
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Color(hexCode: "A76545"))
                    .font(.system(size: 14))
                Text("일정")
                    .font(.pretendardBold(size: 14))
                    .foregroundColor(Color(hexCode: "40392B"))
                Spacer()
                Text(entry.date, style: .time)
                    .font(.jakartaRegular(size: 11))
                    .foregroundColor(.secondary)
            }
            Divider()
                .background(Color(hexCode: "6E5C49").opacity(0.2))
            if entry.events.isEmpty {
                VStack {
                    Text(entry.configuration.favoriteEmoji)
                        .font(.system(size: 24))
                    Text("오늘 일정이 없습니다")
                        .font(.pretendardSemiBold(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(entry.events.prefix(3).enumerated()), id: \.offset) { index, event in
                        HStack {
                            Circle()
                                .fill(Color(hexCode: "A76545"))
                                .frame(width: 4, height: 4)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(event.title)
                                    .font(.pretendardSemiBold(size: 11))
                                    .lineLimit(1)
                                    .foregroundColor(Color(hexCode: "40392B"))
                                if !event.isAllDay {
                                    Text(event.startDate, style: .time)
                                        .font(.jakartaRegular(size: 9))
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("하루 종일")
                                        .font(.jakartaRegular(size: 9))
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(12)
    }
}

struct SmallRemindersWidget: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 헤더
            HStack {
                Image(systemName: "checklist")
                    .foregroundColor(Color(hexCode: "C2966B"))
                    .font(.system(size: 14))
                Text("할 일")
                    .font(.pretendardBold(size: 14))
                    .foregroundColor(Color(hexCode: "40392B"))
                Spacer()
                Text(entry.date, style: .time)
                    .font(.jakartaRegular(size: 11))
                    .foregroundColor(.secondary)
            }
            Divider()
                .background(Color(hexCode: "6E5C49").opacity(0.2))
            if entry.reminders.isEmpty {
                VStack {
                    Text(entry.configuration.favoriteEmoji)
                        .font(.system(size: 24))
                    Text("오늘 할 일이 없습니다")
                        .font(.pretendardSemiBold(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(entry.reminders.prefix(3).enumerated()), id: \.offset) { index, reminder in
                        HStack {
                            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(reminder.isCompleted ? Color(hexCode: "A76545") : .secondary)
                                .font(.system(size: 12))
                            if reminder.priority > 0 {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(priorityColor(reminder.priority))
                                    .font(.system(size: 8))
                                    .opacity(reminder.isCompleted ? 0.5 : 1)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text(reminder.title)
                                    .font(.pretendardRegular(size: 11))
                                    .lineLimit(1)
                                    .strikethrough(reminder.isCompleted)
                                    .foregroundColor(reminder.isCompleted ? .secondary : Color(hexCode: "40392B"))
                                if let dueDate = reminder.dueDate {
                                    Text(dueDate, style: .time)
                                        .font(.jakartaRegular(size: 9))
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(12)
    }
    
    private func priorityColor(_ priority: Int) -> Color {
        switch priority {
        case 1: return Color(hexCode: "FF5722")
        case 5: return Color(hexCode: "FFC107")
        case 9: return Color(hexCode: "4CAF50")
        default: return .secondary
        }
    }
} 
