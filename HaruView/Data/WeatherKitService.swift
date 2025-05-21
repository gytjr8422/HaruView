//
//  WeatherKitService.swift
//  HaruView
//
//  Created by 김효석 on 5/22/25.
//

import Foundation
import WeatherKit
import CoreLocation

final class WeatherKitService {

    private let ws = WeatherService.shared

    func snapshot(for location: CLLocation) async throws -> WeatherSnapshot {

        let current = try await ws.weather(for: location, including: .current)

        return WeatherSnapshot(
            temperature: current.temperature.converted(to: .celsius).value,
            humidity:    current.humidity,
            precipitation: current.precipitationIntensity.value,
            windSpeed:   current.wind.speed.converted(to: .metersPerSecond).value,
            condition:   .init(apiName: current.condition.description),
            symbolName:  current.symbolName,
            updatedAt:   current.date)
    }
}
