//
//  PagedTabView.swift
//  HaruView
//
//  Created by 김효석 on 7/11/25.
//

import SwiftUI

struct PagedTabView<Content: View>: UIViewControllerRepresentable {
    @Binding var currentIndex: Int
    let views: [Content]
    let onPageSettled: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )

        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator

        if let initialVC = context.coordinator.viewController(for: currentIndex) {
            controller.setViewControllers([initialVC], direction: .forward, animated: false)
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        // 뷰가 변경되었으면 컨트롤러들을 새로 생성
        context.coordinator.updateControllers(with: views)
        
        // 외부에서 currentIndex가 변경되었을 때만 업데이트
        if let currentVC = uiViewController.viewControllers?.first,
           let currentVCIndex = context.coordinator.controllers.firstIndex(of: currentVC),
           currentVCIndex != currentIndex {
            
            if let newVC = context.coordinator.viewController(for: currentIndex) {
                let direction: UIPageViewController.NavigationDirection = currentIndex > currentVCIndex ? .forward : .reverse
                uiViewController.setViewControllers([newVC], direction: direction, animated: true)
            }
        } else if let newVC = context.coordinator.viewController(for: currentIndex) {
            // 같은 인덱스라도 내용이 바뀌었을 수 있으므로 업데이트
            uiViewController.setViewControllers([newVC], direction: .forward, animated: false)
        }
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PagedTabView
        private(set) var controllers: [UIViewController]

        init(parent: PagedTabView) {
            self.parent = parent
            self.controllers = parent.views.map { UIHostingController(rootView: $0) }
        }
        
        // 뷰 컨트롤러들을 업데이트할 수 있는 메서드 추가
        func updateControllers(with views: [Content]) {
            controllers = views.map { UIHostingController(rootView: $0) }
        }

        func viewController(for index: Int) -> UIViewController? {
            guard index >= 0 && index < controllers.count else { return nil }
            return controllers[index]
        }

        func presentationCount(for _: UIPageViewController) -> Int { controllers.count }
        func presentationIndex(for _: UIPageViewController) -> Int { parent.currentIndex }

        func pageViewController(_: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController), index > 0 else { return nil }
            return controllers[index - 1]
        }

        func pageViewController(_: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController), index < controllers.count - 1 else { return nil }
            return controllers[index + 1]
        }

        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating _: Bool, previousViewControllers _: [UIViewController], transitionCompleted completed: Bool) {
            if completed, let visibleVC = pageViewController.viewControllers?.first,
               let newIndex = controllers.firstIndex(of: visibleVC) {
                parent.currentIndex = newIndex
                parent.onPageSettled(newIndex) // 손을 떼고 이동이 확정된 순간 호출
            }
        }
    }
}
