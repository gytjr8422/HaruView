//
//  CalendarCacheManager.swift
//  HaruView
//
//  Created by Claude on 8/3/25.
//

import Foundation
import UIKit

final class CalendarCacheManager: ObservableObject {
    static let shared = CalendarCacheManager()
    
    private var monthCache: [String: CalendarMonth] = [:]
    private var displayItemsCache: [String: [CalendarDisplayItem]] = [:]
    private let cacheQueue = DispatchQueue(label: "calendar.cache", attributes: .concurrent)
    private let maxCacheSize = 12 // 최대 12개월 캐시
    
    private init() {
        setupMemoryWarningObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Month Cache
    
    func getCachedMonth(for key: String) -> CalendarMonth? {
        return cacheQueue.sync {
            monthCache[key]
        }
    }
    
    func setCachedMonth(_ month: CalendarMonth, for key: String) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.monthCache[key] = month
            self?.cleanupCacheIfNeeded()
        }
    }
    
    func removeCachedMonth(for key: String) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.monthCache.removeValue(forKey: key)
        }
    }
    
    // MARK: - Display Items Cache
    
    func getCachedDisplayItems(for key: String) -> [CalendarDisplayItem]? {
        return cacheQueue.sync {
            displayItemsCache[key]
        }
    }
    
    func setCachedDisplayItems(_ items: [CalendarDisplayItem], for key: String) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.displayItemsCache[key] = items
            self?.cleanupDisplayItemsCacheIfNeeded()
        }
    }
    
    /// 날짜별 displayItems 캐시 키 생성
    func displayItemsCacheKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "display_\(formatter.string(from: date))"
    }
    
    /// displayItems 계산 및 캐싱
    func getOrComputeDisplayItems(for calendarDay: CalendarDay) -> [CalendarDisplayItem] {
        let cacheKey = displayItemsCacheKey(for: calendarDay.date)
        
        // 캐시된 결과가 있으면 반환
        if let cachedItems = getCachedDisplayItems(for: cacheKey) {
            return cachedItems
        }
        
        // 계산 수행
        let computedItems = computeDisplayItems(for: calendarDay)
        
        // 결과 캐싱
        setCachedDisplayItems(computedItems, for: cacheKey)
        
        return computedItems
    }
    
    /// 실제 displayItems 계산 로직
    private func computeDisplayItems(for calendarDay: CalendarDay) -> [CalendarDisplayItem] {
        var items: [CalendarDisplayItem] = []
        
        // 이벤트를 시간순으로 정렬
        let sortedEvents = calendarDay.events.sorted { event1, event2 in
            // 하루 종일 일정은 뒤로
            if event1.isAllDay != event2.isAllDay {
                return !event1.isAllDay
            }
            
            // 시간이 있는 경우 시간순
            if let time1 = event1.startTime, let time2 = event2.startTime {
                return time1 < time2
            }
            
            // 제목순
            return event1.title < event2.title
        }
        
        // 할일을 우선순위순으로 정렬
        let sortedReminders = calendarDay.reminders.sorted { reminder1, reminder2 in
            // 완료된 할일은 뒤로
            if reminder1.isCompleted != reminder2.isCompleted {
                return !reminder1.isCompleted
            }
            
            // 우선순위 (낮은 숫자가 높은 우선순위)
            let priority1 = reminder1.priority == 0 ? Int.max : reminder1.priority
            let priority2 = reminder2.priority == 0 ? Int.max : reminder2.priority
            
            if priority1 != priority2 {
                return priority1 < priority2
            }
            
            // 시간이 있는 할일 우선
            let hasTime1 = reminder1.dueTime != nil
            let hasTime2 = reminder2.dueTime != nil
            
            if hasTime1 != hasTime2 {
                return hasTime1
            }
            
            // 시간순
            if let time1 = reminder1.dueTime, let time2 = reminder2.dueTime {
                return time1 < time2
            }
            
            return reminder1.title < reminder2.title
        }
        
        // 공휴일 먼저 (가장 우선) - 설정에 따라 표시 여부 결정
        let showHolidays = UserDefaults.standard.object(forKey: "showHolidays") as? Bool ?? true
        if showHolidays {
            for holiday in calendarDay.holidays {
                items.append(.holiday(holiday))
            }
        }
        
        // 이벤트 처리 (연속 이벤트 로직 적용)
        for event in sortedEvents {
            let continuousInfo = createContinuousEventInfo(for: event, on: calendarDay.date)
            if let info = continuousInfo {
                items.append(.continuousEvent(info))
            } else {
                items.append(.event(event))
            }
        }
        
        // 할일 처리
        for reminder in sortedReminders {
            items.append(.reminder(reminder))
        }
        
        return items
    }
    
    /// 연속 이벤트 정보 생성
    private func createContinuousEventInfo(for event: CalendarEvent, on targetDate: Date) -> ContinuousEventInfo? {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: targetDate)
        let eventStartDay = calendar.startOfDay(for: event.originalStart)
        let eventEndDay = calendar.startOfDay(for: event.originalEnd)
        
        // 해당 날짜가 이벤트 기간에 포함되지 않으면 nil 반환
        guard targetDay >= eventStartDay && targetDay <= eventEndDay else {
            return nil
        }
        
        // 단일 날짜 이벤트는 연속 이벤트 처리하지 않음
        guard eventStartDay != eventEndDay else {
            return nil
        }
        
        let weekday = calendar.component(.weekday, from: targetDate)
        let weekPosition = weekday - 1 // 일요일=0, 월요일=1, ..., 토요일=6으로 변환
        
        let isStart = targetDay == eventStartDay
        let isEnd = targetDay == eventEndDay
        
        // 제목 표시 여부 결정: 시작일이거나 주의 시작일(일요일)
        let showTitle = isStart || weekPosition == 0
        
        return ContinuousEventInfo(
            event: event,
            showTitle: showTitle,
            isStart: isStart,
            isEnd: isEnd,
            weekPosition: weekPosition
        )
    }
    
    func removeCachedDisplayItems(for key: String) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.displayItemsCache.removeValue(forKey: key)
        }
    }
    
    // MARK: - Cache Management
    
    func clearAllCache() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.monthCache.removeAll()
            self?.displayItemsCache.removeAll()
        }
    }
    
    func clearDisplayItemsCache() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.displayItemsCache.removeAll()
        }
    }
    
    func clearExpiredCache(currentDate: Date = Date()) {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .month, value: -6, to: currentDate) ?? currentDate
        
        cacheQueue.async(flags: .barrier) { [weak self] in
            let expiredKeys = self?.monthCache.keys.filter { key in
                guard let dateFromKey = self?.dateFromCacheKey(key) else { return true }
                return dateFromKey < cutoffDate
            } ?? []
            
            for key in expiredKeys {
                self?.monthCache.removeValue(forKey: key)
                self?.displayItemsCache.removeValue(forKey: key)
            }
        }
    }
    
    func prefetchMonth(year: Int, month: Int) async {
        let key = cacheKey(for: year, month: month)
        
        // 이미 캐시된 경우 스킵
        if getCachedMonth(for: key) != nil {
            return
        }
        
        // 백그라운드에서 프리페치 실행
        Task.detached(priority: .utility) {
            // 여기서 실제 데이터 로딩 로직 실행
            // Repository에서 데이터를 가져와서 캐시에 저장
        }
    }
    
    // MARK: - Cache Statistics
    
    var cacheStatistics: (monthCount: Int, displayItemsCount: Int, memoryEstimate: String) {
        return cacheQueue.sync {
            let monthCount = monthCache.count
            let displayItemsCount = displayItemsCache.count
            
            // 대략적인 메모리 사용량 계산
            let estimatedMemory = (monthCount * 50 + displayItemsCount * 100) // KB 단위
            let memoryString = estimatedMemory > 1024 ? "\(estimatedMemory/1024)MB" : "\(estimatedMemory)KB"
            
            return (monthCount, displayItemsCount, memoryString)
        }
    }
    
    // MARK: - Private Methods
    
    private func cacheKey(for year: Int, month: Int) -> String {
        return "calendar_\(year)_\(String(format: "%02d", month))"
    }
    
    private func dateFromCacheKey(_ key: String) -> Date? {
        let components = key.components(separatedBy: "_")
        guard components.count == 3,
              let year = Int(components[1]),
              let month = Int(components[2]) else {
            return nil
        }
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        
        return Calendar.current.date(from: dateComponents)
    }
    
    private func cleanupCacheIfNeeded() {
        if monthCache.count > maxCacheSize {
            // 가장 오래된 캐시 항목들 제거
            let sortedKeys = monthCache.keys.sorted { key1, key2 in
                guard let date1 = dateFromCacheKey(key1),
                      let date2 = dateFromCacheKey(key2) else {
                    return false
                }
                return date1 < date2
            }
            
            let keysToRemove = Array(sortedKeys.prefix(monthCache.count - maxCacheSize))
            for key in keysToRemove {
                monthCache.removeValue(forKey: key)
            }
        }
    }
    
    private func cleanupDisplayItemsCacheIfNeeded() {
        if displayItemsCache.count > maxCacheSize {
            let sortedKeys = displayItemsCache.keys.sorted { key1, key2 in
                guard let date1 = dateFromCacheKey(key1),
                      let date2 = dateFromCacheKey(key2) else {
                    return false
                }
                return date1 < date2
            }
            
            let keysToRemove = Array(sortedKeys.prefix(displayItemsCache.count - maxCacheSize))
            for key in keysToRemove {
                displayItemsCache.removeValue(forKey: key)
            }
        }
    }
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.clearExpiredCache()
            }
        }
    }
}