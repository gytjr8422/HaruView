//
//  GlobalToastView.swift
//  HaruView
//
//  Created by 김효석 on 7/27/25.
//

import SwiftUI

struct GlobalToastView: View {
    @StateObject private var toastManager = ToastManager.shared
    
    var body: some View {
        ZStack {
            if toastManager.isShowing {
                VStack {
                    Text(toastManager.currentToast.message)
                        .font(.pretendardSemiBold(size: 14))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(toastManager.currentToast.backgroundColor)
                        )
                        .padding(.top, 50)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .allowsHitTesting(false) // 터치 이벤트 통과
    }
}

// MARK: - ViewModifier for Easy Integration
struct GlobalToastModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            content
            GlobalToastView()
        }
    }
}

extension View {
    func withGlobalToast() -> some View {
        modifier(GlobalToastModifier())
    }
}