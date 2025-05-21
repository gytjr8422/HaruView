//
//  WeatherCard.swift
//  HaruView
//
//  Created by 김효석 on 5/21/25.
//

import SwiftUI

struct WeatherCard: View {
    let snapshot: WeatherSnapshot
    
    // 배경색에 따라 적절한 전경색 반환
    private var foregroundColor: Color {
        let isDarkBackground = isDarkBackground(for: snapshot.condition)
        return isDarkBackground ? .white : .black
    }
    
    // 어두운 배경인지 확인하는 함수
    private func isDarkBackground(for condition: WeatherSnapshot.Condition) -> Bool {
        switch condition {
        case .clear, .mostlyClear:
            // 시간에 따라 배경이 다름
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: snapshot.updatedAt)
            let isDay = hour >= 6 && hour < 18
            let isEdge = (hour >= 6 && hour < 7) || (hour >= 17 && hour < 18)
            
            if isEdge {
                return false // 일출/일몰 시간은 밝은 배경
            }
            return !isDay // 밤에는 어두운 배경
            
        case .partlyCloudy, .mostlyCloudy:
            // 시간에 따라 배경이 다름
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: snapshot.updatedAt)
            let isDay = hour >= 6 && hour < 18
            return !isDay // 밤에는 어두운 배경
            
        case .thunderstorms, .hurricane, .tropicalStorm:
            return true // 항상 어두운 배경
            
        case .rain, .drizzle, .showers:
            // 시간에 따라 배경이 다름
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: snapshot.updatedAt)
            let isDay = hour >= 6 && hour < 18
            return !isDay // 밤에는 어두운 배경
            
        default:
            return false // 나머지는 밝은 배경으로 간주
        }
    }

    var body: some View {
        ZStack {
            snapshot.condition.background(for: snapshot.updatedAt)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Image(systemName: snapshot.symbolName)
                        .font(.system(size: 36, weight: .light))
                    Text(snapshot.condition.rawValue)
                        .font(.pretendardBold(size: 18))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(snapshot.temperature, specifier: "%.1f")°C")
                        .font(.system(size: 36, weight: .semibold))
                    HStack(spacing: 12) {
                        Label("\(snapshot.humidity*100, specifier:"%.0f")%", systemImage: "humidity")
                        Label("\(snapshot.windSpeed, specifier:"%.1f")m/s", systemImage: "wind")
                    }
                    .font(.pretendardRegular(size: 13))
                }
            }
            .foregroundStyle(foregroundColor) // 계산된 전경색 적용
            .padding(20)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }
}


#Preview {
    WeatherCard(snapshot: WeatherSnapshot(
        temperature: 23.5,           // 섭씨 23.5도
        humidity: 0.65,              // 65% 습도
        precipitation: 0.0,          // 강수량 0mm
        windSpeed: 3.2,              // 초속 3.2m 바람
        condition: .mostlyClear,     // 대체로 맑음
        symbolName: "sun.max",       // SF Symbol 이름
        updatedAt: Date()            // 현재 시간
    ))
}
