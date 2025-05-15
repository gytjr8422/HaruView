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
    
    @State private var didBootstrap: Bool = false
    @State private var showAdd: Bool = false
    @State private var selectedItem: DetailItem?
    
    private let di = DIContainer.shared
    
    var body: some Scene {
        WindowGroup {
            HomeView(vm: DIContainer.shared.makeHomeVM())
                .environment(\.di, .shared)
                .sheet(isPresented: $showAdd) {
                    AddSheet(vm: di.makeAddSheetVM())
                }
                .sheet(item: $selectedItem) { item in
                    DetailSheet(vm: di.makeDetailVM(for: item))
                }
                .task {
                    guard !didBootstrap else { return }
                    didBootstrap = true
                    await DIContainer.shared.bootstrapPermissions()
                    preloadInterstitalAd()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    // MARK: - Bootstrap
//    @MainActor
//    private func bootstrapOnce() async {
//        guard !didBootstrap else { return }
//        didBootstrap = true
//        
//        _ = await di.eventKitService.requestAccess(.writeOnly)
//        
//        if EKEventStore.authorizationStatus(for: .event) == .notDetermined {
//            _ = await di.eventKitService.requestAccess(.full)
//        }
//        
//        await scheduleDailyReminder()
//        
//        preloadInterstitalAd()
//    }
    
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
    
    // MARK: - Placeholder for Ad Preload
    private func preloadInterstitalAd() {
        /* TODO: integrate GoogleMobileAds SDK */
    }
}
