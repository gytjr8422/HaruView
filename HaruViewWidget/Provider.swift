//
//  Provider.swift
//  Provider
//
//  Created by 김효석 on 6/20/25.
//

import WidgetKit
import EventKit
import Foundation

struct Provider: AppIntentTimelineProvider {
    private let eventStore = EKEventStore()
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), events: [], reminders: [])
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let (events, reminders) = await fetchCalendarData(for: context.family)
        return SimpleEntry(date: Date(), configuration: configuration, events: events, reminders: reminders)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let (events, reminders) = await fetchCalendarData(for: context.family)
        let currentDate = Date()
        
        let entry = SimpleEntry(date: currentDate, configuration: configuration, events: events, reminders: reminders)
        
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        
        return Timeline(entries: [entry], policy: .after(nextUpdateDate))
    }
    
    func fetchCalendarData(for family: WidgetFamily) async -> ([CalendarEvent], [ReminderItem]) {
        // EventKit 권한 확인
        let status = EKEventStore.authorizationStatus(for: .event)
        let reminderStatus = EKEventStore.authorizationStatus(for: .reminder)
        
        var events: [CalendarEvent] = []
        var reminders: [ReminderItem] = []
        
        // 캘린더 이벤트 가져오기
        if status == .fullAccess {
            events = await fetchTodayEvents(for: family)
        }
        
        // 미리알림 가져오기
        if reminderStatus == .fullAccess {
            reminders = await fetchTodayReminders(for: family)
        }
        
        return (events, reminders)
    }
    
    func fetchTodayEvents(for family: WidgetFamily) async -> [CalendarEvent] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)
        
        // 위젯 크기별 최대 개수 설정
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
                let compsStart = Calendar.current.dateComponents([.hour, .minute], from: event.startDate)
                let compsEnd = Calendar.current.dateComponents([.hour, .minute], from: event.endDate)
                let isAllDayDetected = Calendar.current.isDate(event.startDate, inSameDayAs: event.endDate) &&
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
    
    func fetchTodayReminders(for family: WidgetFamily) async -> [ReminderItem] {
            return await withCheckedContinuation { continuation in
                // 위젯 크기별 최대 개수 설정
                let maxCount: Int
                switch family {
                case .systemSmall:
                    maxCount = 4
                case .systemMedium:
                    maxCount = 4
                case .systemLarge:
                    maxCount = 9  // Large 위젯에서는 8개까지
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
                        
                        // 오늘과 겹치는지 필터링 (앱과 동일한 로직)
                        let todayStart = Calendar.current.startOfDay(for: Date())
                        let todayEnd = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!
                        
                        let filtered = bucket.filter { rem in
                            guard let due = rem.dueDateComponents?.date else { return true }
                            return due >= todayStart && due < todayEnd
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
                                        due = Calendar.current.startOfDay(for: originalDate)
                                    } else {
                                        due = nil
                                    }
                                }
                                
                                // URL에서 ReminderType 추출
                                let reminderType: WidgetReminderType
                                if let url = reminder.url?.absoluteString,
                                   url.contains("haruview-reminder-type://UNTIL") {
                                    reminderType = .untilDate
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
        let today = Calendar.current.startOfDay(for: Date())
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
        let calendar = Calendar.current
        let aDueDay = calendar.startOfDay(for: aDue)
        let bDueDay = calendar.startOfDay(for: bDue)
        
        let aDaysFromToday = calendar.dateComponents([.day], from: today, to: aDueDay).day ?? Int.max
        let bDaysFromToday = calendar.dateComponents([.day], from: today, to: bDueDay).day ?? Int.max
        
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
} 
