//
//  HaruViewApp.swift
//  HaruView
//
//  Created by 김효석 on 4/30/25.
//

import SwiftUI
import EventKit

@main
struct HaruViewApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var didBootstrap: Bool = false
    @State private var showAdd: Bool = false
    
    private let di = DIContainer.shared
    
    init() {
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.di, .shared)
                .environmentObject(LanguageManager.shared)
                .task {
                    guard !didBootstrap else { return }
                    didBootstrap = true
                    await DIContainer.shared.bootstrapPermissions()
                    
                    // ATT 권한 요청
                    await requestTrackingPermission()
                }
        }
    }
    
    private func requestTrackingPermission() async {
        // 메인 스레드에서 2초 후 실행
        await MainActor.run {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let currentStatus = ATTrackingManager.trackingAuthorizationStatus
                
                if currentStatus != .notDetermined {
                    self.initializeAds()
                    return
                }
                
                ATTrackingManager.requestTrackingAuthorization { status in
                    DispatchQueue.main.async {
                        self.initializeAds()
                    }
                }
            }
        }
    }
    
    
    private func initializeAds() {
        MobileAds.shared.start { _ in
            _ = AdManager.shared
        }
    }
}


import GoogleMobileAds
import AppTrackingTransparency

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
}
