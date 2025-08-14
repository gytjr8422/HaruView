//
//  Color+Extensions.swift
//  HaruView
//
//  Created by 김효석 on 5/4/25.
//

import SwiftUI

// MARK: - Convenience Initializers
extension Color {
    init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(
            red: Double(red) / 255.0,
            green: Double(green) / 255.0,
            blue: Double(blue) / 255.0
        )
    }
    
    init(hex: Int) {
        self.init(
            red: (hex >> 16) & 0xFF,
            green: (hex >> 8) & 0xFF,
            blue: hex & 0xFF
        )
    }
    
    init(hexCode: String) {
        var formattedHex = hexCode.trimmingCharacters(in: .whitespacesAndNewlines)
        formattedHex = formattedHex.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: formattedHex).scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}


// MARK: - 색상 관련
extension Color {
    
    /// 메인 브랜드 컬러 (#A76545)
    static let haruPrimary = Color(hexCode: "A76545")
    
    /// 메인 배경색 (#FFFCF5 - 크림색)
    static let haruBackground = Color(hexCode: "FFFCF5")
    
    /// 세컨더리 텍스트 및 보더 (#6E5C49)
    static let haruSecondary = Color(hexCode: "6E5C49")
    
    /// 다크 텍스트 (#40392B)
    static let haruTextPrimary = Color(hexCode: "40392B")
    
    /// 더 다크한 텍스트 (#2E2514)
    static let haruTextDark = Color(hexCode: "2E2514")
    
    /// 라이트 브라운 (#C2966B)
    static let haruAccent = Color(hexCode: "C2966B")
    
    // MARK: - Priority Colors
    
    /// 높은 우선순위 (#FF5722)
    static let haruPriorityHigh = Color(hexCode: "FF5722")
    
    /// 보통 우선순위 (#FFC107)
    static let haruPriorityMedium = Color(hexCode: "FFC107")
    
    /// 낮은 우선순위 (#4CAF50)
    static let haruPriorityLow = Color(hexCode: "4CAF50")
    
    // MARK: - Semantic Colors
    
    /// 완료된 항목 색상 (메인 컬러와 동일)
    static let haruCompleted = haruPrimary
    
    /// D-Day 강조 색상 (높은 우선순위와 동일)
    static let haruDDay = haruPriorityHigh
    
    /// 카운트다운 텍스트 색상 (메인 컬러와 동일)
    static let haruCountdown = haruPrimary
    
    /// 포커스된 입력 필드 보더
    static let haruFocused = haruPrimary
    
    /// 선택된 상태 배경
    static let haruSelectedBackground = haruPrimary.opacity(0.1)
    
    /// 선택된 상태 보더
    static let haruSelectedBorder = haruPrimary.opacity(0.2)
    
    /// 카드 배경 (메인 배경과 동일)
    static let haruCardBackground = haruBackground
    
    /// 카드 보더
    static let haruCardBorder = haruSecondary.opacity(0.2)
    
    /// 위젯 배경 (메인 배경과 동일)
    static let haruWidgetBackground = haruBackground
    
    // MARK: - Contextual Colors
    
    /// 세팅/옵션 배경
    static let haruSettingBackground = haruAccent.opacity(0.09)
    
    /// 세팅/옵션 보더
    static let haruSettingBorder = haruAccent.opacity(0.3)
    
    /// 비활성화된 요소
    static let haruDisabled = haruSecondary.opacity(0.5)
    
    /// 서브틀한 텍스트 (시간, 부가 정보)
    static let haruSubtext = haruTextDark.opacity(0.8)
    
    // MARK: - Calendar Specific Colors
    
    /// 공휴일 색상 (#9C27B0)
    static let haruHoliday = Color(hexCode: "9C27B0")
    
    /// 토요일 색상 (#2196F3)
    static let haruSaturday = Color(hexCode: "2196F3")
    
    // MARK: - Weather Colors
    
    /// 맑은 날씨 노란색 (#FDB813)
    static let haruWeatherSun = Color(hexCode: "FDB813")
    
    /// 회색 (#9CA3AF)
    static let haruWeatherGray = Color(hexCode: "9CA3AF")
    
    /// 파란색 (#5DADE2)
    static let haruWeatherBlue = Color(hexCode: "5DADE2")
    
    /// 밝은 파란색 (#6EC1E4)
    static let haruWeatherLightBlue = Color(hexCode: "6EC1E4")
    
    /// 번개 노란색 (#F4D03F)
    static let haruWeatherLightning = Color(hexCode: "F4D03F")
    
    /// 비 파란색 (#3498DB)
    static let haruWeatherRain = Color(hexCode: "3498DB")
    
    /// 안개 회색 (#AAB2BD)
    static let haruWeatherFog = Color(hexCode: "AAB2BD")
    
    /// 모래 색상 (#F4C27A)
    static let haruWeatherSand = Color(hexCode: "F4C27A")
    
    /// 재 회색 (#B0B0B0)
    static let haruWeatherAsh = Color(hexCode: "B0B0B0")
    
    /// 토네이도 녹색 (#58D68D)
    static let haruWeatherTornado = Color(hexCode: "58D68D")
    
    /// 뜨거운 빨간색 (#FF5733)
    static let haruWeatherHot = Color(hexCode: "FF5733")
    
    /// 차가운 파란색 (#3498DB)
    static let haruWeatherCold = Color(hexCode: "3498DB")
    
    /// 바람 색상 (#AED6F1)
    static let haruWeatherWind = Color(hexCode: "AED6F1")
}

// MARK: - Convenience Methods

extension Color {
    
    /// 우선순위에 따른 색상 반환
    static func haruPriorityColor(for priority: Int) -> Color {
        switch priority {
        case 1: return .haruPriorityHigh
        case 5: return .haruPriorityMedium
        case 9: return .haruPriorityLow
        default: return .secondary
        }
    }
    
    /// 완료 상태에 따른 불투명도 적용
    func haruCompletedOpacity(_ isCompleted: Bool) -> Color {
        return self.opacity(isCompleted ? 0.5 : 1.0)
    }
    
    /// 선택 상태에 따른 색상 반환
    static func haruSelectionColor(isSelected: Bool) -> Color {
        return isSelected ? .haruPrimary : .haruSecondary
    }
}
