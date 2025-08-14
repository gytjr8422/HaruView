//
//  Color+Widget.swift
//  HaruViewWidget
//
//  Created by Claude on 8/13/25.
//

import SwiftUI

// MARK: - Color Hex Initializer for Widget
extension Color {
    init(hexCode: String) {
        let hex = hexCode.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - ShapeStyle Extension for Widget Colors
extension ShapeStyle where Self == Color {
    
    // MARK: - HaruView Theme Colors (Widget)
    
    /// 메인 브랜드 컬러 (#A76545)
    static var haruPrimary: Color { Color(hexCode: "A76545") }
    
    /// 메인 배경색 (#FFFCF5 - 크림색)
    static var haruBackground: Color { Color(hexCode: "FFFCF5") }
    
    /// 위젯 배경 (메인 배경과 동일)
    static var haruWidgetBackground: Color { haruBackground }
    
    /// 세컨더리 텍스트 및 보더 (#6E5C49)
    static var haruSecondary: Color { Color(hexCode: "6E5C49") }
    
    /// 다크 텍스트 (#40392B)
    static var haruTextPrimary: Color { Color(hexCode: "40392B") }
    
    /// 라이트 브라운 (#C2966B)
    static var haruAccent: Color { Color(hexCode: "C2966B") }
    
    /// 완료된 항목 색상 (메인 컬러와 동일)
    static var haruCompleted: Color { haruPrimary }
    
    /// 카드 보더
    static var haruCardBorder: Color { haruSecondary.opacity(0.2) }
}

// MARK: - Color Extension for Widget
extension Color {
    
    /// 메인 브랜드 컬러 (#A76545)
    static let haruPrimary = Color(hexCode: "A76545")
    
    /// 메인 배경색 (#FFFCF5 - 크림색)
    static let haruBackground = Color(hexCode: "FFFCF5")
    
    /// 위젯 배경 (메인 배경과 동일)
    static let haruWidgetBackground = haruBackground
    
    /// 세컨더리 텍스트 및 보더 (#6E5C49)
    static let haruSecondary = Color(hexCode: "6E5C49")
    
    /// 다크 텍스트 (#40392B)
    static let haruTextPrimary = Color(hexCode: "40392B")
    
    /// 라이트 브라운 (#C2966B)
    static let haruAccent = Color(hexCode: "C2966B")
    
    /// 완료된 항목 색상 (메인 컬러와 동일)
    static let haruCompleted = haruPrimary
    
    /// 카드 보더
    static let haruCardBorder = haruSecondary.opacity(0.2)
}