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
                                Text(snapshot.condition.localizedDescription)
                                    .font(.pretendardBold(size: 18))
                            }
                            Spacer()
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: NSLocalizedString("%.0f°", comment: ""), snapshot.temperature))
                            .font(.system(size: 36, weight: .semibold))
                        Text(String(format: NSLocalizedString("최고: %.0f°  최저: %.0f°", comment: ""), snapshot.tempMax, snapshot.tempMin))
                            .font(.pretendardRegular(size: 13))
                        HStack {
                            Text(String(format: NSLocalizedString("습도: %.0f%%", comment: ""), snapshot.humidity*100))
                                .font(.pretendardRegular(size: 13))
                            Text(String(format: NSLocalizedString("바람: %.0fm/s", comment: ""), snapshot.windSpeed))
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

    // MARK: - Formatter
    private func hourLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        if Locale.current.language.languageCode?.identifier == "ko" {
            fmt.locale = Locale(identifier: "ko_KR")
            fmt.dateFormat = "a h시"
        } else {
            fmt.locale = Locale(identifier: "en_US")
            fmt.dateFormat = "ha"
        }
        return fmt.string(from: date)
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
