//
//  Color+HaruView.swift
//  HaruView
//
//  Created by Claude on 8/13/25.
//

import SwiftUI

// MARK: - ShapeStyle Extension for Semantic Colors
extension ShapeStyle where Self == Color {
    
    // MARK: - HaruView Theme Colors
    
    /// 메인 브랜드 컬러 (#A76545)
    static var haruPrimary: Color { Color(hexCode: "A76545") }
    
    /// 메인 배경색 (#FFFCF5 - 크림색)
    static var haruBackground: Color { Color(hexCode: "FFFCF5") }
    
    /// 세컨더리 텍스트 및 보더 (#6E5C49)
    static var haruSecondary: Color { Color(hexCode: "6E5C49") }
    
    /// 다크 텍스트 (#40392B)
    static var haruTextPrimary: Color { Color(hexCode: "40392B") }
    
    /// 더 다크한 텍스트 (#2E2514)
    static var haruTextDark: Color { Color(hexCode: "2E2514") }
    
    /// 라이트 브라운 (#C2966B)
    static var haruAccent: Color { Color(hexCode: "C2966B") }
    
    // MARK: - Priority Colors
    
    /// 높은 우선순위 (#FF5722)
    static var haruPriorityHigh: Color { Color(hexCode: "FF5722") }
    
    /// 보통 우선순위 (#FFC107)  
    static var haruPriorityMedium: Color { Color(hexCode: "FFC107") }
    
    /// 낮은 우선순위 (#4CAF50)
    static var haruPriorityLow: Color { Color(hexCode: "4CAF50") }
    
    // MARK: - Semantic Colors
    
    /// 완료된 항목 색상 (메인 컬러와 동일)
    static var haruCompleted: Color { haruPrimary }
    
    /// D-Day 강조 색상 (높은 우선순위와 동일)
    static var haruDDay: Color { haruPriorityHigh }
    
    /// 카운트다운 텍스트 색상 (메인 컬러와 동일)
    static var haruCountdown: Color { haruPrimary }
    
    /// 포커스된 입력 필드 보더
    static var haruFocused: Color { haruPrimary }
    
    /// 선택된 상태 배경
    static var haruSelectedBackground: Color { haruPrimary.opacity(0.1) }
    
    /// 선택된 상태 보더
    static var haruSelectedBorder: Color { haruPrimary.opacity(0.2) }
    
    /// 카드 배경 (메인 배경과 동일)
    static var haruCardBackground: Color { haruBackground }
    
    /// 카드 보더
    static var haruCardBorder: Color { haruSecondary.opacity(0.2) }
    
    /// 위젯 배경 (메인 배경과 동일)
    static var haruWidgetBackground: Color { haruBackground }
    
    // MARK: - Contextual Colors
    
    /// 세팅/옵션 배경
    static var haruSettingBackground: Color { haruAccent.opacity(0.09) }
    
    /// 세팅/옵션 보더
    static var haruSettingBorder: Color { haruAccent.opacity(0.3) }
    
    /// 비활성화된 요소
    static var haruDisabled: Color { haruSecondary.opacity(0.5) }
    
    /// 서브틀한 텍스트 (시간, 부가 정보)
    static var haruSubtext: Color { haruTextDark.opacity(0.8) }
    
    // MARK: - Calendar Specific Colors
    
    /// 공휴일 색상 (#9C27B0)
    static var haruHoliday: Color { Color(hexCode: "9C27B0") }
    
    /// 토요일 색상 (#2196F3)
    static var haruSaturday: Color { Color(hexCode: "2196F3") }
    
    // MARK: - Weather Colors
    
    /// 맑은 날씨 노란색 (#FDB813)
    static var haruWeatherSun: Color { Color(hexCode: "FDB813") }
    
    /// 회색 (#9CA3AF)
    static var haruWeatherGray: Color { Color(hexCode: "9CA3AF") }
    
    /// 파란색 (#5DADE2)
    static var haruWeatherBlue: Color { Color(hexCode: "5DADE2") }
    
    /// 밝은 파란색 (#6EC1E4)
    static var haruWeatherLightBlue: Color { Color(hexCode: "6EC1E4") }
    
    /// 번개 노란색 (#F4D03F)
    static var haruWeatherLightning: Color { Color(hexCode: "F4D03F") }
    
    /// 비 파란색 (#3498DB)
    static var haruWeatherRain: Color { Color(hexCode: "3498DB") }
    
    /// 안개 회색 (#AAB2BD)
    static var haruWeatherFog: Color { Color(hexCode: "AAB2BD") }
    
    /// 모래 색상 (#F4C27A)
    static var haruWeatherSand: Color { Color(hexCode: "F4C27A") }
    
    /// 재 회색 (#B0B0B0)
    static var haruWeatherAsh: Color { Color(hexCode: "B0B0B0") }
    
    /// 토네이도 녹색 (#58D68D)
    static var haruWeatherTornado: Color { Color(hexCode: "58D68D") }
    
    /// 뜨거운 빨간색 (#FF5733)
    static var haruWeatherHot: Color { Color(hexCode: "FF5733") }
    
    /// 차가운 파란색 (#3498DB)
    static var haruWeatherCold: Color { Color(hexCode: "3498DB") }
    
    /// 바람 색상 (#AED6F1)
    static var haruWeatherWind: Color { Color(hexCode: "AED6F1") }
}
