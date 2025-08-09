//
//  ImprovedSwipeBackModifier.swift
//  HaruView
//
//  Created by Claude on 8/8/25.
//

import SwiftUI

/// 개선된 스와이프 뒤로가기 제스처
/// 부정확한 감지와 타이밍 이슈를 해결한 버전
struct ImprovedSwipeBackModifier: ViewModifier {
    let action: () -> Void
    
    @State private var isDismissing = false
    @State private var startLocation: CGPoint = .zero
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        // 시작 위치 저장 (첫 번째 변경에서만)
                        if startLocation == .zero {
                            startLocation = value.startLocation
                        }
                    }
                    .onEnded { value in
                        defer { 
                            startLocation = .zero 
                        }
                        
                        // 이미 dismiss 중이면 무시
                        guard !isDismissing else { return }
                        
                        // 조건 1: 시작점이 화면 왼쪽 가장자리 30pt 이내
                        guard startLocation.x <= 30 else { return }
                        
                        // 조건 2: 충분한 수평 거리 (최소 120pt)
                        guard value.translation.width > 120 else { return }
                        
                        // 조건 3: 세로 움직임이 수평 움직임의 절반 이하
                        let horizontalDistance = abs(value.translation.width)
                        let verticalDistance = abs(value.translation.height)
                        guard verticalDistance < horizontalDistance * 0.5 else { return }
                        
                        // 조건 4: 드래그 속도 체크 (너무 느리면 무시)
                        let velocity = sqrt(pow(value.velocity.width, 2) + pow(value.velocity.height, 2))
                        guard velocity > 300 else { return } // 최소 속도 300pt/s
                        
                        // 조건 5: 수평 속도가 세로 속도보다 커야 함
                        guard abs(value.velocity.width) > abs(value.velocity.height) else { return }
                        
                        // 모든 조건을 통과하면 dismiss 실행
                        performDismiss()
                    }
            )
    }
    
    private func performDismiss() {
        guard !isDismissing else { return }
        
        isDismissing = true
        
        // 메인 스레드에서 약간의 지연 후 dismiss 실행
        // NavigationStack의 상태가 안정화된 후 실행
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            action()
            
            // dismiss 완료 후 플래그 리셋
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isDismissing = false
            }
        }
    }
}

extension View {
    /// 개선된 스와이프 뒤로가기 제스처를 추가합니다
    /// - Parameter action: 뒤로가기 시 실행할 액션
    func improvedSwipeBack(_ action: @escaping () -> Void) -> some View {
        self.modifier(ImprovedSwipeBackModifier(action: action))
    }
}