//
//  LocationProvider.swift
//  HaruView
//
//  Created by 김효석 on 5/22/25.
//

import CoreLocation
import Foundation

@MainActor
final class LocationProvider: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {

    // MARK: – Singleton
    static let shared = LocationProvider()
    private override init() { super.init() }

    // MARK: – Public Published
    @Published private(set) var status: CLAuthorizationStatus = .notDetermined
    @Published private(set) var lastLocation: CLLocation?
    @Published private(set) var lastUpdateTime: Date?

    // MARK: – Private
    private let manager: CLLocationManager = {
        let m = CLLocationManager()
        m.desiredAccuracy = kCLLocationAccuracyHundredMeters   // 배터리 절약
        m.distanceFilter  = 500                                // 500m 이동 시만
        return m
    }()
    private var cont: CheckedContinuation<CLLocation, Error>?
    
    // 위치 정보 갱신 간격 (30분)
    private let locationUpdateInterval: TimeInterval = 30 * 60

    // MARK: – Public API
    /// async-await 로 단일 좌표 획득. 권한 거부·취소 시 Error throw
    func current() async throws -> CLLocation {
        // 캐시된 위치가 있고, 마지막 업데이트로부터 30분이 지나지 않았다면 캐시된 위치 반환
        if let loc = lastLocation,
           let lastUpdate = lastUpdateTime,
           Date().timeIntervalSince(lastUpdate) < locationUpdateInterval {
            return loc
        }

        return try await withCheckedThrowingContinuation { c in
            cont = c
            manager.delegate = self

            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                c.resume(throwing: LocationError.denied)
            @unknown default:
                c.resume(throwing: LocationError.denied)
            }
        }
    }

    // MARK: – CLLocationManagerDelegate
    func locationManager(_ m: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        self.status = status

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            m.requestLocation()

        case .denied, .restricted:
            if let c = cont {
                cont = nil
                c.resume(throwing: LocationError.denied)
            }

        default:
            break
        }
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.last else { return }
        lastLocation = loc
        lastUpdateTime = Date()
        if let c = cont {
            cont = nil
            c.resume(returning: loc)
        }
    }

    func locationManager(_ m: CLLocationManager, didFailWithError e: Error) {
        if let c = cont {
            cont = nil
            c.resume(throwing: e)
        }
    }

    enum LocationError: LocalizedError {
        case denied
        
        var errorDescription: String? {
            switch self {
            case .denied:
                return "위치 정보 접근이 거부되었습니다. 날씨 정보를 가져오기 위해 설정에서 위치 권한을 허용해주세요."
            }
        }
    }
}
