import Foundation
import WidgetKit

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let events: [CalendarEvent]
    let reminders: [ReminderItem]
}

struct CalendarEvent {
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
}

struct ReminderItem: Identifiable {
    let id: String
    let title: String
    let dueDate: Date?
    let priority: Int
    let isCompleted: Bool
}
