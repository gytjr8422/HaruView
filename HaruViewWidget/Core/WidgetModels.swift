//
//  WidgetModels.swift
//  WidgetModels
//
//  Created by 김효석 on 6/20/25.
//


import Foundation
import WidgetKit
import CoreGraphics

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
    let calendarColor: CGColor
}

// ReminderType enum for widget
enum WidgetReminderType {
    case onDate
    case untilDate
}

struct ReminderItem: Identifiable {
    let id: String
    let title: String
    let dueDate: Date?
    let priority: Int
    let isCompleted: Bool
    let reminderType: WidgetReminderType
}
