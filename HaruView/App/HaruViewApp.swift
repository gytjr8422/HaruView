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
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    private func scheduleDailyReminder() async {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        guard granted == true else { return }
        center.removePendingNotificationRequests(withIdentifiers: ["daily_open"])
        
        var date = DateComponents()
        date.hour = 8
        date.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "하루뷰"
        content.body = "카드를 잠금 해제하려면 앱을 열어보세요!"
        
        let req = UNNotificationRequest(identifier: "daily_open", content: content, trigger: trigger)
        do {
            try await center.add(req)
        } catch {
            print("Failed to schedule daily reminder: \(error)")
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        if url.scheme == "haruview", url.host == "add" {
            showAdd = true
        }
    }
}


import GoogleMobileAds

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        MobileAds.shared.start(completionHandler: nil)
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["4ECABE1C-80B0-4475-B992-651D240F36ED"]
        return true
    }
     
}
