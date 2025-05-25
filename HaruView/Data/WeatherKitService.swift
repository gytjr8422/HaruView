//
//  WeatherKitService.swift
//  HaruView
//
//  Created by 김효석 on 5/22/25.
//

import WeatherKit
import CoreLocation

final class WeatherKitService {

    private let ws        = WeatherService.shared
    private let geocoder  = CLGeocoder()

    // 재시도
    private let maxRetries      = 3
    private let retryInterval   : TimeInterval = 2      // 초

    fileprivate func snapshot(for loc: CLLocation) async throws -> WeatherSnapshot {

        var lastError: Error?

        for attempt in 1...maxRetries {
            do {
                // 동시 요청 → current, hourly, daily
                async let cur  = ws.weather(for: loc, including: .current)
                async let hrly = ws.weather(for: loc, including: .hourly)
                async let daily = ws.weather(for: loc, including: .daily)

                let (current, hourly, dailyForecast) = try await (cur, hrly, daily)
                
                // 6시간 예보
                let now = Date()
                let next6 = hourly.forecast
                    .filter { $0.date > now }  // 현재 시간 이후의 데이터만 필터링
                    .prefix(6)  // 최대 6개
                    .map {
                        HourlyForecast(date: $0.date,
                                      symbol: $0.symbolName,
                                      temperature: $0.temperature.converted(to: .celsius).value)
                    }
                // 최고·최저 (오늘)
                let today = dailyForecast.forecast.first
                let tMax = today?.highTemperature
                    .converted(to: .celsius).value ?? current.temperature.value
                let tMin = today?.lowTemperature
                    .converted(to: .celsius).value ?? current.temperature.value
                
                print(current.condition)

                return WeatherSnapshot(
                    temperature: current.temperature.converted(to: .celsius).value,
                    humidity:    current.humidity,
                    precipitation: current.precipitationIntensity.value,     // mm/h
                    windSpeed:   current.wind.speed
                        .converted(to: .metersPerSecond).value,
                    condition:   .init(apiName: current.condition.description),
                    symbolName:  current.symbolName,
                    updatedAt:   current.date,
                    hourlies:    Array(next6),
                    tempMax:     tMax,
                    tempMin:     tMin
                )
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try await Task.sleep(for: .seconds(retryInterval))
                }
            }
        }
        throw WeatherError.fetchFailed(lastError)
    }

    // MARK: snapshot + 지역명
    func snapshotWithPlace(for loc: CLLocation) async throws -> (WeatherSnapshot,String) {

        async let snap  = snapshot(for: loc)
        async let place = geocoder.reverseGeocodeLocation(loc).first

        let (weather, pm) = try await (snap, place)

        let name = [pm?.locality, pm?.subLocality]      // “도시 구/동”
            .compactMap { $0 }
            .joined(separator: " ")

        return (weather, name.isEmpty ? "알 수 없음" : name)
    }

    // MARK: - Error
    enum WeatherError: LocalizedError {
        case fetchFailed(Error?)
        var errorDescription: String? {
            switch self {
            case .fetchFailed(let e):
                return e == nil ? "날씨 정보를 가져오는데 실패했습니다."
                                : "날씨 정보를 가져오는데 실패했습니다: \(e!.localizedDescription)"
            }
        }
    }
}
