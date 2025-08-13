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
                .task {
                    guard !didBootstrap else { return }
                    didBootstrap = true
                    await DIContainer.shared.bootstrapPermissions()
                }
        }
    }
}


import GoogleMobileAds
import AppTrackingTransparency

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // ATT 권한 요청
        DispatchQueue.main.async {
            ATTrackingManager.requestTrackingAuthorization { status in
                // ATT 완료 후 광고 SDK 초기화
                MobileAds.shared.start { _ in
                    _ = AdManager.shared
                }
            }
        }
        return true
    }
     
}
