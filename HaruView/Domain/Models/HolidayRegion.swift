//
//  HolidayRegion.swift
//  HaruView
//
//  Created by 김효석 on 8/1/25.
//

import Foundation

struct HolidayRegion: Identifiable, Hashable, Codable {
    var id = UUID()
    let localeIdentifier: String
    let displayName: String
    let flagEmoji: String
    let continent: Continent
    
    enum Continent: String, CaseIterable, Codable {
        case auto = "자동"
        case asia = "아시아"
        case northAmerica = "북미"
        case europe = "유럽"
        case oceania = "오세아니아"
        case southAmerica = "남미"
    }
    
    // 기본 캘린더 연동 + Apple EventKit 확인된 지원 국가들
    static let availableRegions: [HolidayRegion] = [
        // 자동 (기본 캘린더 연동)
        HolidayRegion(localeIdentifier: "auto", displayName: "자동 (기본 캘린더)", flagEmoji: "🌍", continent: .auto),
        
        // 주요 지원 국가들 (확인된 지원 국가만)
        HolidayRegion(localeIdentifier: "ko_KR", displayName: "대한민국", flagEmoji: "🇰🇷", continent: .asia),
        HolidayRegion(localeIdentifier: "ja_JP", displayName: "일본", flagEmoji: "🇯🇵", continent: .asia),
        HolidayRegion(localeIdentifier: "zh_CN", displayName: "중국", flagEmoji: "🇨🇳", continent: .asia),
        HolidayRegion(localeIdentifier: "zh_HK", displayName: "홍콩", flagEmoji: "🇭🇰", continent: .asia),
        HolidayRegion(localeIdentifier: "hi_IN", displayName: "인도", flagEmoji: "🇮🇳", continent: .asia),
        
        HolidayRegion(localeIdentifier: "en_US", displayName: "미국", flagEmoji: "🇺🇸", continent: .northAmerica),
        HolidayRegion(localeIdentifier: "en_CA", displayName: "캐나다", flagEmoji: "🇨🇦", continent: .northAmerica),
        HolidayRegion(localeIdentifier: "es_MX", displayName: "멕시코", flagEmoji: "🇲🇽", continent: .northAmerica),
        
        HolidayRegion(localeIdentifier: "en_GB", displayName: "영국", flagEmoji: "🇬🇧", continent: .europe),
        HolidayRegion(localeIdentifier: "de_DE", displayName: "독일", flagEmoji: "🇩🇪", continent: .europe),
        HolidayRegion(localeIdentifier: "fr_FR", displayName: "프랑스", flagEmoji: "🇫🇷", continent: .europe),
        HolidayRegion(localeIdentifier: "it_IT", displayName: "이탈리아", flagEmoji: "🇮🇹", continent: .europe),
        HolidayRegion(localeIdentifier: "es_ES", displayName: "스페인", flagEmoji: "🇪🇸", continent: .europe),
        HolidayRegion(localeIdentifier: "sv_SE", displayName: "스웨덴", flagEmoji: "🇸🇪", continent: .europe),
        
        HolidayRegion(localeIdentifier: "en_AU", displayName: "호주", flagEmoji: "🇦🇺", continent: .oceania),
        HolidayRegion(localeIdentifier: "pt_BR", displayName: "브라질", flagEmoji: "🇧🇷", continent: .southAmerica),
    ]
    
    static var `default`: HolidayRegion {
        // 기본값은 자동 (기본 캘린더 연동)
        return availableRegions.first { $0.localeIdentifier == "auto" }!
    }
    
    static func regionsByContinent() -> [Continent: [HolidayRegion]] {
        Dictionary(grouping: availableRegions, by: { $0.continent })
    }
}

// MARK: - AppSettings
@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var holidayRegion: HolidayRegion {
        didSet {
            saveHolidayRegion()
            // 공휴일 설정 변경 시 달력 강제 새로고침
            NotificationCenter.default.post(name: .calendarNeedsRefresh, object: nil)
        }
    }
    
    @Published var showHolidays: Bool {
        didSet {
            UserDefaults.standard.set(showHolidays, forKey: "showHolidays")
            // 공휴일 표시 설정 변경 시 displayItems 캐시만 무효화
            clearDisplayItemsCache()
            // 달력 새로고침 알림
            NotificationCenter.default.post(name: .calendarNeedsRefresh, object: nil)
        }
    }
    
    // 선택된 공휴일 캘린더 ID들
    @Published var selectedHolidayCalendarIds: Set<String> {
        didSet {
            let array = Array(selectedHolidayCalendarIds)
            UserDefaults.standard.set(array, forKey: "selectedHolidayCalendarIds")
            clearDisplayItemsCache()
            // 달력 새로고침 알림
            NotificationCenter.default.post(name: .calendarNeedsRefresh, object: nil)
        }
    }
    
    private init() {
        self.holidayRegion = Self.loadHolidayRegion()
        self.showHolidays = UserDefaults.standard.object(forKey: "showHolidays") as? Bool ?? true
        self.selectedHolidayCalendarIds = Set(UserDefaults.standard.stringArray(forKey: "selectedHolidayCalendarIds") ?? [])
    }
    
    // Main actor 격리 없이 접근 가능한 현재 설정 조회 메서드
    nonisolated func getCurrentHolidayRegion() -> HolidayRegion {
        return Self.loadHolidayRegion()
    }
    
    nonisolated func getShowHolidays() -> Bool {
        return UserDefaults.standard.object(forKey: "showHolidays") as? Bool ?? true
    }
    
    nonisolated private static func loadHolidayRegion() -> HolidayRegion {
        guard let data = UserDefaults.standard.data(forKey: "holidayRegion"),
              let region = try? JSONDecoder().decode(HolidayRegion.self, from: data) else {
            return HolidayRegion.default
        }
        return region
    }
    
    private func saveHolidayRegion() {
        if let data = try? JSONEncoder().encode(holidayRegion) {
            UserDefaults.standard.set(data, forKey: "holidayRegion")
        }
    }
    
    /// 공휴일 설정 변경 시 displayItems 캐시만 무효화
    private func clearDisplayItemsCache() {
        Task { @MainActor in
            CalendarCacheManager.shared.clearDisplayItemsCache()
        }
    }
}
