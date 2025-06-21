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
    
    /// 디바운싱된 새로고침 (짧은 시간 내 여러 번 호출 시 한 번만 실행)
    private var refreshTask: Task<Void, Never>?
    
    func refreshWithDebounce(delay: TimeInterval = 0.3) {
        refreshTask?.cancel()
        refreshTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            refreshHaruWidget()
        }
    }
}
