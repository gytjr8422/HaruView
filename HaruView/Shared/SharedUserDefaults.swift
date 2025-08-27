import Foundation
import WidgetKit

// IMPORTANT: 
// 1. Add this file to both the `HaruView` and `HaruViewWidget` targets in Xcode.
// 2. Enable App Groups for both targets in Xcode's "Signing & Capabilities" tab 
//    with the identifier used below.
struct SharedUserDefaults {
    // Make sure this identifier matches the one in your App Group settings.
    private static let suiteName = "group.com.hskim.HaruView"
    private static let userDefaults = UserDefaults(suiteName: suiteName)

    private static let languageKey = "selectedLanguage"
    private static let weekStartDayKey = "weekStartDay"

    static var selectedLanguage: String {
        get {
            userDefaults?.string(forKey: languageKey) ?? "ko"
        }
        set {
            userDefaults?.set(newValue, forKey: languageKey)
            userDefaults?.synchronize()
            // When the language is set, immediately reload all widgets.
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    static var weekStartDay: Int {
        get {
            userDefaults?.integer(forKey: weekStartDayKey) ?? 0
        }
        set {
            userDefaults?.set(newValue, forKey: weekStartDayKey)
            userDefaults?.synchronize()
            // When the setting is changed, immediately reload all widgets.
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    /// 위젯 업데이트 알림
    static func notifyWidgetUpdate() {
        userDefaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
