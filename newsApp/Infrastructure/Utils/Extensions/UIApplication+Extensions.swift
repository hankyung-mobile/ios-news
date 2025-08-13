//
//  UIApplication+Extensions.swift
//  newsApp
//
//  Created by jay on 6/4/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    
    /// iOS 14.0+에서 안전하게 key window를 가져오는 프로퍼티
    var keyWindowCompat: UIWindow? {
        // iOS 14.0+에서는 Scene 기반
        return connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    /// 활성화된 window 가져오기
    var activeWindow: UIWindow? {
        // 활성화된 Scene의 key window 찾기
        for scene in connectedScenes {
            if let windowScene = scene as? UIWindowScene,
               windowScene.activationState == .foregroundActive {
                if let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                    return keyWindow
                }
                // key window가 없으면 첫 번째 window 반환
                return windowScene.windows.first
            }
        }
        
        // 활성화된 Scene이 없으면 첫 번째 Scene의 첫 번째 window
        if let windowScene = connectedScenes.first as? UIWindowScene {
            return windowScene.windows.first
        }
        
        return nil
    }
    
    /// 최상위 뷰컨트롤러 찾기
    var topViewController: UIViewController? {
        guard let window = activeWindow else { return nil }
        return topViewController(from: window.rootViewController)
    }
    
    private func topViewController(from viewController: UIViewController?) -> UIViewController? {
        guard let viewController = viewController else { return nil }
        
        if let navigationController = viewController as? UINavigationController {
            return topViewController(from: navigationController.visibleViewController)
        }
        
        if let tabBarController = viewController as? UITabBarController {
            return topViewController(from: tabBarController.selectedViewController)
        }
        
        if let presentedViewController = viewController.presentedViewController {
            return topViewController(from: presentedViewController)
        }
        
        return viewController
    }
}
