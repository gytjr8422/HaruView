import Foundation
import WidgetKit
import SwiftUI

enum Language: String, CaseIterable {
    case korean = "ko"
    case english = "en" 
    case japanese = "ja"
    
    var title: String {
        return self.rawValue
    }
    
    var displayName: String {
        switch self {
        case .korean:
            return "한국어"
        case .english:
            return "English"
        case .japanese:
            return "日本語"
        }
    }
    
    /// Apple 언어 설정용 코드 (AppleLanguages)
    var appleLanguageCode: String {
        switch self {
        case .korean:
            return "ko-KR"
        case .english:
            return "en-US"
        case .japanese:
            return "ja-JP"
        }
    }
    
    /// .lproj 폴더명과 Bundle path용 코드
    var bundleIdentifier: String {
        return self.rawValue
    }
    
    /// DateFormatter, NumberFormatter 등에서 사용할 전체 locale 식별자
    var localeIdentifier: String {
        switch self {
        case .korean:
            return "ko_KR"
        case .english:
            return "en_US"
        case .japanese:
            return "ja_JP"
        }
    }
    
    /// Locale 객체 반환
    var locale: Locale {
        return Locale(identifier: localeIdentifier)
    }
    
    /// 시스템 언어 코드에서 Language enum으로 변환
    static func from(systemLanguageCode: String) -> Language {
        let languageCode = systemLanguageCode.prefix(2).lowercased()
        switch languageCode {
        case "ko": return .korean
        case "ja": return .japanese
        case "en": return .english
        default: return .korean // 기본값
        }
    }
    
    /// Locale 객체에서 Language enum으로 변환
    static func from(locale: Locale) -> Language {
        guard let languageCode = locale.language.languageCode?.identifier else {
            return .korean
        }
        return from(systemLanguageCode: languageCode)
    }
}

// Bundle 교체를 위한 클래스
class BundleEx: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        return (LanguageManager.shared.currentBundle ?? Bundle.main).localizedString(forKey: key, value: value, table: tableName)
    }
}

final class LanguageManager: ObservableObject {
    @Published var selectedLanguage: String = Language.korean.title
    @Published var refreshTrigger = UUID()
    
    static let shared = LanguageManager()
    
    var currentBundle: Bundle?
    private var bundleCache: [String: Bundle] = [:] // Bundle 캐싱
    
    /// 언어 변경 debouncing을 위한 타이머
    private var languageChangeTimer: Timer?
    
    /// 캐시된 Locale 객체들
    private var localeCache: [String: Locale] = [:]
    
    private init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") ?? detectSystemLanguage()
        self.selectedLanguage = savedLanguage
        setCurrentLanguage(savedLanguage)
    }
    
    /// 시스템 언어를 감지하여 앱에서 지원하는 언어로 매핑
    private func detectSystemLanguage() -> String {
        let systemLanguages = Locale.preferredLanguages
        
        // 첫 번째 언어(주 언어)만 확인
        guard let primaryLanguage = systemLanguages.first else {
            print("🌍 No system language found, defaulting to Korean")
            return Language.korean.title
        }
        
        let detectedLanguage = Language.from(systemLanguageCode: primaryLanguage)
        print("🌍 System language detected: \(detectedLanguage.displayName)")
        return detectedLanguage.title
    }
    
    func updateLanguage(_ language: String) {
        print("🔄 Changing language to: \(language)")
        
        // 이전 타이머 취소
        languageChangeTimer?.invalidate()
        
        // Debouncing: 0.3초 후에 실제 언어 변경 수행
        languageChangeTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.performLanguageUpdate(language)
        }
    }
    
    private func performLanguageUpdate(_ language: String) {
        selectedLanguage = language
        UserDefaults.standard.set(language, forKey: "AppLanguage")
        
        // AppleLanguages도 설정 (앱 재시작 시 적용)
        if let lang = Language(rawValue: language) {
            UserDefaults.standard.set([lang.appleLanguageCode], forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
        
        // 언어 Bundle 변경
        setCurrentLanguage(language)
        
        // DateFormatterFactory 캐시 클리어 (새로운 언어에 맞는 포맷터 사용)
        DateFormatterFactory.clearCache()
        
        // 날씨 캐시 클리어 (새로운 언어에 맞는 지역명 사용)
        clearWeatherCache()
        
        // UI 업데이트 트리거 (단일 호출)
        DispatchQueue.main.async {
            self.refreshTrigger = UUID()
        }
        
        // 위젯 새로고침 (비동기)
        Task {
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        print("✅ Language changed to: \(language)")
    }
    
    private func setCurrentLanguage(_ language: String) {
        // Bundle 클래스 교체 (한 번만 수행)
        if object_getClass(Bundle.main) != BundleEx.self {
            object_setClass(Bundle.main, BundleEx.self)
        }
        
        // 캐시된 Bundle 확인
        if let cachedBundle = bundleCache[language] {
            currentBundle = cachedBundle
            print("✅ Using cached bundle for: \(language)")
            return
        }
        
        // 새 Bundle 생성 및 캐싱
        let languageEnum = Language(rawValue: language) ?? .korean
        let bundleIdentifier = languageEnum.bundleIdentifier
        
        if let path = Bundle.main.path(forResource: bundleIdentifier, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            currentBundle = bundle
            bundleCache[language] = bundle // 캐싱
            print("✅ Bundle created and cached for: \(language) -> \(bundleIdentifier)")
        } else {
            currentBundle = Bundle.main
            bundleCache[language] = Bundle.main // 폴백도 캐싱
            print("⚠️ Fallback to main bundle for language: \(language)")
        }
    }
    
    var currentLanguage: Language {
        return Language(rawValue: selectedLanguage) ?? .korean
    }
    
    func localizedString(forKey key: String) -> String {
        // Bundle에서 번역 가져오기
        return (currentBundle ?? Bundle.main).localizedString(forKey: key, value: key, table: nil)
    }
    
    /// 캐시된 Locale 반환 (성능 최적화)
    func getCachedLocale(for language: Language) -> Locale {
        let key = language.localeIdentifier
        
        if let cachedLocale = localeCache[key] {
            return cachedLocale
        }
        
        let locale = Locale(identifier: key)
        localeCache[key] = locale
        return locale
    }
    
    /// 메모리 정리
    func clearCache() {
        localeCache.removeAll()
        bundleCache.removeAll()
    }
    
    /// 날씨 캐시 클리어 (언어 변경 시 호출)
    private func clearWeatherCache() {
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        
        // weatherCache_ 로 시작하는 모든 키를 삭제
        let weatherCacheKeys = allKeys.filter { $0.hasPrefix("weatherCache_") }
        for key in weatherCacheKeys {
            defaults.removeObject(forKey: key)
        }
        
        defaults.synchronize()
        print("🧹 Weather cache cleared for language change")
    }
}

// 반응형 Text를 위한 구조체
struct LocalizedText: View {
    let key: String
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        Text(languageManager.localizedString(forKey: key))
    }
}

// String extension - Bundle에서 직접 번역 가져오기
extension String {
    func localized() -> String {
        return LanguageManager.shared.localizedString(forKey: self)
    }
    
    func localized(with arguments: CVarArg...) -> String {
        let localizedString = LanguageManager.shared.localizedString(forKey: self)
        return String(format: localizedString, arguments: arguments)
    }
}