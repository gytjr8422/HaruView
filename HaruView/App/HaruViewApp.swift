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
            HomeView(vm: DIContainer.shared.makeHomeVM())
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

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        MobileAds.shared.start(completionHandler: nil)
//        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["4ECABE1C-80B0-4475-B992-651D240F36ED"]
        MobileAds.shared.start(completionHandler: nil)
        return true
    }
     
}
