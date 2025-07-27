//
//  ToastManager.swift
//  HaruView
//
//  Created by 김효석 on 7/27/25.
//

import SwiftUI
import Combine

enum ToastType {
    case success
    case delete
    case error
    
    var message: String {
        switch self {
        case .success:
            return String(localized: "저장이 완료되었습니다.")
        case .delete:
            return String(localized: "삭제가 완료되었습니다.")
        case .error:
            return String(localized: "오류가 발생했습니다.")
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .success:
            return Color.black.opacity(0.8)
        case .delete:
            return Color.red.opacity(0.8)
        case .error:
            return Color.orange.opacity(0.8)
        }
    }
}

@MainActor
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var isShowing = false
    @Published var currentToast: ToastType = .success
    
    private var hideTask: Task<Void, Never>?
    
    private init() {}
    
    func show(_ type: ToastType, duration: TimeInterval = 2.0) {
        // 기존 타이머 취소
        hideTask?.cancel()
        
        // 토스트 표시
        currentToast = type
        withAnimation(.easeInOut) {
            isShowing = true
        }
        
        // 자동 숨김
        hideTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            
            if !Task.isCancelled {
                withAnimation(.easeInOut) {
                    isShowing = false
                }
            }
        }
    }
    
    func hide() {
        hideTask?.cancel()
        withAnimation(.easeInOut) {
            isShowing = false
        }
    }
}
