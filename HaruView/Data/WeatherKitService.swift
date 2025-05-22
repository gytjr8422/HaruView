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

    fileprivate func snapshot(for location: CLLocation) async throws -> WeatherSnapshot {
        let cur = try await ws.weather(for: location, including: .current)
        dump("cur = \(cur)")
        return WeatherSnapshot(
            temperature:  cur.temperature.converted(to: .celsius).value,
            humidity:     cur.humidity,
            precipitation: cur.precipitationIntensity.value,
            windSpeed:    cur.wind.speed.converted(to: .metersPerSecond).value,
            condition:    .init(apiName: cur.condition.description),
            symbolName:   cur.symbolName,
            updatedAt:    cur.date)
    }

    func snapshotWithPlace(for location: CLLocation) async throws -> (WeatherSnapshot,String) {

        async let snap = snapshot(for: location)

        async let placemark = geocoder
            .reverseGeocodeLocation(location)
            .first

        let (weather, pm) = try await (snap, placemark)

        // 지역명: 시/구 · 행정구역
        let place = [pm?.locality, pm?.administrativeArea]
            .compactMap { $0 }
            .joined(separator: " ")
        
        
        return (weather, place)
    }
}
