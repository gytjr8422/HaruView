//
//  HolidayCalendarInfo.swift
//  HaruView
//
//  Created by 김효석 on 8/5/25.
//

import Foundation
import CoreGraphics

/// 구독된 공휴일 캘린더 정보
struct HolidayCalendarInfo: Identifiable, Hashable {
    let id: String           // 캘린더 식별자
    let title: String        // 캘린더 제목 (예: "대한민국 공휴일", "Japan Holidays")
    let color: CGColor       // 캘린더 색상
    
    /// 국가 이름 추출 (간단한 버전)
    var countryName: String {
        // 간단한 국가명 추출 로직
        if title.contains("대한민국") || title.contains("Korea") {
            return "대한민국"
        } else if title.contains("Japan") || title.contains("日本") || title.contains("祝日") {
            return "일본"
        } else if title.contains("United States") || title.contains("US Holidays") {
            return "미국"
        } else if title.contains("China") || title.contains("中国") {
            return "중국"
        } else if title.contains("United Kingdom") || title.contains("UK") {
            return "영국"
        } else if title.contains("Germany") || title.contains("Deutschland") {
            return "독일"
        } else if title.contains("France") || title.contains("français") {
            return "프랑스"
        } else {
            // 기본적으로 제목에서 "Holiday", "공휴일" 등을 제거한 부분 반환
            return title.replacingOccurrences(of: " Holiday", with: "")
                       .replacingOccurrences(of: " Holidays", with: "")
                       .replacingOccurrences(of: "공휴일", with: "")
                       .replacingOccurrences(of: "祝日", with: "")
                       .trimmingCharacters(in: .whitespaces)
        }
    }
    
    /// 국기 이모지 (간단한 버전)
    var flagEmoji: String {
        if title.contains("대한민국") || title.contains("Korea") {
            return "🇰🇷"
        } else if title.contains("Japan") || title.contains("日本") || title.contains("祝日") {
            return "🇯🇵"
        } else if title.contains("United States") || title.contains("US Holidays") {
            return "🇺🇸"
        } else if title.contains("China") || title.contains("中国") {
            return "🇨🇳"
        } else if title.contains("United Kingdom") || title.contains("UK") {
            return "🇬🇧"
        } else if title.contains("Germany") || title.contains("Deutschland") {
            return "🇩🇪"
        } else if title.contains("France") || title.contains("français") {
            return "🇫🇷"
        } else {
            return "🏳️"  // 기본 깃발
        }
    }
}