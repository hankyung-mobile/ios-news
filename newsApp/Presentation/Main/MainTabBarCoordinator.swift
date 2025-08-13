//
//  MainTabBarCoordinator.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import UIKit

class MainTabBarCoordinator: TabCoordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    // 탭바 컨트롤러
    let tabBarController = UITabBarController()
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        // 각 탭별 코디네이터 설정
        setupTabCoordinators()
        
        // 탭바 알림 처리 설정
        setupTabSwitchingNotifications()
    }
    
    private func setupTabCoordinators() {
        // 홈 탭
//        let homeCoordinator = HomeCoordinator(navigationController: UINavigationController())
        
        // 예약 탭
//        let reservationCoordinator = ReservationCoordinator(navigationController: UINavigationController())
//        
//        // 주식 탭
//        let stockCoordinator = StockCoordinator(navigationController: UINavigationController())
//        
//        // 알림 탭
//        let notificationCoordinator = NotificationCoordinator(navigationController: UINavigationController())
//        
//        // 설정 탭
//        let settingsCoordinator = SettingsCoordinator(navigationController: UINavigationController())
        
        // 코디네이터 배열에 추가
//        childCoordinators.append(homeCoordinator)
//        childCoordinators.append(reservationCoordinator)
//        childCoordinators.append(stockCoordinator)
//        childCoordinators.append(notificationCoordinator)
//        childCoordinators.append(settingsCoordinator)
//        
//        // 각 코디네이터 시작
//        homeCoordinator.start()
//        reservationCoordinator.start()
//        stockCoordinator.start()
//        notificationCoordinator.start()
//        settingsCoordinator.start()
//        
//        // 탭바 설정
//        tabBarController.viewControllers = [
//            homeCoordinator.navigationController,
//            reservationCoordinator.navigationController,
//            stockCoordinator.navigationController,
//            notificationCoordinator.navigationController,
//            settingsCoordinator.navigationController
//        ]
//        
//        // 탭바 아이템 설정
//        setupTabBarItems(
//            homeNav: homeCoordinator.navigationController,
//            reservationNav: reservationCoordinator.navigationController,
//            stockNav: stockCoordinator.navigationController,
//            notificationNav: notificationCoordinator.navigationController,
//            settingsNav: settingsCoordinator.navigationController
//        )
    }
    
    private func setupTabBarItems(
        homeNav: UINavigationController,
        reservationNav: UINavigationController,
        stockNav: UINavigationController,
        notificationNav: UINavigationController,
        settingsNav: UINavigationController
    ) {
        homeNav.tabBarItem = UITabBarItem(
            title: "홈",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        
        reservationNav.tabBarItem = UITabBarItem(
            title: "예약",
            image: UIImage(systemName: "calendar"),
            selectedImage: UIImage(systemName: "calendar.fill")
        )
        
        stockNav.tabBarItem = UITabBarItem(
            title: "주식",
            image: UIImage(systemName: "chart.line.uptrend.xyaxis"),
            selectedImage: UIImage(systemName: "chart.line.uptrend.xyaxis.circle.fill")
        )
        
        notificationNav.tabBarItem = UITabBarItem(
            title: "알림",
            image: UIImage(systemName: "bell"),
            selectedImage: UIImage(systemName: "bell.fill")
        )
        
        settingsNav.tabBarItem = UITabBarItem(
            title: "설정",
            image: UIImage(systemName: "gear"),
            selectedImage: UIImage(systemName: "gear.circle.fill")
        )
    }
    
    private func setupTabSwitchingNotifications() {
        // 탭 전환 노티피케이션 리스너 등록
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTabSwitch(_:)),
            name: NSNotification.Name("SwitchToTab"),
            object: nil
        )
    }
    
    @objc private func handleTabSwitch(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let tabIndex = userInfo["tabIndex"] as? Int {
            selectTab(tabIndex)
        }
    }
}
