//
//  WeatherCard.swift
//  HaruView
//
//  Created by 김효석 on 5/21/25.
//

import SwiftUI

struct WeatherCard: View {
    let snapshot: WeatherSnapshot
    let place: String
    @EnvironmentObject private var languageManager: LanguageManager
    
    private var foreground: Color {
        isDarkBackground ? .white : .black
    }
    private var isDarkBackground: Bool {
        let h = Calendar.current.component(.hour, from: snapshot.updatedAt)
        let isDay  = (6..<18).contains(h)
        let isEdge = (6..<7).contains(h) || (17..<18).contains(h)

        switch snapshot.condition {
        case .clear, .mostlyClear: return !(isDay || isEdge)
        case .partlyCloudy, .mostlyCloudy,
             .rain, .drizzle, .showers:        return !isDay
        case .thunderstorms:                   return true
        default:                               return false
        }
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            snapshot.condition
                .background(for: snapshot.updatedAt)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 16) {

                // 상단 요약
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(place)
                            .font(.pretendardBold(size: 15))
                        VStack {
                            Spacer()
                            HStack(alignment: .center) {
                                Image(systemName: snapshot.condition.symbolName(for: Date()).withFillIfAvailable())
                                    .font(.system(size: 36))
                                    .symbolRenderingMode(snapshot.condition.symbolTheme(for: Date()).renderingMode)
                                    .foregroundStyle(snapshot.condition.symbolTheme(for: Date()).styles[0],
                                                     snapshot.condition.symbolTheme(for: Date()).styles[safe: 1],
                                                     snapshot.condition.symbolTheme(for: Date()).styles[safe: 2])
                                Text(getLocalizedCondition())
                                    .font(.pretendardBold(size: 18))
                            }
                            Spacer()
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: getLocalizedTemperatureFormat(), snapshot.temperature))
                            .font(.system(size: 36, weight: .semibold))
                        Text(String(format: getLocalizedMinMaxFormat(), snapshot.tempMax, snapshot.tempMin))
                            .font(.pretendardRegular(size: 13))
                        HStack {
                            Text(String(format: getLocalizedHumidityFormat(), snapshot.humidity*100))
                                .font(.pretendardRegular(size: 13))
                            Text(String(format: getLocalizedWindFormat(), snapshot.windSpeed))
                                .font(.pretendardRegular(size: 13))
                        }
                        
                    }
                }

                // 6-시간 예보
                if !snapshot.hourlies.isEmpty {
                    HStack {
                        ForEach(snapshot.hourlies) { h in
                            VStack(spacing: 4) {
                                Text(hourLabel(h.date))
                                    .font(.pretendardRegular(size: 11))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false) // 수평만 고정
                                Image(systemName: h.symbol)
                                    .resizable() // 크기 조절을 위해 필요
                                    .scaledToFit() // 비율 유지
                                    .frame(height: 16)
                                Text("\(h.temperature, specifier: "%.0f")°")
                                    .font(.pretendardRegular(size: 11))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .foregroundStyle(foreground)
            .padding(20)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
    }

    // MARK: - Helper Methods
    
    /// 날씨 상태를 현지화된 텍스트로 반환 (언어 변경에 즉시 반응)
    private func getLocalizedCondition() -> String {
        return snapshot.condition.localizedDescription
    }
    
    /// 온도 포맷을 현지화하여 반환
    private func getLocalizedTemperatureFormat() -> String {
        return "%.0f°".localized()
    }
    
    /// 최고/최저 온도 포맷을 현지화하여 반환
    private func getLocalizedMinMaxFormat() -> String {
        return "최고: %.0f°  최저: %.0f°".localized()
    }
    
    /// 습도 포맷을 현지화하여 반환
    private func getLocalizedHumidityFormat() -> String {
        return "습도: %.0f%%".localized()
    }
    
    /// 바람 속도 포맷을 현지화하여 반환
    private func getLocalizedWindFormat() -> String {
        return "바람: %.0fm/s".localized()
    }
    
    /// 시간 라벨을 현지화하여 반환
    private func hourLabel(_ date: Date) -> String {
        let formatter: DateFormatter
        
        switch languageManager.currentLanguage {
        case .korean:
            formatter = DateFormatterFactory.formatter(for: .custom("a h시"), language: .korean)
        case .japanese:
            formatter = DateFormatterFactory.formatter(for: .custom("ah時"), language: .japanese)
        case .english:
            formatter = DateFormatterFactory.formatter(for: .custom("ha"), language: .english)
        }
        
        return formatter.string(from: date)
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
        updatedAt: Date(),           // 현재 시간
        hourlies: [],
        tempMax: 27,
        tempMin: 16
    ), place: " ")
}
