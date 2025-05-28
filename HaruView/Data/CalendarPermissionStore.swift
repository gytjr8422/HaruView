//
//  CalendarPermissionStore.swift
//  HaruView
//
//  Created by 김효석 on 5/19/25.
//

import SwiftUI
import Combine
import EventKit

@MainActor
final class CalendarPermissionStore: ObservableObject {

    enum AccessState {
        case notDetermined, restricted, denied, granted
    }

    // 퍼블리셔: 뷰가 이 값을 구독하면 자동으로 갱신
    @Published private(set) var eventState: AccessState
    @Published private(set) var reminderState: AccessState

    private let store = EKEventStore()
    private var bag   = Set<AnyCancellable>()
    
    var isAllGranted: Bool {
        eventState == .granted && reminderState == .granted
    }

    init() {
        // 현재 상태로 초기화
        eventState    = Self.map(EKEventStore.authorizationStatus(for: .event))
        reminderState = Self.map(EKEventStore.authorizationStatus(for: .reminder))

        // 1. 사용자가 Alert에 응답하면 시스템이 보내는 알림
        let eventKit = NotificationCenter.default
            .publisher(for: .EKEventStoreChanged)

        // 2. 설정 앱에서 권한을 바꾼 뒤 다시 돌아오는 경우
        let becomeActive = NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)

        // 두 스트림을 하나로 합쳐 상태 리프레시
        eventKit
            .merge(with: becomeActive)
            .sink { [weak self] _ in self?.refreshStatus() }
            .store(in: &bag)
    }

    func requestEvents() async {
        do {
            try await store.requestFullAccessToEvents()
            await MainActor.run { self.refreshStatus() }
        } catch {
            print("Calendar permission request failed: \(error)")
        }
    }

    func requestReminders() async {
        do {
            try await store.requestFullAccessToReminders()
            await MainActor.run { self.refreshStatus() }
        } catch {
            print("Reminder permission request failed: \(error)")
        }
    }

    // MARK: - 내부 헬퍼

    private func refreshStatus() {
        eventState    = Self.map(EKEventStore.authorizationStatus(for: .event))
        reminderState = Self.map(EKEventStore.authorizationStatus(for: .reminder))
    }

    private static func map(_ s: EKAuthorizationStatus) -> AccessState {
        switch s {
        case .authorized, .fullAccess: .granted
        case .denied, .writeOnly:                  .denied
        case .restricted:              .restricted
        case .notDetermined:           .notDetermined
        @unknown default:              .restricted
        }
    }
}
