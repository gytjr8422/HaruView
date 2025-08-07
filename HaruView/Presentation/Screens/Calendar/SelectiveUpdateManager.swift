//
//  SelectiveUpdateManager.swift
//  HaruView
//
//  Created by Claude on 8/3/25.
//

import SwiftUI
import Combine

@MainActor
final class SelectiveUpdateManager: ObservableObject {
    
    // MARK: - Types
    enum UpdateType {
        case eventAdded(Event, Date)
        case eventUpdated(Event, Date)
        case eventDeleted(String, Date)
        case reminderAdded(Reminder, Date?)
        case reminderUpdated(Reminder, Date?)
        case reminderDeleted(String, Date?)
        case dateRange([Date]) // 여러 날짜 업데이트
    }
    
    struct PendingUpdate {
        let type: UpdateType
        let timestamp: Date
        let id = UUID()
    }
    
    // MARK: - Published Properties
    @Published private(set) var isUpdating = false
    @Published private(set) var pendingUpdates: [PendingUpdate] = []
    
    // MARK: - Private Properties
    private let cacheManager = CalendarCacheManager.shared
    private var updateTimer: Timer?
    private let updateDelay: TimeInterval = 0.05 // 50ms 지연으로 업데이트 배치 (더 빠르게)
    private var currentUpdateTask: Task<Void, Never>?
    
    // MARK: - Public Methods
    
    /// 이벤트 추가 업데이트
    func scheduleEventAddUpdate(event: Event, affectedDate: Date) {
        let update = PendingUpdate(
            type: .eventAdded(event, affectedDate),
            timestamp: Date()
        )
        addPendingUpdate(update)
    }
    
    /// 이벤트 수정 업데이트
    func scheduleEventEditUpdate(event: Event, affectedDate: Date) {
        let update = PendingUpdate(
            type: .eventUpdated(event, affectedDate),
            timestamp: Date()
        )
        addPendingUpdate(update)
    }
    
    /// 이벤트 삭제 업데이트
    func scheduleEventDeleteUpdate(eventId: String, affectedDate: Date) {
        let update = PendingUpdate(
            type: .eventDeleted(eventId, affectedDate),
            timestamp: Date()
        )
        addPendingUpdate(update)
    }
    
    /// 할일 추가 업데이트
    func scheduleReminderAddUpdate(reminder: Reminder, affectedDate: Date?) {
        let update = PendingUpdate(
            type: .reminderAdded(reminder, affectedDate),
            timestamp: Date()
        )
        addPendingUpdate(update)
    }
    
    /// 할일 수정 업데이트
    func scheduleReminderEditUpdate(reminder: Reminder, affectedDate: Date?) {
        let update = PendingUpdate(
            type: .reminderUpdated(reminder, affectedDate),
            timestamp: Date()
        )
        addPendingUpdate(update)
    }
    
    /// 할일 삭제 업데이트
    func scheduleReminderDeleteUpdate(reminderId: String, affectedDate: Date?) {
        let update = PendingUpdate(
            type: .reminderDeleted(reminderId, affectedDate),
            timestamp: Date()
        )
        addPendingUpdate(update)
    }
    
    /// 특정 날짜 범위 업데이트
    func scheduleDateRangeUpdate(dates: [Date]) {
        let update = PendingUpdate(
            type: .dateRange(dates),
            timestamp: Date()
        )
        addPendingUpdate(update)
    }
    
    /// 모든 업데이트 취소
    func cancelAllUpdates() {
        pendingUpdates.removeAll()
        updateTimer?.invalidate()
        updateTimer = nil
        isUpdating = false
    }
    
    /// 즉시 업데이트 적용
    func applyUpdatesImmediately() {
        updateTimer?.invalidate()
        processUpdates()
    }
    
    // MARK: - Private Methods
    
    private func addPendingUpdate(_ update: PendingUpdate) {
        pendingUpdates.append(update)
        scheduleUpdate()
    }
    
    private func scheduleUpdate() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.processUpdates()
            }
        }
    }
    
    private func processUpdates() {
        guard !pendingUpdates.isEmpty && !isUpdating else { return }
        
        // 이전 업데이트 태스크가 있으면 취소
        currentUpdateTask?.cancel()
        
        isUpdating = true
        let updates = pendingUpdates
        pendingUpdates.removeAll()
        
        currentUpdateTask = Task {
            await applyUpdates(updates)
            await MainActor.run {
                self.isUpdating = false
                self.currentUpdateTask = nil
            }
        }
    }
    
    private func applyUpdates(_ updates: [PendingUpdate]) async {
        // 영향받는 날짜들을 수집
        var affectedDates: Set<Date> = []
        
        for update in updates {
            switch update.type {
            case .eventAdded(_, let date), .eventUpdated(_, let date), .eventDeleted(_, let date):
                affectedDates.insert(Calendar.current.startOfDay(for: date))
            case .reminderAdded(_, let date), .reminderUpdated(_, let date), .reminderDeleted(_, let date):
                if let date = date {
                    affectedDates.insert(Calendar.current.startOfDay(for: date))
                }
            case .dateRange(let dates):
                for date in dates {
                    affectedDates.insert(Calendar.current.startOfDay(for: date))
                }
            }
        }
        
        // 영향받는 월들을 계산
        let affectedMonths = Set(affectedDates.map { date in
            let components = Calendar.current.dateComponents([.year, .month], from: date)
            return "\(components.year!)_\(components.month!)"
        })
        
        // 해당 월들의 캐시만 선택적으로 무효화
        for monthKey in affectedMonths {
            let components = monthKey.split(separator: "_")
            if components.count == 2,
               let year = Int(components[0]),
               let month = Int(components[1]) {
                
                let cacheKey = "calendar_\(year)_\(String(format: "%02d", month))"
                cacheManager.removeCachedMonth(for: cacheKey)
                
                // 해당 날짜들의 displayItems 캐시도 무효화
                for date in affectedDates {
                    let dateComponents = Calendar.current.dateComponents([.year, .month], from: date)
                    if dateComponents.year == year && dateComponents.month == month {
                        let displayKey = cacheManager.displayItemsCacheKey(for: date)
                        cacheManager.removeCachedDisplayItems(for: displayKey)
                    }
                }
            }
        }
        
        // 변경된 월들만 백그라운드에서 새로 로드
        await reloadAffectedMonths(Array(affectedMonths))
    }
    
    private func reloadAffectedMonths(_ monthKeys: [String]) async {
        let smartLoader = SmartDataLoader.shared
        var updatedMonths: [CalendarMonth] = []
        
        // 모든 월을 병렬로 로드
        await withTaskGroup(of: CalendarMonth?.self) { group in
            for monthKey in monthKeys {
                group.addTask {
                    let components = monthKey.split(separator: "_")
                    guard components.count == 2,
                          let year = Int(components[0]),
                          let month = Int(components[1]) else {
                        return nil
                    }
                    
                    let result = await smartLoader.loadCurrentMonth(year: year, month: month)
                    if case .success(let calendarMonth) = result {
                        return calendarMonth
                    }
                    return nil
                }
            }
            
            for await calendarMonth in group {
                if let month = calendarMonth {
                    updatedMonths.append(month)
                    
                    // 캐시에 새 데이터 저장 (원자적으로)
                    let cacheKey = "calendar_\(month.year)_\(String(format: "%02d", month.month))"
                    cacheManager.setCachedMonth(month, for: cacheKey)
                }
            }
        }
        
        // UI 업데이트 알림 발송 (모든 데이터가 로드된 후)
        if !updatedMonths.isEmpty {
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .calendarDataUpdated,
                    object: nil,
                    userInfo: ["updatedMonths": updatedMonths]
                )
            }
        }
    }
}

// MARK: - Helper Extensions
extension SelectiveUpdateManager {
    
    /// 이벤트에서 영향받는 날짜들 계산
    func getAffectedDates(for event: Event) -> [Date] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: event.start)
        let endDate = calendar.startOfDay(for: event.end)
        
        var dates: [Date] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return dates
    }
    
    /// 할일에서 영향받는 날짜 계산
    func getAffectedDate(for reminder: Reminder) -> Date? {
        guard let due = reminder.due else { return Date() } // 오늘로 기본 설정
        return Calendar.current.startOfDay(for: due)
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let calendarDataUpdated = Notification.Name("calendarDataUpdated")
}