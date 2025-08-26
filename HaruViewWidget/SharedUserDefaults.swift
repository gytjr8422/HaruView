//
//  SharedUserDefaults.swift
//  HaruViewWidget
//
//  Created by Claude on 8/26/25.
//

import Foundation
import WidgetKit

/// 앱과 위젯 간 설정을 공유하기 위한 매니저 (위젯용)
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
        return shared?.integer(forKey: Keys.weekStartDay) ?? 0
    }
    
    // MARK: - Language Settings
    
    /// 선택된 언어 ("ko", "en", "ja")
    static var selectedLanguage: String {
        return shared?.string(forKey: Keys.selectedLanguage) ?? "ko"
    }
}