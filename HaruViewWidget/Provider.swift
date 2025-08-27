//
//  Provider.swift
//  Provider
//
//  Created by 김효석 on 6/20/25.
//

import WidgetKit
import EventKit
import Foundation

extension Calendar {
    /// 위젯용 사용자 설정에 따른 주 시작일이 적용된 Calendar 반환
    static func withUserWeekStartPreference() -> Calendar {
        var calendar = Calendar.current
        let weekStartsOnMonday = UserDefaults.standard.object(forKey: "weekStartsOnMonday") as? Bool ?? false
        calendar.firstWeekday = weekStartsOnMonday ? 2 : 1  // 1=일요일, 2=월요일
        return calendar
    }
}

struct Provider: AppIntentTimelineProvider {
    private let eventStore = EKEventStore()
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), events: [], reminders: [])
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let (events, reminders) = await fetchCalendarData(for: context.family, configuration: configuration)
        return SimpleEntry(date: Date(), configuration: configuration, events: events, reminders: reminders)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let (events, reminders) = await fetchCalendarData(for: context.family, configuration: configuration)
        let currentDate = Date()
        
        let entry = SimpleEntry(date: currentDate, configuration: configuration, events: events, reminders: reminders)
        
        let nextUpdateDate = Calendar.withUserWeekStartPreference().date(byAdding: Calendar.Component.minute, value: 5, to: currentDate)!
        
        return Timeline(entries: [entry], policy: .after(nextUpdateDate))
    }
    
    func fetchCalendarData(for family: WidgetFamily, configuration: ConfigurationAppIntent? = nil) async -> ([CalendarEvent], [ReminderItem]) {
        // EventKit 권한 확인
        let status = EKEventStore.authorizationStatus(for: .event)
        let reminderStatus = EKEventStore.authorizationStatus(for: .reminder)
        
        var events: [CalendarEvent] = []
        var reminders: [ReminderItem] = []
        
        // 위젯 타입에 따라 데이터 범위 결정
        let isCalendarWidget = configuration?.viewType == .calendar
        
        // 캘린더 이벤트 가져오기
        if status == .fullAccess {
            if isCalendarWidget {
                events = await fetchMonthEvents(for: family)
            } else {
                events = await fetchTodayEvents(for: family)
            }
        }
        
        // 미리알림 가져오기
        if reminderStatus == .fullAccess {
            if isCalendarWidget {
                reminders = await fetchMonthReminders(for: family)
            } else {
                reminders = await fetchTodayReminders(for: family)
            }
        }
        
        return (events, reminders)
    }
    
    // 달력 위젯용: 전체 월 이벤트
    func fetchMonthEvents(for family: WidgetFamily) async -> [CalendarEvent] {
        let calendar = Calendar.withUserWeekStartPreference()
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? calendar.date(byAdding: .day, value: 1, to: now)!
        
        let predicate = eventStore.predicateForEvents(withStart: startOfMonth, end: endOfMonth, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)
        
        let maxCount = 100 // 달력 위젯은 많은 데이터 필요
        
        let sortedEvents = ekEvents
            .filter { !isHolidayCalendar($0.calendar) }
            .map { event in
                let compsStart = calendar.dateComponents([Calendar.Component.hour, Calendar.Component.minute], from: event.startDate)
                let compsEnd = calendar.dateComponents([Calendar.Component.hour, Calendar.Component.minute], from: event.endDate)
                let isAllDayDetected = calendar.isDate(event.startDate, inSameDayAs: event.endDate) &&
                                     compsStart.hour == 0 && compsStart.minute == 0 &&
                                     compsEnd.hour == 23 && compsEnd.minute == 59
                
                return CalendarEvent(
                    title: event.title ?? "제목 없음",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    isAllDay: event.isAllDay || isAllDayDetected,
                    calendarColor: event.calendar.cgColor
                )
            }
            .sorted(by: eventSortRule)
            .prefix(maxCount)
        
        return Array(sortedEvents)
    }
    
    // 리스트 위젯용: 오늘 이벤트만
    func fetchTodayEvents(for family: WidgetFamily) async -> [CalendarEvent] {
        let startOfDay = Calendar.withUserWeekStartPreference().startOfDay(for: Date())
        let endOfDay = Calendar.withUserWeekStartPreference().date(byAdding: Calendar.Component.day, value: 1, to: startOfDay)!
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)
        
        let maxCount: Int
        switch family {
        case .systemSmall:
            maxCount = 4
        case .systemMedium:
            maxCount = 4
        case .systemLarge:
            maxCount = 9
        default:
            maxCount = 4
        }
        
        // 앱과 동일한 정렬 로직 적용
        let sortedEvents = ekEvents
            .filter { !isHolidayCalendar($0.calendar) }
            .map { event in
                // 하루 종일 이벤트 감지 로직 (앱과 동일)
                let compsStart = Calendar.withUserWeekStartPreference().dateComponents([Calendar.Component.hour, Calendar.Component.minute], from: event.startDate)
                let compsEnd = Calendar.withUserWeekStartPreference().dateComponents([Calendar.Component.hour, Calendar.Component.minute], from: event.endDate)
                let isAllDayDetected = Calendar.withUserWeekStartPreference().isDate(event.startDate, inSameDayAs: event.endDate) &&
                                     compsStart.hour == 0 && compsStart.minute == 0 &&
                                     compsEnd.hour == 23 && compsEnd.minute == 59
                
                return CalendarEvent(
                    title: event.title ?? "제목 없음",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    isAllDay: event.isAllDay || isAllDayDetected,  // EKEvent의 isAllDay 또는 시간 기반 감지
                    calendarColor: event.calendar.cgColor
                )
            }
            .sorted(by: eventSortRule)
            .prefix(maxCount)
        
        return Array(sortedEvents)
    }
    
    // 앱과 동일한 일정 정렬 규칙
    func eventSortRule(_ a: CalendarEvent, _ b: CalendarEvent) -> Bool {
        let now = Date()
        let aPast = a.endDate < now
        let bPast = b.endDate < now
        if aPast != bPast { return !aPast }          // 미종료 → 종료 순
        return a.startDate < b.startDate             // 둘 다 동일 상태면 시작 시간
    }
    
    // 달력 위젯용: 전체 월 할일
    func fetchMonthReminders(for family: WidgetFamily) async -> [ReminderItem] {
        return await withCheckedContinuation { continuation in
            let maxCount = 100 // 달력 위젯은 많은 데이터 필요
            
            let incPred = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
            let cmpPred = eventStore.predicateForCompletedReminders(withCompletionDateStarting: nil, ending: nil, calendars: nil)
            
            var bucket: [EKReminder] = []
            eventStore.fetchReminders(matching: incPred) { inc in
                bucket.append(contentsOf: inc ?? [])
                self.eventStore.fetchReminders(matching: cmpPred) { comp in
                    bucket.append(contentsOf: comp ?? [])
                    
                    // 달력 위젯용: 현재 월 전체 기간으로 확장
                    let calendar = Calendar.withUserWeekStartPreference()
                    let now = Date()
                    let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
                    let monthEnd = calendar.dateInterval(of: .month, for: now)?.end ?? calendar.date(byAdding: .day, value: 1, to: now)!
                    
                    let filtered = bucket.filter { rem in
                        guard let due = rem.dueDateComponents?.date else { 
                            return false // 달력 위젯에서는 마감일 없는 할일 제외
                        }
                        
                        // ReminderType 추출
                        let reminderType: WidgetReminderType
                        if let url = rem.url {
                            let urlString = url.absoluteString
                            if urlString.contains("haruview-reminder-type://UNTIL") || urlString.contains("haruview_type=UNTIL") {
                                reminderType = .untilDate
                            } else {
                                reminderType = .onDate
                            }
                        } else {
                            reminderType = .onDate
                        }
                        
                        switch reminderType {
                        case .onDate:
                            // 특정 날짜 할 일: 현재 월 내의 날짜만
                            return due >= monthStart && due < monthEnd
                        case .untilDate:
                            // 마감일까지 할 일: 마감일이 현재 월 내에 있거나 이후인 경우
                            return due >= monthStart
                        }
                    }
                    
                    let reminderItems = filtered
                        .map { reminder in
                            let reminderType: WidgetReminderType
                            if let url = reminder.url {
                                let urlString = url.absoluteString
                                if urlString.contains("haruview-reminder-type://UNTIL") || urlString.contains("haruview_type=UNTIL") {
                                    reminderType = .untilDate
                                } else {
                                    reminderType = .onDate
                                }
                            } else {
                                reminderType = .onDate
                            }
                            
                            return ReminderItem(
                                id: reminder.calendarItemIdentifier,
                                title: reminder.title ?? "제목 없음",
                                dueDate: reminder.dueDateComponents?.date,
                                priority: Int(reminder.priority),
                                isCompleted: reminder.isCompleted,
                                reminderType: reminderType
                            )
                        }
                        .prefix(maxCount)
                    
                    continuation.resume(returning: Array(reminderItems))
                }
            }
        }
    }
    
    // 리스트 위젯용: 오늘 할일만
    func fetchTodayReminders(for family: WidgetFamily) async -> [ReminderItem] {
        return await withCheckedContinuation { continuation in
            let maxCount: Int
            switch family {
            case .systemSmall:
                maxCount = 4
            case .systemMedium:
                maxCount = 4
            case .systemLarge:
                maxCount = 9
            default:
                maxCount = 4
            }
                
                let incPred = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
                let cmpPred = eventStore.predicateForCompletedReminders(withCompletionDateStarting: nil, ending: nil, calendars: nil)
                
                var bucket: [EKReminder] = []
                eventStore.fetchReminders(matching: incPred) { inc in
                    bucket.append(contentsOf: inc ?? [])
                    self.eventStore.fetchReminders(matching: cmpPred) { comp in
                        bucket.append(contentsOf: comp ?? [])
                        
                        // 달력 위젯용: 현재 월 전체 기간으로 확장
                        let calendar = Calendar.withUserWeekStartPreference()
                        let now = Date()
                        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
                        let monthEnd = calendar.dateInterval(of: .month, for: now)?.end ?? calendar.date(byAdding: .day, value: 1, to: now)!
                        
                        let filtered = bucket.filter { rem in
                            guard let due = rem.dueDateComponents?.date else { 
                                // 마감일이 없는 할 일은 항상 표시
                                return true 
                            }
                            
                            // ReminderType 추출
                            let reminderType: WidgetReminderType
                            if let url = rem.url {
                                let urlString = url.absoluteString
                                if urlString.contains("haruview-reminder-type://UNTIL") || urlString.contains("haruview_type=UNTIL") {
                                    reminderType = .untilDate
                                } else {
                                    reminderType = .onDate
                                }
                            } else {
                                reminderType = .onDate
                            }
                            
                            switch reminderType {
                            case .onDate:
                                // 특정 날짜 할 일: 현재 월 내의 날짜만
                                return due >= monthStart && due < monthEnd
                            case .untilDate:
                                // 마감일까지 할 일: 마감일이 현재 월 내에 있거나 이후인 경우
                                return due >= monthStart
                            }
                        }
                        
                        let reminderItems = filtered
                            .map { reminder in
                                // 앱과 동일한 매핑 로직 적용
                                let hasTime = reminder.dueDateComponents?.hour != nil || reminder.dueDateComponents?.minute != nil
                                let due: Date?
                                if hasTime {
                                    due = reminder.dueDateComponents?.date
                                } else {
                                    // 날짜만 있는 경우 해당 날짜의 시작 시간으로 설정 (앱과 동일)
                                    if let originalDate = reminder.dueDateComponents?.date {
                                        due = Calendar.withUserWeekStartPreference().startOfDay(for: originalDate)
                                    } else {
                                        due = nil
                                    }
                                }
                                
                                // URL에서 ReminderType 추출
                                let reminderType: WidgetReminderType
                                if let url = reminder.url {
                                    let urlString = url.absoluteString
                                    
                                    // 1. 기존 방식: haruview-reminder-type://UNTIL 체크
                                    if urlString.contains("haruview-reminder-type://UNTIL") {
                                        reminderType = .untilDate
                                    }
                                    // 2. 새 방식: 쿼리 파라미터 체크
                                    else if urlString.contains("haruview_type=UNTIL") {
                                        reminderType = .untilDate
                                    } else {
                                        reminderType = .onDate // 기본값
                                    }
                                } else {
                                    reminderType = .onDate // 기본값
                                }
                                
                                return ReminderItem(
                                    id: reminder.calendarItemIdentifier,
                                    title: reminder.title ?? "제목 없음",
                                    dueDate: due,
                                    priority: reminder.priority,
                                    isCompleted: reminder.isCompleted,
                                    reminderType: reminderType
                                )
                            }
                            .sorted(by: reminderSortRule)
                            .prefix(maxCount)
                        
                        continuation.resume(returning: Array(reminderItems))
                    }
                }
            }
        }
    
    // 앱과 동일한 미리알림 정렬 규칙
    func reminderSortRule(_ a: ReminderItem, _ b: ReminderItem) -> Bool {
        // 1. 완료 여부 기준 (미완료 먼저)
        if a.isCompleted != b.isCompleted {
            return !a.isCompleted
        }
        
        // 2. 우선순위 기준 (priority == 0 은 가장 낮은 순위로 처리)
        let aPriority = a.priority == 0 ? Int.max : a.priority
        let bPriority = b.priority == 0 ? Int.max : b.priority

        if aPriority != bPriority {
            return aPriority < bPriority // 숫자가 작을수록 앞에 (1=높음, 5=보통, 9=낮음)
        }
        
        // 3. ReminderType 우선순위 ("특정 날짜에"가 "마감일까지"보다 먼저)
        let aType = a.reminderType
        let bType = b.reminderType
        
        if aType != bType {
            if aType == .onDate && bType == .untilDate {
                return true  // "특정 날짜에"가 먼저
            } else if aType == .untilDate && bType == .onDate {
                return false // "마감일까지"가 나중
            }
        }
        
        // 4. 마감일 긴급도 기준
        let today = Calendar.withUserWeekStartPreference().startOfDay(for: Date())
        let aDue = a.dueDate ?? .distantFuture
        let bDue = b.dueDate ?? .distantFuture
        
        // 마감일이 없으면 가장 마지막
        if aDue == .distantFuture && bDue == .distantFuture {
            return a.title < b.title
        } else if aDue == .distantFuture {
            return false
        } else if bDue == .distantFuture {
            return true
        }
        
        // 오늘부터 마감일까지의 차이 계산 (음수면 지난 일정)
        // 날짜만 비교 - 시간 정보는 무시
        let calendar = Calendar.withUserWeekStartPreference()
        let aDueDay = calendar.startOfDay(for: aDue)
        let bDueDay = calendar.startOfDay(for: bDue)
        
        let aDaysFromToday = calendar.dateComponents([Calendar.Component.day], from: today, to: aDueDay).day ?? Int.max
        let bDaysFromToday = calendar.dateComponents([Calendar.Component.day], from: today, to: bDueDay).day ?? Int.max
        
        if aDaysFromToday != bDaysFromToday {
            return aDaysFromToday < bDaysFromToday // 오늘에 가까운 것부터
        }

        // 5. 제목 기준 (알파벳 순)
        return a.title < b.title
    }
    
    /// 공휴일 캘린더인지 확인하는 헬퍼 메서드
    private func isHolidayCalendar(_ calendar: EKCalendar) -> Bool {
        let titleLower = calendar.title.lowercased()
        return titleLower.contains("holiday") || 
               titleLower.contains("휴일") ||
               titleLower.contains("공휴일") ||
               calendar.calendarIdentifier.contains("holiday")
    }
    
    // 주간 위젯용: 이번 주 전체 이벤트와 할일
    func fetchWeeklyData() async -> ([CalendarEvent], [ReminderItem]) {
        let calendar = Calendar.withUserWeekStartPreference()
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.end ?? calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        // EventKit 권한 확인
        let eventStatus = EKEventStore.authorizationStatus(for: .event)
        let reminderStatus = EKEventStore.authorizationStatus(for: .reminder)
        
        var events: [CalendarEvent] = []
        var reminders: [ReminderItem] = []
        
        // 이벤트 가져오기
        if eventStatus == .fullAccess {
            let predicate = eventStore.predicateForEvents(withStart: startOfWeek, end: endOfWeek, calendars: nil)
            let ekEvents = eventStore.events(matching: predicate)
            
            events = ekEvents
                .filter { !isHolidayCalendar($0.calendar) }
                .map { event in
                    let compsStart = calendar.dateComponents([.hour, .minute], from: event.startDate)
                    let compsEnd = calendar.dateComponents([.hour, .minute], from: event.endDate)
                    let isAllDayDetected = calendar.isDate(event.startDate, inSameDayAs: event.endDate) &&
                                         compsStart.hour == 0 && compsStart.minute == 0 &&
                                         compsEnd.hour == 23 && compsEnd.minute == 59
                    
                    return CalendarEvent(
                        title: event.title ?? "제목 없음",
                        startDate: event.startDate,
                        endDate: event.endDate,
                        isAllDay: event.isAllDay || isAllDayDetected,
                        calendarColor: event.calendar.cgColor
                    )
                }
                .sorted(by: eventSortRule)
        }
        
        // 할일 가져오기
        if reminderStatus == .fullAccess {
            reminders = await fetchWeeklyReminders(startOfWeek: startOfWeek, endOfWeek: endOfWeek)
        }
        
        return (events, reminders)
    }
    
    private func fetchWeeklyReminders(startOfWeek: Date, endOfWeek: Date) async -> [ReminderItem] {
        return await withCheckedContinuation { continuation in
            let incPred = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
            let cmpPred = eventStore.predicateForCompletedReminders(withCompletionDateStarting: nil, ending: nil, calendars: nil)
            
            var bucket: [EKReminder] = []
            eventStore.fetchReminders(matching: incPred) { inc in
                bucket.append(contentsOf: inc ?? [])
                self.eventStore.fetchReminders(matching: cmpPred) { comp in
                    bucket.append(contentsOf: comp ?? [])
                    
                    let calendar = Calendar.withUserWeekStartPreference()
                    
                    let filtered = bucket.filter { rem in
                        guard let due = rem.dueDateComponents?.date else {
                            return false // 주간 위젯에서는 마감일 없는 할일 제외
                        }
                        
                        // ReminderType 추출
                        let reminderType: WidgetReminderType
                        if let url = rem.url {
                            let urlString = url.absoluteString
                            if urlString.contains("haruview-reminder-type://UNTIL") || urlString.contains("haruview_type=UNTIL") {
                                reminderType = .untilDate
                            } else {
                                reminderType = .onDate
                            }
                        } else {
                            reminderType = .onDate
                        }
                        
                        switch reminderType {
                        case .onDate:
                            // 특정 날짜 할 일: 이번 주 내의 날짜만
                            return due >= startOfWeek && due < endOfWeek
                        case .untilDate:
                            // 마감일까지 할 일: 마감일이 이번 주 내에 있거나 이후인 경우
                            return due >= startOfWeek
                        }
                    }
                    
                    let reminderItems = filtered
                        .map { reminder in
                            let reminderType: WidgetReminderType
                            if let url = reminder.url {
                                let urlString = url.absoluteString
                                if urlString.contains("haruview-reminder-type://UNTIL") || urlString.contains("haruview_type=UNTIL") {
                                    reminderType = .untilDate
                                } else {
                                    reminderType = .onDate
                                }
                            } else {
                                reminderType = .onDate
                            }
                            
                            return ReminderItem(
                                id: reminder.calendarItemIdentifier,
                                title: reminder.title ?? "제목 없음",
                                dueDate: reminder.dueDateComponents?.date,
                                priority: Int(reminder.priority),
                                isCompleted: reminder.isCompleted,
                                reminderType: reminderType
                            )
                        }
                        .sorted(by: reminderSortRule)
                    
                    continuation.resume(returning: Array(reminderItems))
                }
            }
        }
    }
}

// MARK: - Specialized Providers for Small Widgets

struct CalendarProvider: TimelineProvider {
    private let eventStore = EKEventStore()
    
    func placeholder(in context: Context) -> SimpleEntry {
        let config = ConfigurationAppIntent()
        config.viewType = .calendar
        return SimpleEntry(date: Date(), configuration: config, events: [], reminders: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task {
            let provider = Provider()
            let config = ConfigurationAppIntent()
            config.viewType = .calendar
            let (events, reminders) = await provider.fetchCalendarData(for: .systemSmall, configuration: config)
            let entry = SimpleEntry(date: Date(), configuration: config, events: events, reminders: reminders)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        Task {
            let provider = Provider()
            let config = ConfigurationAppIntent()
            config.viewType = .calendar
            let (events, reminders) = await provider.fetchCalendarData(for: .systemSmall, configuration: config)
            let currentDate = Date()
            let entry = SimpleEntry(date: currentDate, configuration: config, events: events, reminders: reminders)
            let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
            completion(timeline)
        }
    }
}

struct EventsProvider: TimelineProvider {
    private let eventStore = EKEventStore()
    
    func placeholder(in context: Context) -> SimpleEntry {
        let config = ConfigurationAppIntent()
        config.widgetType = .events
        config.viewType = .list
        return SimpleEntry(date: Date(), configuration: config, events: [], reminders: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task {
            let provider = Provider()
            let config = ConfigurationAppIntent()
            config.widgetType = .events
            config.viewType = .list
            let (events, reminders) = await provider.fetchCalendarData(for: .systemSmall, configuration: config)
            let entry = SimpleEntry(date: Date(), configuration: config, events: events, reminders: reminders)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        Task {
            let provider = Provider()
            let config = ConfigurationAppIntent()
            config.widgetType = .events
            config.viewType = .list
            let (events, reminders) = await provider.fetchCalendarData(for: .systemSmall, configuration: config)
            let currentDate = Date()
            let entry = SimpleEntry(date: currentDate, configuration: config, events: events, reminders: reminders)
            let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
            completion(timeline)
        }
    }
}

struct RemindersProvider: TimelineProvider {
    private let eventStore = EKEventStore()
    
    func placeholder(in context: Context) -> SimpleEntry {
        let config = ConfigurationAppIntent()
        config.widgetType = .reminders
        config.viewType = .list
        return SimpleEntry(date: Date(), configuration: config, events: [], reminders: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task {
            let provider = Provider()
            let config = ConfigurationAppIntent()
            config.widgetType = .reminders
            config.viewType = .list
            let (events, reminders) = await provider.fetchCalendarData(for: .systemSmall, configuration: config)
            let entry = SimpleEntry(date: Date(), configuration: config, events: events, reminders: reminders)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        Task {
            let provider = Provider()
            let config = ConfigurationAppIntent()
            config.widgetType = .reminders
            config.viewType = .list
            let (events, reminders) = await provider.fetchCalendarData(for: .systemSmall, configuration: config)
            let currentDate = Date()
            let entry = SimpleEntry(date: currentDate, configuration: config, events: events, reminders: reminders)
            let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
            completion(timeline)
        }
    }
}

struct CalendarListProvider: TimelineProvider {
    private let eventStore = EKEventStore()
    
    func placeholder(in context: Context) -> SimpleEntry {
        let config = ConfigurationAppIntent()
        config.viewType = .calendar
        return SimpleEntry(date: Date(), configuration: config, events: [], reminders: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task {
            let provider = Provider()
            let config = ConfigurationAppIntent()
            config.viewType = .calendar
            let (events, reminders) = await provider.fetchCalendarData(for: .systemMedium, configuration: config)
            let entry = SimpleEntry(date: Date(), configuration: config, events: events, reminders: reminders)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        Task {
            let provider = Provider()
            let config = ConfigurationAppIntent()
            config.viewType = .calendar
            let (events, reminders) = await provider.fetchCalendarData(for: .systemMedium, configuration: config)
            let currentDate = Date()
            let entry = SimpleEntry(date: currentDate, configuration: config, events: events, reminders: reminders)
            let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
            completion(timeline)
        }
    }
}

struct WeeklyScheduleProvider: TimelineProvider {
    private let eventStore = EKEventStore()
    
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), events: [], reminders: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task {
            let provider = Provider()
            let (events, reminders) = await provider.fetchWeeklyData()
            let entry = SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), events: events, reminders: reminders)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        Task {
            let provider = Provider()
            let (events, reminders) = await provider.fetchWeeklyData()
            let currentDate = Date()
            let entry = SimpleEntry(date: currentDate, configuration: ConfigurationAppIntent(), events: events, reminders: reminders)
            let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
            completion(timeline)
        }
    }
}
