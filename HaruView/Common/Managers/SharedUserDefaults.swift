//
//  SharedUserDefaults.swift
//  HaruView
//
//  Created by Claude on 8/25/25.
//

import Foundation

/// 앱과 위젯 간 설정을 공유하기 위한 매니저
final class SharedUserDefaults {
    
    // MARK: - Constants
    
    private static let suiteName = "group.com.hskim.HaruView"
    
    // MARK: - Keys
    
    private enum Keys {
        static let weekStartDay = "weekStartDay"
        static let selectedLanguage = "selectedLanguage"
    }
    
    // MARK: - Shared Instance
    
    private static let shared = UserDefaults(suiteName: suiteName)
    
    // MARK: - Week Start Day
    
    /// 주 시작 요일 (0: 일요일, 1: 월요일)
    static var weekStartDay: Int {
        get {
            return shared?.integer(forKey: Keys.weekStartDay) ?? 0
        }
        set {
            shared?.set(newValue, forKey: Keys.weekStartDay)
        }
    }
    
    // MARK: - Language Settings
    
    /// 선택된 언어 ("ko", "en", "ja")
    static var selectedLanguage: String {
        get {
            return shared?.string(forKey: Keys.selectedLanguage) ?? "ko"
        }
        set {
            shared?.set(newValue, forKey: Keys.selectedLanguage)
        }
    }
    
    // MARK: - Helper Methods
    
    /// 앱에서 설정이 변경되었을 때 위젯에 알림
    static func notifyWidgetUpdate() {
        shared?.synchronize()
        
        // 위젯 리로드 요청
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - WidgetCenter Import

import WidgetKit