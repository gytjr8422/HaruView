//
//  DateFormatterFactory.swift
//  HaruView
//
//  Created by 김효석 on 5/4/25.
//

import Foundation

/// 캐싱과 동적 locale을 지원하는 효율적인 DateFormatter 팩토리
enum DateFormatterFactory {
    
    // MARK: - Cached Formatters
    
    private static var cachedFormatters: [String: DateFormatter] = [:]
    private static let lock = NSLock()
    
    // MARK: - Predefined Format Types
    
    enum FormatType {
        case dateWithDay
        case shortDate
        case mediumDate
        case shortTime
        case mediumTime
        case dateTime
        case custom(String)
        
        func formatString(for language: Language) -> String {
            switch self {
            case .dateWithDay:
                switch language {
                case .korean: return "M월 d일, EEEE"
                case .english: return "EEEE, MMMM d"
                case .japanese: return "M月d日, EEEE"
                }
            case .shortDate:
                return "MMM d"
            case .mediumDate:
                return "MMM d, yyyy"
            case .shortTime:
                return "HH:mm"
            case .mediumTime:
                return "h:mm a"
            case .dateTime:
                return "MMM d, yyyy h:mm a"
            case .custom(let format):
                return format
            }
        }
        
        var cacheKey: String {
            switch self {
            case .dateWithDay: return "dateWithDay"
            case .shortDate: return "shortDate"
            case .mediumDate: return "mediumDate"
            case .shortTime: return "shortTime"
            case .mediumTime: return "mediumTime"
            case .dateTime: return "dateTime"
            case .custom(let format): return "custom_\(format)"
            }
        }
    }
    
    // MARK: - Main Factory Method
    
    /// 캐싱된 DateFormatter를 반환하거나 새로 생성하여 캐싱
    static func formatter(for type: FormatType, language: Language) -> DateFormatter {
        let cacheKey = "\(type.cacheKey)_\(language.rawValue)"
        
        lock.lock()
        defer { lock.unlock() }
        
        if let cachedFormatter = cachedFormatters[cacheKey] {
            return cachedFormatter
        }
        
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = type.formatString(for: language)
        
        cachedFormatters[cacheKey] = formatter
        return formatter
    }
    
    // MARK: - Convenience Methods (현재 언어 사용)
    
    /// 현재 LanguageManager 언어를 사용하는 편의 메소드
    static func formatter(for type: FormatType) -> DateFormatter {
        let currentLanguage = LanguageManager.shared.currentLanguage
        return formatter(for: type, language: currentLanguage)
    }
    
    // MARK: - Legacy Support (하위 호환성)
    
    /// 하위 호환성을 위한 메소드 (Deprecated)
    @available(*, deprecated, message: "Use formatter(for: .dateWithDay) instead")
    static func koreanDateWithDayFormatter() -> DateFormatter {
        return formatter(for: .dateWithDay, language: .korean)
    }
    
    @available(*, deprecated, message: "Use formatter(for: .dateWithDay) instead")
    static func englishDateWithDayFormatter() -> DateFormatter {
        return formatter(for: .dateWithDay, language: .english)
    }
    
    @available(*, deprecated, message: "Use formatter(for: .dateWithDay) instead")
    static func japaneseDateWithDayFormatter() -> DateFormatter {
        return formatter(for: .dateWithDay, language: .japanese)
    }
    
    @available(*, deprecated, message: "Use formatter(for: .custom(format), language: language) instead")
    static func customFormatter(format: String, locale: Locale = .current) -> DateFormatter {
        let language = Language.from(locale: locale)
        return formatter(for: .custom(format), language: language)
    }
    
    // MARK: - Cache Management
    
    /// 캐시 정리 (메모리 압박 시 사용)
    static func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cachedFormatters.removeAll()
    }
    
    /// 캐시 통계 (디버깅용)
    static func cacheInfo() -> (count: Int, keys: [String]) {
        lock.lock()
        defer { lock.unlock() }
        return (cachedFormatters.count, Array(cachedFormatters.keys))
    }
}
