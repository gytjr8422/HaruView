//
//  WeatherKitRepository.swift
//  HaruView
//
//  Created by 김효석 on 5/22/25.
//

import Foundation
import CoreLocation
import WeatherKit

struct WeatherKitRepository: WeatherRepositoryProtocol {
   private let service: WeatherKitService
   private let locProvider: () async throws -> CLLocation

   init(service: WeatherKitService = WeatherKitService(),
               locationProvider: @escaping () async throws -> CLLocation) {
       self.service = service
       self.locProvider = locationProvider
   }

   func fetchWeather() async -> Result<WeatherSnapshot, TodayBoardError> {
       do {
           let loc = try await locProvider()
           let snap = try await service.snapshot(for: loc)
           return .success(snap)
       } catch {
           return .failure(.networkError)
       }
   }
}
