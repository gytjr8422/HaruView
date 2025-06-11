//
//  AdManager.swift
//  HaruView
//
//  Created by 김효석 on 5/18/25.
//

import Foundation
import GoogleMobileAds

@MainActor
final class AdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = AdManager()
    
    #if DEBUG
    private let unitID = "ca-app-pub-3940256099942544/1033173712" // 테스트 ID
    #else
    private let unitID = "ca-app-pub-2709183664449693/2685953604"
    #endif
    private var interstitial: InterstitialAd?
    private var onDismiss: (() -> Void)?           // 광고 종료 후 실행

    private override init() { super.init(); Task { await loadNext() } }
    
    // MARK: Config (로컬 빈도 캡)
    private struct LocalFrequency {
        static let window: TimeInterval = 10 * 60           // 10 분
        static let maxCount = 1                             // 최대 1 회

        private static let keyTime   = "ad_last_shown"
        private static let keyCount  = "ad_shown_count"

        static var lastShown: Date {
            get { UserDefaults.standard.object(forKey: keyTime) as? Date ?? .distantPast }
            set { UserDefaults.standard.set(newValue, forKey: keyTime) }
        }
        static var count: Int {
            get { UserDefaults.standard.integer(forKey: keyCount) }
            set { UserDefaults.standard.set(newValue, forKey: keyCount) }
        }

        static var canShow: Bool {
            let now = Date()
            if now.timeIntervalSince(lastShown) > window {
                count = 0; lastShown = .distantPast
            }
            return count < maxCount
        }
        static func registerShow() {
            count += 1; lastShown = Date()
        }
    }

    func show(from vc: UIViewController, completion: (() -> Void)? = nil) {
        guard LocalFrequency.canShow else { completion?(); return }
        guard let ad = interstitial else {
            // 광고가 없다면 로드를 시도
            Task { await loadNext() }
            completion?()
            return
        }

        ad.fullScreenContentDelegate = self
        ad.present(from: vc)
        LocalFrequency.registerShow()                 // 로컬 카운트++
        onDismiss = completion
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { await loadNext() }
        onDismiss?(); onDismiss = nil
    }
    
    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        Task { await loadNext() }
        onDismiss?(); onDismiss = nil
    }

    private func loadNext() async {
        do {
            interstitial = try await InterstitialAd.load(with: unitID, request: Request())
        } catch {
            print("Interstitial load fail:", error.localizedDescription)
            // 일정 시간 후 재시도
            try? await Task.sleep(for: .seconds(5))
            await loadNext()
        }
    }
}
