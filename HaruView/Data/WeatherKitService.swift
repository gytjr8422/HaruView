//
//  WeatherKitService.swift
//  HaruView
//
//  Created by 김효석 on 5/22/25.
//

import Foundation
import WeatherKit
import CoreLocation

@MainActor
final class WeatherKitService {
    private let service = WeatherService.shared

    func snapshot(for location: CLLocation) async -> Result<WeatherSnapshot, TodayBoardError> {
        do {
            let current = try await service.weather(for: location, including: .current)
            
            return .success(WeatherSnapshot(
                temperature:     current.temperature.converted(to: .celsius).value,
                humidity:        current.humidity,
                precipitation:   current.precipitationIntensity.converted(to: .metersPerSecond).value,
                windSpeed:       current.wind.speed.converted(to: .metersPerSecond).value,
                condition:       .init(apiName: current.condition.description),
                symbolName:      current.symbolName,
                updatedAt:       current.date))
        } catch {
            return .failure(TodayBoardError.networkError)
        }
    }}
