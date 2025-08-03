//
//  ProgressiveUpdateManager.swift
//  HaruView
//
//  Created by Claude on 8/3/25.
//

import SwiftUI
import Combine

@MainActor
final class ProgressiveUpdateManager: ObservableObject {
    
    // MARK: - Published State
    @Published private(set) var isProgressiveUpdateInProgress = false
    @Published private(set) var currentUpdatePhase: UpdatePhase = .idle
    @Published private(set) var backgroundDataReady = false
    
    // MARK: - Types
    enum UpdatePhase {
        case idle
        case backgroundLoading
        case dataReady
        case applying
        case completed
    }
    
    // MARK: - Private Properties
    private var pendingUpdates: [String: CalendarMonth] = [:]
    private var updateTimer: Timer?
    private let cacheManager = CalendarCacheManager.shared
    private let smartLoader = SmartDataLoader.shared
    
    // MARK: - Public Methods
    
    /// 점진적 업데이트 시작
    func startProgressiveUpdate(for year: Int, month: Int, completion: @escaping (CalendarMonth?) -> Void) {
        guard !isProgressiveUpdateInProgress else { return }
        
        isProgressiveUpdateInProgress = true
        currentUpdatePhase = .backgroundLoading
        
        Task {
            await performProgressiveUpdate(year: year, month: month, completion: completion)
        }
    }
    
    /// 백그라운드에서 여러 월 데이터 준비
    func prepareBackgroundData(centerYear: Int, centerMonth: Int, range: Int = 2) {
        Task.detached(priority: .utility) {
            await self.loadBackgroundData(centerYear: centerYear, centerMonth: centerMonth, range: range)
        }
    }
    
    /// 진행 중인 업데이트 취소
    func cancelProgressiveUpdate() {
        isProgressiveUpdateInProgress = false
        currentUpdatePhase = .idle
        backgroundDataReady = false
        pendingUpdates.removeAll()
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    /// 업데이트가 준비되었는지 확인
    func isUpdateReady(for year: Int, month: Int) -> Bool {
        let key = cacheKey(for: year, month: month)
        return pendingUpdates[key] != nil
    }
    
    /// 즉시 적용 가능한 업데이트 적용
    func applyReadyUpdate(for year: Int, month: Int) -> CalendarMonth? {
        let key = cacheKey(for: year, month: month)
        return pendingUpdates.removeValue(forKey: key)
    }
    
    // MARK: - Private Methods
    
    private func performProgressiveUpdate(year: Int, month: Int, completion: @escaping (CalendarMonth?) -> Void) async {
        let key = cacheKey(for: year, month: month)
        
        // 1. 캐시된 데이터가 있으면 즉시 반환
        if let cachedMonth = cacheManager.getCachedMonth(for: key) {
            await MainActor.run {
                self.currentUpdatePhase = .completed
                self.isProgressiveUpdateInProgress = false
                completion(cachedMonth)
            }
            return
        }
        
        // 2. 백그라운드에서 데이터 로드
        let result = await smartLoader.loadCurrentMonth(year: year, month: month)
        
        switch result {
        case .success(let month):
            await MainActor.run {
                self.pendingUpdates[key] = month
                self.currentUpdatePhase = .dataReady
                self.backgroundDataReady = true
                
                // 부드러운 전환을 위해 약간의 지연 후 적용
                self.scheduleUpdate {
                    self.currentUpdatePhase = .applying
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        completion(month)
                        self.currentUpdatePhase = .completed
                        self.isProgressiveUpdateInProgress = false
                        self.backgroundDataReady = false
                    }
                }
            }
            
        case .failure:
            await MainActor.run {
                self.currentUpdatePhase = .idle
                self.isProgressiveUpdateInProgress = false
                completion(nil)
            }
        }
    }
    
    private func loadBackgroundData(centerYear: Int, centerMonth: Int, range: Int) async {
        for offset in -range...range {
            let (year, month) = calculateYearMonth(centerYear, centerMonth, offset: offset)
            let key = cacheKey(for: year, month: month)
            
            // 이미 캐시되어 있거나 대기 중인 업데이트가 있으면 스킵
            if cacheManager.getCachedMonth(for: key) != nil || pendingUpdates[key] != nil {
                continue
            }
            
            let result = await smartLoader.loadAdjacentMonth(year: year, month: month)
            if case .success(let month) = result {
                await MainActor.run {
                    self.pendingUpdates[key] = month
                }
            }
        }
        
        await MainActor.run {
            self.backgroundDataReady = true
        }
    }
    
    private func scheduleUpdate(after delay: TimeInterval = 0.1, action: @escaping () -> Void) {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            action()
        }
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