//
//  NativeAdView.swift
//  HaruView
//
//  Created by 김효석 on 5/18/25.
//

import GoogleMobileAds
import SwiftUI

struct NativeAdBanner: UIViewRepresentable {
    #if DEBUG
    let unitID = "ca-app-pub-3940256099942544/3986624511"
    #else
    private let unitID = "ca-app-pub-2709183664449693~4583141590"
    #endif

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, NativeAdLoaderDelegate {
        private weak var nativeAdView: NativeAdView?
        private var adLoader: AdLoader?

        func attach(view: NativeAdView, unitID: String) {
            nativeAdView = view
            let rootVC = UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
                .first
            adLoader = AdLoader(adUnitID: unitID,
                                rootViewController: rootVC,
                                adTypes: [.native],
                                options: nil)
            adLoader?.delegate = self
            adLoader?.load(Request())
        }

        func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
            guard let view = nativeAdView else { return }
            (view.headlineView as? UILabel)?.text = nativeAd.headline
            (view.bodyView as? UILabel)?.text = nativeAd.body
            (view.iconView  as? UIImageView)?.image = nativeAd.icon?.image
            view.nativeAd = nativeAd
        }

        func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
            print("Native ad load fail:", error.localizedDescription)
        }
    }

    func makeUIView(context: Context) -> NativeAdView {
        let adView = NativeAdView(frame: .zero)

        let icon = UIImageView()
        icon.layer.cornerRadius = 8; icon.clipsToBounds = true
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 60).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 60).isActive = true

        let headline = UILabel(); headline.font = .boldSystemFont(ofSize: 16); headline.numberOfLines = 2
        let body = UILabel(); body.font = .systemFont(ofSize: 14); body.textColor = .secondaryLabel; body.numberOfLines = 2
        let textStack = UIStackView(arrangedSubviews: [headline, body])
        textStack.axis = .vertical; textStack.spacing = 4

        let hStack = UIStackView(arrangedSubviews: [icon, textStack])
        hStack.alignment = .center; hStack.spacing = 12
        hStack.translatesAutoresizingMaskIntoConstraints = false

        adView.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            hStack.topAnchor.constraint(equalTo: adView.topAnchor),
            hStack.bottomAnchor.constraint(equalTo: adView.bottomAnchor)
        ])

        // 아웃렛 연결
        adView.iconView = icon
        adView.headlineView = headline
        adView.bodyView = body

        // 광고 로드 연결
        context.coordinator.attach(view: adView, unitID: unitID)
        
        return adView
    }

    func updateUIView(_ uiView: NativeAdView, context: Context) { }
}

#if DEBUG
struct NativeAdBanner_Previews: PreviewProvider {
    static var previews: some View {
        NativeAdBanner()
            .frame(height: 120)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif

