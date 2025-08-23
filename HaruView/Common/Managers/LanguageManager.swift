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
class BundleEx: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        return (LanguageManager.shared.currentBundle ?? Bundle.main).localizedString(forKey: key, value: value, table: tableName)
    }
}

final class LanguageManager: ObservableObject {
    @Published var selectedLanguage: String = Language.korean.title
    @Published var refreshTrigger = UUID()
    
    static let shared = LanguageManager()
    
    var currentBundle: Bundle?
    
    private init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") ?? Language.korean.title
        self.selectedLanguage = savedLanguage
        setCurrentLanguage(savedLanguage)
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
        
        // UI 즉시 업데이트 트리거
        DispatchQueue.main.async {
            self.refreshTrigger = UUID()
        }
        
        // 0.1초 후 한번 더 (확실하게)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.refreshTrigger = UUID()
        }
        
        // 위젯 새로고침
        WidgetCenter.shared.reloadAllTimelines()
        
        print("✅ Language changed to: \(language)")
    }
    
    private func setCurrentLanguage(_ language: String) {
        // Bundle 클래스 교체
        object_setClass(Bundle.main, BundleEx.self)
        
        // 언어별 Bundle 설정
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            currentBundle = bundle
            print("✅ Bundle set to: \(path)")
        } else {
            currentBundle = Bundle.main
            print("⚠️ Fallback to main bundle for language: \(language)")
        }
    }
    
    var currentLanguage: Language {
        return Language(rawValue: selectedLanguage) ?? .korean
    }
    
    func localizedString(forKey key: String) -> String {
        // refreshTrigger 의존성 생성
        let _ = refreshTrigger
        
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