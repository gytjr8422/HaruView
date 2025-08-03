//
//  SmartDataLoader.swift
//  HaruView
//
//  Created by Claude on 8/3/25.
//

import Foundation

@MainActor
final class SmartDataLoader: ObservableObject {
    static let shared = SmartDataLoader()
    
    // MARK: - Properties
    private let cacheManager = CalendarCacheManager.shared
    private var activeTasks: [String: Task<Void, Never>] = [:]
    private var loadingQueue: [LoadRequest] = []
    private var isProcessingQueue = false
    
    // MARK: - Types
    private struct LoadRequest {
        let year: Int
        let month: Int
        let priority: LoadPriority
        let completion: ((Result<CalendarMonth, TodayBoardError>) -> Void)?
        let id = UUID()
    }
    
    enum LoadPriority: Int, Comparable {
        case critical = 0    // 현재 보고 있는 월
        case high = 1        // 인접한 월 (이전/다음)
        case medium = 2      // 2개월 전후
        case low = 3         // 배경 프리페치
        
        static func < (lhs: LoadPriority, rhs: LoadPriority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 현재 월 데이터 로드 (최우선)
    func loadCurrentMonth(year: Int, month: Int) async -> Result<CalendarMonth, TodayBoardError> {
        return await loadMonth(year: year, month: month, priority: .critical)
    }
    
    /// 인접 월 데이터 로드 (높은 우선순위)
    func loadAdjacentMonth(year: Int, month: Int) async -> Result<CalendarMonth, TodayBoardError> {
        return await loadMonth(year: year, month: month, priority: .high)
    }
    
    /// 백그라운드 프리페치
    func prefetchMonth(year: Int, month: Int, priority: LoadPriority = .low) {
        Task.detached(priority: .utility) {
            await self.loadMonth(year: year, month: month, priority: priority)
        }
    }
    
    /// 윈도우 범위 로드 (현재 월 ± 범위)
    func loadWindow(centerYear: Int, centerMonth: Int, range: Int = 1) async -> [CalendarMonth] {
        var results: [CalendarMonth] = []
        
        // 현재 월 먼저 로드
        if let currentMonth = await loadCurrentMonth(year: centerYear, month: centerMonth).value {
            results.append(currentMonth)
        }
        
        // 인접 월들을 병렬로 로드
        await withTaskGroup(of: CalendarMonth?.self) { group in
            for offset in -range...range {
                if offset == 0 { continue } // 현재 월은 이미 로드됨
                
                let (year, month) = calculateYearMonth(centerYear, centerMonth, offset: offset)
                group.addTask {
                    return await self.loadAdjacentMonth(year: year, month: month).value
                }
            }
            
            for await month in group {
                if let month = month {
                    results.append(month)
                }
            }
        }
        
        return results.sorted { $0.year * 12 + $0.month < $1.year * 12 + $1.month }
    }
    
    /// 특정 월 데이터가 캐시되어 있는지 확인
    func isMonthCached(year: Int, month: Int) -> Bool {
        let key = cacheKey(for: year, month: month)
        return cacheManager.getCachedMonth(for: key) != nil
    }
    
    /// 모든 로딩 작업 취소
    func cancelAllLoading() {
        for (_, task) in activeTasks {
            task.cancel()
        }
        activeTasks.removeAll()
        loadingQueue.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func loadMonth(year: Int, month: Int, priority: LoadPriority) async -> Result<CalendarMonth, TodayBoardError> {
        let key = cacheKey(for: year, month: month)
        
        // 캐시된 데이터가 있으면 즉시 반환
        if let cachedMonth = cacheManager.getCachedMonth(for: key) {
            return .success(cachedMonth)
        }
        
        // 이미 로딩 중인 작업이 있으면 대기
        if let existingTask = activeTasks[key] {
            await existingTask.value
            if let cachedMonth = cacheManager.getCachedMonth(for: key) {
                return .success(cachedMonth)
            }
        }
        
        // 새로운 로딩 작업 시작
        return await withCheckedContinuation { continuation in
            let request = LoadRequest(
                year: year,
                month: month,
                priority: priority
            ) { result in
                continuation.resume(returning: result)
            }
            
            addToQueue(request)
        }
    }
    
    private func addToQueue(_ request: LoadRequest) {
        // 우선순위에 따라 큐에 삽입
        if let insertIndex = loadingQueue.firstIndex(where: { $0.priority > request.priority }) {
            loadingQueue.insert(request, at: insertIndex)
        } else {
            loadingQueue.append(request)
        }
        
        processQueueIfNeeded()
    }
    
    private func processQueueIfNeeded() {
        guard !isProcessingQueue, !loadingQueue.isEmpty else { return }
        
        isProcessingQueue = true
        
        Task {
            while !loadingQueue.isEmpty {
                let request = loadingQueue.removeFirst()
                await processRequest(request)
            }
            isProcessingQueue = false
        }
    }
    
    private func processRequest(_ request: LoadRequest) async {
        let key = cacheKey(for: request.year, month: request.month)
        
        // 이미 캐시된 경우 스킵
        if let cachedMonth = cacheManager.getCachedMonth(for: key) {
            request.completion?(.success(cachedMonth))
            return
        }
        
        // 로딩 작업 생성
        let loadTask = Task {
            let result = await actuallyLoadMonth(year: request.year, month: request.month)
            
            // 결과를 캐시에 저장
            if case .success(let month) = result {
                cacheManager.setCachedMonth(month, for: key)
            }
            
            // 완료 핸들러 호출
            request.completion?(result)
            
            // 작업 완료 후 정리
            activeTasks.removeValue(forKey: key)
        }
        
        activeTasks[key] = loadTask
        await loadTask.value
    }
    
    private func actuallyLoadMonth(year: Int, month: Int) async -> Result<CalendarMonth, TodayBoardError> {
        // EventKitRepository를 통한 실제 데이터 로딩
        let repository = EventKitRepository()
        return await repository.fetchCalendarMonth(year: year, month: month)
    }
    
    private func cacheKey(for year: Int, month: Int) -> String {
        return "calendar_\(year)_\(String(format: "%02d", month))"
    }
    
    private func calculateYearMonth(_ year: Int, _ month: Int, offset: Int) -> (Int, Int) {
        let totalMonths = year * 12 + month - 1 + offset
        let newYear = totalMonths / 12
        let newMonth = totalMonths % 12 + 1
        return (newYear, newMonth)
    }
}

// MARK: - Result Extension
private extension Result {
    var value: Success? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
}