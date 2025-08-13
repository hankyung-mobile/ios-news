//
//  TabBarController.swift
//  newsApp
//
//  Created by hkcom on 2020/07/29.
//  Copyright © 2020 hkcom. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAnalytics
import WebKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    
    //    var tapCounter: Int = 0
    
    override func loadView() {
        super.loadView()
        tabBarViewController = self
        setupTabs()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        setupTabBarAppearance()
        
        //        self.tabBar.showBadgOn(index: 2)
    }
    
    private func setupTabs() {
        // 1. 안전하게 ViewController 로드
        guard let homeVC = loadViewController(storyboard: "News", identifier: "NewsContentController") as? NewsContentController,
              let premiumVC = loadViewController(storyboard: "Premium", identifier: "PremiumViewController") as? PremiumViewController,
              let marketVC = loadViewController(storyboard: "Market", identifier: "MarketViewController") as? MarketViewController,
              let aiSearchVC = loadViewController(storyboard: "AiSearch", identifier: "AIViewController") as? AIViewController,
              let gameVC = loadViewController(storyboard: "Game", identifier: "GameViewController") as? GameViewController,
//              let stockVC = loadViewController(storyboard: "Stock", identifier: "StockViewController") as? StockViewController,
//              let notificationVC = loadViewController(storyboard: "Notification", identifier: "NotificationViewController") as? NotificationViewController,
              let settingsVC = loadViewController(storyboard: "Settings", identifier: "SettingsViewController") as? SettingsViewController
        else {
            
            print("❌ Failed to load view controllers from storyboards")
            return
        }
        
        // 2. NavigationController로 감싸기
        let homeNav = UINavigationController(rootViewController: homeVC)
        let premiumNav = UINavigationController(rootViewController: premiumVC)
        let aiSearchNav = UINavigationController(rootViewController: aiSearchVC)
        let gameNav = UINavigationController(rootViewController: gameVC)
        let marketNav = UINavigationController(rootViewController: marketVC)
//        let notificationNav = UINavigationController(rootViewController: notificationVC)
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        
        homeNav.setNavigationBarHidden(true, animated: false)
        premiumNav.setNavigationBarHidden(true, animated: false)
        aiSearchNav.setNavigationBarHidden(true, animated: false)
        gameNav.setNavigationBarHidden(true, animated: false)
        marketNav.setNavigationBarHidden(true, animated: false)
        settingsNav.setNavigationBarHidden(true, animated: false)
        
        // 3. 탭바 아이템 설정
        setupTabBarItems(navControllers: [homeNav, aiSearchNav, gameNav, marketNav, settingsNav])
        
        // 4. TabBarController에 추가
        self.viewControllers = [homeNav, aiSearchNav, gameNav, marketNav, settingsNav]
    }
    
    private func loadViewController(storyboard storyboardName: String, identifier: String) -> UIViewController? {
        do {
            let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier: identifier)
            return viewController
        } catch {
            print("❌ Failed to load \(identifier) from \(storyboardName): \(error)")
            return nil
        }
    }
    
    private func setupTabBarItems(navControllers: [UINavigationController]) {
        let tabItems = [
            ("뉴스", "newsLine", "newsFill"),
            ("AI", "starLine", "starFill"),
            ("게임", "gameLine", "gameFill"),
            ("마켓", "chartLine", "chartFill"),
            ("개인", "userLine", "userFill")
        ]
        
        for (index, navController) in navControllers.enumerated() {
            guard index < tabItems.count else { continue }
            
            let (title, image, selectedImage) = tabItems[index]
            navController.tabBarItem = UITabBarItem(
                title: title,
                image: UIImage(named: image),
                selectedImage: UIImage(named: selectedImage)
            )
        }
    }
    
    private func setupTabBarAppearance() {
            // iOS 15+ 대응
        let selectedColor = UIColor(named: "#142C67")
        let unSelectedColor = UIColor(named: "#808080") // 한경 비활성화 색상
            if #available(iOS 15.0, *) {
                let appearance = UITabBarAppearance()
                appearance.configureWithDefaultBackground()
                
                // 탭바 배경색
//                appearance.backgroundColor = UIColor.white
                
                
                // 선택되지 않은 아이템 색상
//                appearance.stackedLayoutAppearance.normal.iconColor = unSelectedColor
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                    .foregroundColor: unSelectedColor,
                    .font: UIFont.systemFont(ofSize: 11, weight: .regular)
                ]
                
                // 선택된 아이템 색상 (한경 브랜드 컬러)
                appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                    .foregroundColor: selectedColor,
                    .font: UIFont.systemFont(ofSize: 11, weight: .bold)
                ]
                
                tabBar.standardAppearance = appearance
                tabBar.scrollEdgeAppearance = appearance
            } else {
                // iOS 14 이하 대응
                tabBar.backgroundColor = UIColor.white
                tabBar.tintColor = selectedColor
                tabBar.unselectedItemTintColor = selectedColor
            }
            
            // 탭바 그림자 효과 (선택사항)
//            tabBar.layer.shadowColor = UIColor.black.cgColor
//            tabBar.layer.shadowOpacity = 0.1
//            tabBar.layer.shadowOffset = CGSize(width: 0, height: -2)
//            tabBar.layer.shadowRadius = 4
        }
    
    private func scrollToTopInViewController(_ vc: UIViewController?) {
        guard let vc = vc else { return }
        
        // 직접 ScrollableViewController인지 확인
//        if let scrollable = vc as? ScrollableViewController {
//            scrollable.scrollToTop()
//            return
//        }
//        
//        // 자식들 중에서 찾기
//        for child in vc.children {
//            if let pageVC = child as? UIPageViewController {
//                if let currentPage = pageVC.viewControllers?.first as? ScrollableViewController {
//                    currentPage.scrollToTop()
//                    return
//                }
//            }
//        }
        
        var name: Notification.Name = .moveToNewsPage
        if self.selectedIndex == 1 {
            name = .moveToPremiumPage
        }
        
        if self.selectedIndex == 2 {
            name = .moveToMarketPage
        }
        
        NotificationCenter.default.post(
            name: name,
            object: nil,
            userInfo: ["url": findMainSlideURL() ?? ""]
        )
        
        // 직접 ScrollableViewController인지 확인
        if let scrollable = vc as? ScrollableViewController {
            scrollable.scrollToTop()
            return
        }

        // 자식들 중에서 찾기
        for child in vc.children {
            if let pageVC = child as? UIPageViewController {
                if let currentPage = pageVC.viewControllers?.first as? ScrollableViewController {
                    currentPage.scrollToTop()
                    return
                }
            }
        }
    }
    
    private func findMainSlideURL() -> String? {
        
        switch self.selectedIndex {
        case 0: // 뉴스 탭
            let slides = AppDataManager.shared.getNewsSlideData()
            let mainSlide = slides.first { $0.isMain ?? true }
            
            guard let url = mainSlide?.url, !url.isEmpty else {
                return nil
            }
            
            return url
        case 1: // 프리미엄 탭
            let slides = AppDataManager.shared.getPremiumSlideData()
            let mainSlide = slides.first { $0.isMain ?? true }
            
            guard let url = mainSlide?.url, !url.isEmpty else {
                return nil
            }
            
            return url
        case 2:
            let slides = AppDataManager.shared.getMarketSlideData()
            let mainSlide = slides.first { $0.isMain ?? true }
            
            guard let url = mainSlide?.url, !url.isEmpty else {
                return nil
            }
            
            return url
        default:
            return ""
        }
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        if selectedViewController != viewController {
            
            let gaEventDict: [String: Any] = [
                "hk_click_page": "앱 공통",
                "hk_click_area": "앱 탭바",
                "hk_click_label": ["뉴스","AI","게임","마켓","개인"][selectedIndex]
            ]
            
            Analytics.logEvent("click_event", parameters: gaEventDict)
        }
        
        
        if selectedViewController == viewController && viewController.isKind(of: NewsViewController.classForCoder()) {
            
            newsViewController.webView.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            
            return false
        }
        else if viewController.restorationIdentifier == "pushNavigation" {
            
            self.tabBar.items?[2].badgeValue = nil
            
            UIApplication.shared.applicationIconBadgeNumber = 0
            
            if selectedViewController == viewController, let pnvc = viewController as? UINavigationController, let pvc = pnvc.topViewController as? PushViewController {
                
                guard pvc.tableView.numberOfSections > 0 else {
                    return true
                }
                
                DispatchQueue.main.async {
                    let topRow = IndexPath(row: 0, section: 0)
                    pvc.tableView.scrollToRow(at: topRow, at: .top, animated: true)
                }
            }
        }
        else if viewController.restorationIdentifier == "MarketIndexNavigation" {
            if selectedViewController == viewController, let minvc = viewController as? UINavigationController, let mivc = minvc.topViewController as? MarketIndexViewController {
                
                //                if let mipvc = mivc.children[0] as? MarketIndexPageViewController {
                //                    if let misvc = mipvc.viewControllers?[0] as? StockTableViewController {
                //                        guard misvc.tableView.numberOfSections > 0 else {
                //                            return true
                //                        }
                //                        DispatchQueue.main.async {
                //                            let topRow = IndexPath(row: 0, section: 0)
                //                            misvc.tableView.scrollToRow(at: topRow, at: .top, animated: true)
                //                        }
                //                    }
                //                    else if let mibvc = mipvc.viewControllers?[0] as? BlockchainTableViewController {
                //                        guard mibvc.tableView.numberOfSections > 0 else {
                //                            return true
                //                        }
                //                        DispatchQueue.main.async {
                //                            let topRow = IndexPath(row: 0, section: 0)
                //                            mibvc.tableView.scrollToRow(at: topRow, at: .top, animated: true)
                //                        }
                //                    }
                //                }
                
            }
        }
        
        
        
        if tabBarController.selectedViewController == viewController {
            
            // 네비게이션 컨트롤러라면 루트로 팝
            if let navController = viewController as? UINavigationController {
                if navController.viewControllers.count > 1 {
                    navController.popToRootViewController(animated: true)
                } else {
                    // 이미 루트 상태면 스크롤 상단으로 이동
                    scrollToTopInViewController(navController.topViewController)
                }
            }
        }
        
        return true
    }
}
