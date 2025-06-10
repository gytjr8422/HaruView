//
//  NativeAdView.swift
//  HaruView
//
//  Created by 김효석 on 5/18/25.
//

import GoogleMobileAds
import SwiftUI

struct NativeAdBanner: UIViewRepresentable {

    // MARK: - Public

    /// 광고 높이를 외부(View)로 전달 —  광고가 로드된 뒤 실제 intrinsicHeight 로 갱신됩니다.
    @Binding var height: CGFloat

    #if DEBUG
    private let unitID = "ca-app-pub-3940256099942544/2247696110"         // 테스트
    #else
    private let unitID = "ca-app-pub-2709183664449693/1890138459"
    #endif

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> NativeAdView {
        // 1) 광고 컨테이너
        let adView = NativeAdView()

        // 2) MediaView(필수)
        let media = MediaView()
        media.translatesAutoresizingMaskIntoConstraints = false
        media.heightAnchor.constraint(equalToConstant: 120).isActive = true

        // 3) 아이콘
        let icon = UIImageView()
        icon.layer.cornerRadius = 8
        icon.clipsToBounds = true
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 60).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 60).isActive = true

        // 4) 텍스트
        let headline = UILabel()
        headline.font = .boldSystemFont(ofSize: 16)
        headline.numberOfLines = 2

        let body = UILabel()
        body.font = .systemFont(ofSize: 14)
        body.textColor = .secondaryLabel
        body.numberOfLines = 2

        // 5) 스택 조합
        let textStack = UIStackView(arrangedSubviews: [headline, body])
        textStack.axis = .vertical
        textStack.spacing = 4

        let bottomStack = UIStackView(arrangedSubviews: [icon, textStack])
        bottomStack.alignment = .center
        bottomStack.spacing = 12

        let vStack = UIStackView(arrangedSubviews: [media, bottomStack])
        vStack.axis = .vertical
        vStack.spacing = 8
        vStack.translatesAutoresizingMaskIntoConstraints = false

        adView.addSubview(vStack)
        NSLayoutConstraint.activate([
            vStack.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            vStack.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            vStack.topAnchor.constraint(equalTo: adView.topAnchor),
            vStack.bottomAnchor.constraint(equalTo: adView.bottomAnchor)
        ])

        // 6) 아웃렛 연결
        adView.mediaView    = media
        adView.iconView     = icon
        adView.headlineView = headline
        adView.bodyView     = body

        // 7) 로드
        context.coordinator.attach(view: adView, unitID: unitID)

        return adView
    }

    func updateUIView(_ uiView: NativeAdView, context: Context) { }

    // MARK: - Coordinator

    final class Coordinator: NSObject, NativeAdLoaderDelegate {

        private var banner: NativeAdBanner?
        private weak var adView: NativeAdView?
        private var loader: AdLoader?

        init(_ banner: NativeAdBanner) {
            self.banner = banner
        }

        func attach(view: NativeAdView, unitID: String) {
            adView = view
            let root = UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
                .first

            loader = AdLoader(adUnitID: unitID,
                              rootViewController: root,
                              adTypes: [.native],
                              options: nil)
            loader?.delegate = self
            loader?.load(Request())
        }

        // MARK: NativeAdLoaderDelegate

        func adLoader(_ loader: AdLoader, didReceive nativeAd: NativeAd) {
            guard let v = adView else { return }

            (v.headlineView as? UILabel)?.text = nativeAd.headline
            (v.bodyView     as? UILabel)?.text = nativeAd.body
            (v.iconView     as? UIImageView)?.image = nativeAd.icon?.image
            v.mediaView?.mediaContent = nativeAd.mediaContent
            v.nativeAd = nativeAd

            // intrinsicSize 계산 → SwiftUI에 높이 전달
            DispatchQueue.main.async {
                let size = v.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
                self.banner?._height.wrappedValue = size.height
            }
        }

        func adLoader(_ loader: AdLoader, didFailToReceiveAdWithError error: Error) {
            print("Native ad load fail:", error.localizedDescription)
        }
    }
}

#if DEBUG
struct NativeAdBanner_Previews: PreviewProvider {
    static var previews: some View {
        NativeAdBanner(height: .constant(120))
            .frame(height: 120)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif

