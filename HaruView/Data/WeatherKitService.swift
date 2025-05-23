//
//  WeatherKitService.swift
//  HaruView
//
//  Created by 김효석 on 5/22/25.
//

import WeatherKit
import CoreLocation

final class WeatherKitService {

    private let ws = WeatherService.shared
    private let geocoder = CLGeocoder()
    
    // 최대 재시도 횟수
    private let maxRetries = 3
    // 재시도 간격 (초)
    private let retryInterval: TimeInterval = 2

    fileprivate func snapshot(for location: CLLocation) async throws -> WeatherSnapshot {
        var lastError: Error?
        
        // 최대 3번까지 재시도
        for attempt in 1...maxRetries {
            do {
                let cur = try await ws.weather(for: location, including: .current)
                return WeatherSnapshot(
                    temperature: cur.temperature.converted(to: .celsius).value,
                    humidity: cur.humidity,
                    precipitation: cur.precipitationIntensity.value,
                    windSpeed: cur.wind.speed.converted(to: .metersPerSecond).value,
                    condition: .init(apiName: cur.condition.description),
                    symbolName: cur.symbolName,
                    updatedAt: cur.date)
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(retryInterval * 1_000_000_000))
                }
            }
        }
        
        throw WeatherError.fetchFailed(lastError)
    }

    func snapshotWithPlace(for location: CLLocation) async throws -> (WeatherSnapshot, String) {
        async let snap = snapshot(for: location)
        async let placemark = geocoder.reverseGeocodeLocation(location).first

        let (weather, pm) = try await (snap, placemark)

        // 지역명: 시/구, 동
        let place = [pm?.locality, pm?.subLocality]
            .compactMap { $0 }
            .joined(separator: " ")
        
        return (weather, place)
    }
    
    enum WeatherError: LocalizedError {
        case fetchFailed(Error?)
        
        var errorDescription: String? {
            switch self {
            case .fetchFailed(let error):
                if let error = error {
                    return "날씨 정보를 가져오는데 실패했습니다: \(error.localizedDescription)"
                }
                return "날씨 정보를 가져오는데 실패했습니다."
            }
        }
    }
}
