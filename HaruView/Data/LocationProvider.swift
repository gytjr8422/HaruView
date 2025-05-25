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
    
    private var stateTask: Task<CLLocation, Error>?
    private let ttl: TimeInterval = 30 * 60
    private var isWaitingForLocation = false
    
    // 위치 정보 갱신 간격 (30분)
    private let locationUpdateInterval: TimeInterval = 30 * 60

    // MARK: – Public API
    func current() async throws -> CLLocation {
        // 캐시가 유효하면 즉시 반환
        if let loc  = lastLocation,
           let time = lastUpdateTime,
           Date().timeIntervalSince(time) < ttl {
            return loc
        }

        // 이미 진행중 Task가 있으면 재사용
        if let task = stateTask { return try await task.value }

        // 새 Task 생성
        let task = Task { () throws -> CLLocation in
            try await withCheckedThrowingContinuation { cont in
                self.startRequest(cont: cont)
            }
        }
        stateTask = task
        defer { stateTask = nil }
        return try await task.value
    }

    // MARK: – Private Helpers
    private var continuation: CheckedContinuation<CLLocation, Error>?
    private func startRequest(cont: CheckedContinuation<CLLocation, Error>) {
        continuation = cont
        manager.delegate = self

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            cont.resume(throwing: LocationError.denied)
        }
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
            lastLocation    = nil
            lastUpdateTime  = nil
            continuation?.resume(throwing: LocationError.denied)
            continuation = nil

        default:
            break
        }
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.last, let c = continuation else { return }
        lastLocation = loc; lastUpdateTime = Date()
        continuation = nil; c.resume(returning: loc)
    }

    func locationManager(_ m: CLLocationManager, didFailWithError e: Error) {
        continuation?.resume(throwing: e); continuation = nil
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
