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

    let service: WeatherKitService
    let locationProvider: () async throws -> CLLocation

    /// 서울 시청(37.5665, 126.9780) 좌표
    private let seoul = CLLocation(latitude: 37.5665, longitude: 126.9780)

    func fetchWeather() async -> Result<TodayWeather, TodayBoardError> {
        do {
            let loc           = try await locationProvider()
            let (snap, place) = try await service.snapshotWithPlace(for: loc)
            print("🌤 temp=\(snap.temperature)°C  place=\(place)")
            return .success(.init(snapshot: snap, placeName: place))

        } catch {
            do {
                let (snap, _) = try await service.snapshotWithPlace(for: seoul)
                print("🌤 temp=\(snap.temperature)°C  place=서울이다!!")
                return .success(.init(snapshot: snap, placeName: "서울"))
            } catch {
                print("실패!!!!!!!")
                return .failure(.networkError)
            }
        }
    }
}
