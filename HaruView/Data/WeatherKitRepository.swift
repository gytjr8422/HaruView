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

    /// 서울 시청(37.5665, 126.9780)
    private let seoul = CLLocation(latitude: 37.5665, longitude: 126.9780)

    // MARK: - 10 분 캐시 구조
    private struct Cached: Codable {
        let snapshot: WeatherSnapshot
        let place:    String
        let expires:  Date
    }

    func fetchWeather() async -> Result<TodayWeather, TodayBoardError> {

        // 1) 위치 권한 - 실패 시 서울 좌표
        let loc: CLLocation
        do { loc = try await locationProvider() }
        catch { loc = seoul }

        let key = cacheKey(for: loc)

        // 2) 캐시 먼저
        if let data = UserDefaults.standard.data(forKey: key),
           let cached = try? JSONDecoder().decode(Cached.self, from: data),
           cached.expires > Date() {
            return .success(.init(snapshot: cached.snapshot,
                                  placeName: cached.place))
        }

        do {
            let (snap, place) = try await service.snapshotWithPlace(for: loc)
            saveCache(key: key, snap: snap, place: place)
            return .success(.init(snapshot: snap, placeName: place))

        } catch {
            do {
                let (snap, _) = try await service.snapshotWithPlace(for: seoul)
                saveCache(key: cacheKey(for: seoul), snap: snap, place: "서울")
                return .success(.init(snapshot: snap, placeName: "서울"))
            } catch {
                return .failure(.networkError)
            }
        }
    }

    private func cacheKey(for loc: CLLocation) -> String {
        let lat = Int(loc.coordinate.latitude  * 100)   // 1 km 그리드
        let lon = Int(loc.coordinate.longitude * 100)
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        return "weatherCache_\(lat)_\(lon)_\(lang)"
    }

    private func saveCache(key: String, snap: WeatherSnapshot, place: String) {
        let obj = Cached(snapshot: snap,
                         place: place,
                         expires: Date().addingTimeInterval(600)) // 10 분
        if let data = try? JSONEncoder().encode(obj) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
