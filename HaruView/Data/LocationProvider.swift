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
        m.desiredAccuracy = kCLLocationAccuracyHundredMeters
        m.distanceFilter = 500
        return m
    }()
    
    private var cont: CheckedContinuation<CLLocation, Error>?
    private var isWaitingForLocation = false  // 🔧 추가: 상태 추적
    
    // 위치 정보 갱신 간격 (30분)
    private let locationUpdateInterval: TimeInterval = 30 * 60

    // MARK: – Public API
    func current() async throws -> CLLocation {
        // 캐시된 위치 확인
        if let loc = lastLocation,
           let lastUpdate = lastUpdateTime,
           Date().timeIntervalSince(lastUpdate) < locationUpdateInterval {
            return loc
        }

        return try await withCheckedThrowingContinuation { c in
            // 🔧 중복 요청 방지
            guard cont == nil else {
                c.resume(throwing: LocationError.alreadyRequesting)
                return
            }
            
            cont = c
            isWaitingForLocation = true  // 🔧 상태 설정
            manager.delegate = self

            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
                
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
                
            case .denied, .restricted:
                // 🔧 즉시 처리하지 않고 delegate에 맡김
                finishWithError(LocationError.denied)
                
            @unknown default:
                finishWithError(LocationError.denied)
            }
        }
    }

    // MARK: – Private Helpers
    private func finishWithLocation(_ location: CLLocation) {
        guard isWaitingForLocation, let c = cont else { return }
        
        lastLocation = location
        lastUpdateTime = Date()
        
        cont = nil
        isWaitingForLocation = false
        c.resume(returning: location)
    }
    
    private func finishWithError(_ error: Error) {
        guard isWaitingForLocation, let c = cont else { return }
        
        cont = nil
        isWaitingForLocation = false
        c.resume(throwing: error)
    }

    // MARK: – CLLocationManagerDelegate
    func locationManager(_ m: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        self.status = status

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // 🔧 현재 위치 요청 중일 때만 실행
            if isWaitingForLocation {
                m.requestLocation()
            }

        case .denied, .restricted:
            finishWithError(LocationError.denied)

        default:
            break
        }
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.last else { return }
        finishWithLocation(loc)
    }

    func locationManager(_ m: CLLocationManager, didFailWithError e: Error) {
        finishWithError(e)
    }

    enum LocationError: LocalizedError {
        case denied
        case alreadyRequesting  // 🔧 추가
        
        var errorDescription: String? {
            switch self {
            case .denied:
                return "위치 정보 접근이 거부되었습니다. 날씨 정보를 가져오기 위해 설정에서 위치 권한을 허용해주세요."
            case .alreadyRequesting:
                return "이미 위치 정보를 요청 중입니다."
            }
        }
    }
}
