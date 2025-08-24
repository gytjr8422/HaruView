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
            print("🌍 No system language found, defaulting to English")
            return Language.english.title
        }
        
        // 언어 코드만 추출 (예: "ko-KR" -> "ko", "ja-JP" -> "ja")
        let languageCode = String(primaryLanguage.prefix(2))
        
        switch languageCode {
        case "ko":
            print("🌍 Primary system language detected: Korean")
            return Language.korean.title
        case "ja":
            print("🌍 Primary system language detected: Japanese") 
            return Language.japanese.title
        case "en":
            print("🌍 Primary system language detected: English")
            return Language.english.title
        default:
            // 첫 번째 언어가 지원되지 않으면 영어로 기본 설정
            print("🌍 Primary system language (\(languageCode)) not supported, defaulting to English")
            return Language.english.title
        }
    }
    
    func updateLanguage(_ language: String) {
        print("🔄 Changing language to: \(language)")
        
        selectedLanguage = language
        UserDefaults.standard.set(language, forKey: "AppLanguage")
        
        // AppleLanguages도 설정 (앱 재시작 시 적용)
        if let lang = Language(rawValue: language) {
            UserDefaults.standard.set([lang.appleLanguageCode], forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
        
        // 언어 Bundle 변경
        setCurrentLanguage(language)
        
        // UI 업데이트 트리거 (단일 호출)
        refreshTrigger = UUID()
        
        // 위젯 새로고침
        WidgetCenter.shared.reloadAllTimelines()
        
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
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            currentBundle = bundle
            bundleCache[language] = bundle // 캐싱
            print("✅ Bundle created and cached for: \(language)")
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