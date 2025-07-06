//
//  WidgetRefreshService.swift
//  HaruView
//
//  Created by 김효석 on 6/22/25.
//

import WidgetKit
import Foundation

@MainActor
final class WidgetRefreshService {
    static let shared = WidgetRefreshService()
    
    private init() {}
    
    /// 모든 하루뷰 위젯을 새로고침
    func refreshAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// 특정 위젯만 새로고침
    func refreshHaruWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "HaruViewWidget")
    }
    
    /// 즉시 새로고침 (디바운싱 없음) - 중요한 변경사항용
    func refreshImmediately() {
        refreshTask?.cancel()
        refreshHaruWidget()
    }
    
    /// 디바운싱된 새로고침 (짧은 시간 내 여러 번 호출 시 한 번만 실행)
    private var refreshTask: Task<Void, Never>?
    
    func refreshWithDebounce(delay: TimeInterval = 0.3) {
        refreshTask?.cancel()
        refreshTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else {
                return
            }
            refreshHaruWidget()
        }
    }
    
    /// 강제 새로고침 - 여러 방법을 시도
    func forceRefresh() {
        
        // 1. 즉시 새로고침
        refreshHaruWidget()
        
        // 2. 0.5초 후 다시 시도
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            refreshHaruWidget()
        }
        
        // 3. 모든 위젯 새로고침도 시도
        Task {
            try? await Task.sleep(for: .seconds(1.0))
            refreshAllWidgets()
        }
    }
}
