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
                                Image(systemName: snapshot.symbolName)
                                    .font(.system(size: 36, weight: .light))
                                Text(snapshot.condition.localizedDescription)
                                    .font(.pretendardBold(size: 18))
                            }
                            Spacer()
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(snapshot.temperature, specifier: "%.0f")°")
                            .font(.system(size: 36, weight: .semibold))
                        Text("최고: \(snapshot.tempMax, specifier: "%.0f")°  최저: \(snapshot.tempMin, specifier: "%.0f")°")
                            .font(.pretendardRegular(size: 13))
                        HStack {
                            Text("습도: \(snapshot.humidity*100 , specifier: "%.0f")%")
                                .font(.pretendardRegular(size: 13))
                            Text("바람: \(snapshot.windSpeed, specifier: "%.0f")m/s")
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
                                    .font(.caption2)
                                Image(systemName: h.symbol)
                                    .resizable() // 크기 조절을 위해 필요
                                    .scaledToFit() // 비율 유지
                                    .frame(height: 15)
                                Text("\(h.temperature, specifier: "%.0f")°")
                                    .font(.caption2)
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
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "a h시"           // “오후 3시”
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
