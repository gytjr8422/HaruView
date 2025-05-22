//
//  LocationProvider.swift
//  HaruView
//
//  Created by 김효석 on 5/22/25.
//

import CoreLocation
import Foundation

@MainActor
final class LocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: – Singleton
    static let shared = LocationProvider()
    private override init() { super.init() }

    // MARK: – Public Published
    @Published private(set) var status: CLAuthorizationStatus = .notDetermined
    @Published private(set) var lastLocation: CLLocation?

    // MARK: – Private
    private let manager: CLLocationManager = {
        let m = CLLocationManager()
        m.desiredAccuracy = kCLLocationAccuracyHundredMeters   // 배터리 절약
        m.distanceFilter  = 500                                // 500m 이동 시만
        return m
    }()
    private var cont: CheckedContinuation<CLLocation, Error>?

    // MARK: – Public API
    /// async-await 로 단일 좌표 획득. 권한 거부·취소 시 Error throw
    func current() async throws -> CLLocation {
        if let loc = lastLocation { return loc }

        return try await withCheckedThrowingContinuation { c in
            cont = c
            manager.delegate = self

            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()     // ✅ cont는 살아 있지만 아직 resume하지 않음
                // 여기서 return 하지 말고 requestLocation()까지 이어지도록 둔다
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                c.resume(throwing: LocationError.denied)    // 즉시 실패 건네기
            @unknown default:
                c.resume(throwing: LocationError.denied)
            }
        }
    }

    // MARK: – CLLocationManagerDelegate
    nonisolated func locationManager(_ m: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.status = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                m.requestLocation()
            } else if status == .denied || status == .restricted {
                cont?.resume(throwing: LocationError.denied)
                cont = nil
            }
        }
    }

    nonisolated func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        Task { @MainActor in
            guard let loc = locs.last else { return }
            lastLocation = loc
            cont?.resume(returning: loc)
            cont = nil
        }
    }

    nonisolated func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            cont?.resume(throwing: error)
            cont = nil
        }
    }

    enum LocationError: Error { case denied }
}
