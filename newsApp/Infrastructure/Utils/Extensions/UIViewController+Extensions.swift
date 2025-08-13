//
//  UIViewController+Extensions.swift
//  newsApp
//
//  Created by jay on 5/27/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit

extension UIViewController {
    
    /// 네비게이션 컨트롤러 유무에 따라 자동으로 push 또는 present 수행
    /// - Parameters:
    ///   - viewController: 전환할 뷰컨트롤러
    ///   - animated: 애니메이션 여부 (기본값: true)
    ///   - completion: present 완료 후 실행할 클로저 (push일 때는 실행되지 않음)
    func navigateTo(_ viewController: UIViewController,
                   animated: Bool = true,
                   completion: (() -> Void)? = nil) {
        
        if let navigationController = self.navigationController {
            // NavigationController가 있으면 push
            navigationController.pushViewController(viewController, animated: animated)
            completion?() // push는 completion이 없으므로 바로 실행
        } else {
            // NavigationController가 없으면 present (fullScreen으로)
            self.presentFullScreenForced(viewController, animated: animated, completion: completion)
        }
    }
    
    /// 강제로 present로 화면 전환 (fullScreen)
    /// - Parameters:
    ///   - viewController: 전환할 뷰컨트롤러
    ///   - animated: 애니메이션 여부 (기본값: true)
    ///   - completion: present 완료 후 실행할 클로저
    func presentFullScreen(_ viewController: UIViewController,
                          animated: Bool = true,
                          completion: (() -> Void)? = nil) {
        self.presentFullScreenForced(viewController, animated: animated, completion: completion)
    }
    
    /// 내부에서 사용하는 강제 fullScreen present
    private func presentFullScreenForced(_ viewController: UIViewController,
                                       animated: Bool = true,
                                       completion: (() -> Void)? = nil) {
        
        // 1. 먼저 viewController가 NavigationController에 포함되어 있다면 그것을 present
        let targetViewController: UIViewController
        if viewController.navigationController == nil {
            // NavigationController가 없으면 새로 만들어서 감싸기
            let navController = UINavigationController(rootViewController: viewController)
            navController.modalPresentationStyle = .fullScreen
            navController.modalTransitionStyle = .coverVertical
            targetViewController = navController
        } else {
            // 이미 NavigationController에 포함되어 있으면 그대로 사용
            viewController.modalPresentationStyle = .fullScreen
            viewController.modalTransitionStyle = .coverVertical
            targetViewController = viewController
        }
        
        // 2. 현재 뷰컨트롤러에서 바로 present (최상위 찾지 않음)
        self.present(targetViewController, animated: animated, completion: completion)
    }
    
    /// 강제로 push로 화면 전환 (NavigationController 필수)
    /// - Parameters:
    ///   - viewController: 전환할 뷰컨트롤러
    ///   - animated: 애니메이션 여부 (기본값: true)
    /// - Returns: push 성공 여부
    @discardableResult
    func safePush(_ viewController: UIViewController, animated: Bool = true) -> Bool {
        guard let navigationController = self.navigationController else {
            print("⚠️ NavigationController가 없어서 push할 수 없습니다.")
            return false
        }
        navigationController.pushViewController(viewController, animated: animated)
        return true
    }
    
    /// 현재 뷰컨트롤러가 NavigationController 내부에 있는지 확인
    var hasNavigationController: Bool {
        return navigationController != nil
    }
    
    /// 현재 뷰컨트롤러가 Modal로 present된 상태인지 확인
    var isModal: Bool {
        if let navigationController = self.navigationController {
            return navigationController.presentingViewController != nil
        }
        return self.presentingViewController != nil
    }
}

// MARK: - 사용 예시 및 편의 메서드들
extension UIViewController {
    
    /// 뒤로 가기 (pop 또는 dismiss 자동 선택)
    /// - Parameter animated: 애니메이션 여부 (기본값: true)
    func goBack(animated: Bool = true) {
        if let navigationController = self.navigationController,
           navigationController.viewControllers.count > 1 {
            // NavigationController에서 pop
            navigationController.popViewController(animated: animated)
        } else if self.presentingViewController != nil {
            // Modal로 present된 경우 dismiss
            self.dismiss(animated: animated)
        } else {
            print("⚠️ 뒤로 갈 수 없습니다.")
        }
    }
    
    /// Root로 이동 (popToRoot 또는 dismiss to root)
    /// - Parameter animated: 애니메이션 여부 (기본값: true)
    func goToRoot(animated: Bool = true) {
        if let navigationController = self.navigationController {
            navigationController.popToRootViewController(animated: animated)
        } else {
            // 최상위 presentedViewController까지 dismiss
            var topViewController = self
            while let presentingVC = topViewController.presentingViewController {
                topViewController = presentingVC
            }
            topViewController.dismiss(animated: animated)
        }
    }
    
    /// 최상위 presented 뷰컨트롤러 찾기 (성능 개선)
    private func getTopPresentedViewController() -> UIViewController {
        var current = self
        var depth = 0
        let maxDepth = 10 // 무한루프 방지
        
        while let presented = current.presentedViewController, depth < maxDepth {
            current = presented
            depth += 1
        }
        
        return current
    }
}
