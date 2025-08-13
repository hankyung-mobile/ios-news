//
//  TabCoordinator.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import UIKit

// 탭 코디네이터 프로토콜
protocol TabCoordinator: Coordinator {
    var tabBarController: UITabBarController { get }
    func selectTab(_ index: Int)
    func setTabBarVisible(_ visible: Bool, animated: Bool)
}

// 기본 구현
extension TabCoordinator {
    func selectTab(_ index: Int) {
        tabBarController.selectedIndex = index
    }
    
    func setTabBarVisible(_ visible: Bool, animated: Bool) {
        let frame = tabBarController.tabBar.frame
        let height = frame.size.height
        let offsetY = visible ? 0 : height
        
        // 탭바 숨김/표시 애니메이션
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.tabBarController.tabBar.frame.origin.y = UIScreen.main.bounds.height - offsetY
                self.tabBarController.tabBar.alpha = visible ? 1.0 : 0.0
            }
        } else {
            tabBarController.tabBar.frame.origin.y = UIScreen.main.bounds.height - offsetY
            tabBarController.tabBar.alpha = visible ? 1.0 : 0.0
        }
    }
}
