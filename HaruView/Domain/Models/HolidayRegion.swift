//
//  HolidayRegion.swift
//  HaruView
//
//  Created by 김효석 on 8/1/25.
//

import Foundation

struct HolidayRegion: Identifiable, Hashable, Codable {
    let id = UUID()
    let localeIdentifier: String
    let displayName: String
    let flagEmoji: String
    let continent: Continent
    
    enum Continent: String, CaseIterable, Codable {
        case asia = "아시아"
        case northAmerica = "북미"
        case europe = "유럽"
        case oceania = "오세아니아"
        case southAmerica = "남미"
        case africa = "아프리카"
        case middleEast = "중동"
    }
    
    static let availableRegions: [HolidayRegion] = [
        // 아시아
        HolidayRegion(localeIdentifier: "ko_KR", displayName: "대한민국", flagEmoji: "🇰🇷", continent: .asia),
        HolidayRegion(localeIdentifier: "ja_JP", displayName: "일본", flagEmoji: "🇯🇵", continent: .asia),
        HolidayRegion(localeIdentifier: "zh_CN", displayName: "중국", flagEmoji: "🇨🇳", continent: .asia),
        HolidayRegion(localeIdentifier: "zh_TW", displayName: "대만", flagEmoji: "🇹🇼", continent: .asia),
        HolidayRegion(localeIdentifier: "hi_IN", displayName: "인도", flagEmoji: "🇮🇳", continent: .asia),
        HolidayRegion(localeIdentifier: "th_TH", displayName: "태국", flagEmoji: "🇹🇭", continent: .asia),
        HolidayRegion(localeIdentifier: "vi_VN", displayName: "베트남", flagEmoji: "🇻🇳", continent: .asia),
        HolidayRegion(localeIdentifier: "ms_SG", displayName: "싱가포르", flagEmoji: "🇸🇬", continent: .asia),
        HolidayRegion(localeIdentifier: "ms_MY", displayName: "말레이시아", flagEmoji: "🇲🇾", continent: .asia),
        HolidayRegion(localeIdentifier: "id_ID", displayName: "인도네시아", flagEmoji: "🇮🇩", continent: .asia),
        HolidayRegion(localeIdentifier: "tl_PH", displayName: "필리핀", flagEmoji: "🇵🇭", continent: .asia),
        
        // 북미
        HolidayRegion(localeIdentifier: "en_US", displayName: "미국", flagEmoji: "🇺🇸", continent: .northAmerica),
        HolidayRegion(localeIdentifier: "en_CA", displayName: "캐나다", flagEmoji: "🇨🇦", continent: .northAmerica),
        HolidayRegion(localeIdentifier: "es_MX", displayName: "멕시코", flagEmoji: "🇲🇽", continent: .northAmerica),
        
        // 유럽
        HolidayRegion(localeIdentifier: "en_GB", displayName: "영국", flagEmoji: "🇬🇧", continent: .europe),
        HolidayRegion(localeIdentifier: "de_DE", displayName: "독일", flagEmoji: "🇩🇪", continent: .europe),
        HolidayRegion(localeIdentifier: "fr_FR", displayName: "프랑스", flagEmoji: "🇫🇷", continent: .europe),
        HolidayRegion(localeIdentifier: "it_IT", displayName: "이탈리아", flagEmoji: "🇮🇹", continent: .europe),
        HolidayRegion(localeIdentifier: "es_ES", displayName: "스페인", flagEmoji: "🇪🇸", continent: .europe),
        HolidayRegion(localeIdentifier: "nl_NL", displayName: "네덜란드", flagEmoji: "🇳🇱", continent: .europe),
        HolidayRegion(localeIdentifier: "sv_SE", displayName: "스웨덴", flagEmoji: "🇸🇪", continent: .europe),
        HolidayRegion(localeIdentifier: "no_NO", displayName: "노르웨이", flagEmoji: "🇳🇴", continent: .europe),
        HolidayRegion(localeIdentifier: "da_DK", displayName: "덴마크", flagEmoji: "🇩🇰", continent: .europe),
        HolidayRegion(localeIdentifier: "fi_FI", displayName: "핀란드", flagEmoji: "🇫🇮", continent: .europe),
        HolidayRegion(localeIdentifier: "ru_RU", displayName: "러시아", flagEmoji: "🇷🇺", continent: .europe),
        HolidayRegion(localeIdentifier: "pl_PL", displayName: "폴란드", flagEmoji: "🇵🇱", continent: .europe),
        
        // 오세아니아
        HolidayRegion(localeIdentifier: "en_AU", displayName: "호주", flagEmoji: "🇦🇺", continent: .oceania),
        HolidayRegion(localeIdentifier: "en_NZ", displayName: "뉴질랜드", flagEmoji: "🇳🇿", continent: .oceania),
        
        // 남미
        HolidayRegion(localeIdentifier: "pt_BR", displayName: "브라질", flagEmoji: "🇧🇷", continent: .southAmerica),
        HolidayRegion(localeIdentifier: "es_AR", displayName: "아르헨티나", flagEmoji: "🇦🇷", continent: .southAmerica),
        HolidayRegion(localeIdentifier: "es_CL", displayName: "칠레", flagEmoji: "🇨🇱", continent: .southAmerica),
        
        // 중동
        HolidayRegion(localeIdentifier: "ar_SA", displayName: "사우디아라비아", flagEmoji: "🇸🇦", continent: .middleEast),
        HolidayRegion(localeIdentifier: "ar_AE", displayName: "아랍에미리트", flagEmoji: "🇦🇪", continent: .middleEast),
        HolidayRegion(localeIdentifier: "he_IL", displayName: "이스라엘", flagEmoji: "🇮🇱", continent: .middleEast),
        HolidayRegion(localeIdentifier: "tr_TR", displayName: "터키", flagEmoji: "🇹🇷", continent: .middleEast),
        
        // 아프리카
        HolidayRegion(localeIdentifier: "af_ZA", displayName: "남아프리카공화국", flagEmoji: "🇿🇦", continent: .africa),
        HolidayRegion(localeIdentifier: "ar_EG", displayName: "이집트", flagEmoji: "🇪🇬", continent: .africa),
    ]
    
    static var `default`: HolidayRegion {
        // 시스템 로케일에 따라 기본값 결정
        let systemLocale = Locale.current.identifier
        return availableRegions.first { $0.localeIdentifier == systemLocale } 
            ?? availableRegions.first { $0.localeIdentifier == "ko_KR" }!
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
    
    private init() {
        self.holidayRegion = Self.loadHolidayRegion()
    }
    
    // Main actor 격리 없이 접근 가능한 현재 설정 조회 메서드
    nonisolated func getCurrentHolidayRegion() -> HolidayRegion {
        return Self.loadHolidayRegion()
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
}