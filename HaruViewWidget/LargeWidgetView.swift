import SwiftUI

struct LargeWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 일정 섹션
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Color(hexCode: "A76545"))
                        .font(.system(size: 15))
                    Text("오늘의 일정")
                        .font(.pretendardSemiBold(size: 15))
                        .foregroundColor(Color(hexCode: "40392B"))
                }
                if entry.events.isEmpty {
                    HStack {
                        Spacer()
                        Text("오늘 일정이 없습니다")
                            .font(.pretendardRegular(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                        Spacer()
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hexCode: "FFFCF5"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hexCode: "6E5C49").opacity(0.2), lineWidth: 1)
                            )
                    )
                } else {
                    ForEach(Array(entry.events.enumerated()), id: \.offset) { index, event in
                        HStack {
                            Circle()
                                .fill(Color(hexCode: "A76545"))
                                .frame(width: 6, height: 6)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.pretendardSemiBold(size: 13))
                                    .lineLimit(1)
                                    .foregroundColor(Color(hexCode: "40392B"))
                                if !event.isAllDay {
                                    Text(event.startDate, style: .time)
                                        .font(.jakartaRegular(size: 11))
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("하루 종일")
                                        .font(.jakartaRegular(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hexCode: "FFFCF5"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(hexCode: "6E5C49").opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
            }
            // 할 일 섹션
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checklist")
                        .foregroundColor(Color(hexCode: "C2966B"))
                        .font(.system(size: 15))
                    Text("할 일")
                        .font(.pretendardSemiBold(size: 15))
                        .foregroundColor(Color(hexCode: "40392B"))
                }
                if entry.reminders.isEmpty {
                    HStack {
                        Spacer()
                        Text("오늘 할 일이 없습니다")
                            .font(.pretendardRegular(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 6)
                        Spacer()
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hexCode: "C2966B").opacity(0.09))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hexCode: "C2966B").opacity(0.5), lineWidth: 1)
                            )
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(entry.reminders.enumerated()), id: \.offset) { index, reminder in
                            HStack {
                                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(reminder.isCompleted ? Color(hexCode: "A76545") : .secondary)
                                    .font(.system(size: 16))
                                if reminder.priority > 0 {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(priorityColor(reminder.priority))
                                        .font(.system(size: 10))
                                        .opacity(reminder.isCompleted ? 0.5 : 1)
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(reminder.title)
                                        .font(.pretendardRegular(size: 13))
                                        .lineLimit(1)
                                        .strikethrough(reminder.isCompleted)
                                        .foregroundColor(reminder.isCompleted ? .secondary : Color(hexCode: "40392B"))
                                    if let dueDate = reminder.dueDate {
                                        Text(dueDate, style: .time)
                                            .font(.jakartaRegular(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            if index < entry.reminders.count - 1 {
                                Divider()
                                    .padding(.horizontal, 12)
                                    .background(Color.gray.opacity(0.1))
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hexCode: "C2966B").opacity(0.09))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hexCode: "C2966B").opacity(0.5), lineWidth: 1)
                            )
                    )
                }
            }
            Spacer()
        }
        .padding(16)
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
