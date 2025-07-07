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
        _ = AdManager.shared
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
        // 1. 광고 SDK 초기화
        MobileAds.shared.start { status in
            // 2. 초기화 완료 후 AdManager 초기화
            _ = AdManager.shared
        }
        
        // 3. ATT 권한 요청
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { status in }
        }
        return true
    }
     
}
