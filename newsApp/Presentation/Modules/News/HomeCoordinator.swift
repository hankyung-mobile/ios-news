////
////  HomeCoordinator.swift
////  newsApp
////
////  Created by jay on 5/20/25.
////  Copyright © 2025 hkcom. All rights reserved.
////
//
//import Foundation
//import UIKit
//
//class HomeCoordinator: Coordinator {
//    var childCoordinators: [Coordinator] = []
//    var navigationController: UINavigationController
//    
//    private let userService: UserService
//    private let webContentService: WebContentService
//    
//    init(navigationController: UINavigationController,
//         userService: UserService = UserService(),
//         webContentService: WebContentService = WebContentService()) {
//        self.navigationController = navigationController
//        self.userService = userService
//        self.webContentService = webContentService
//    }
//    
//    func start() {
//        let viewModel = HomeViewModel(userService: userService, webContentService: webContentService)
//        let viewController = HomeViewController(viewModel: viewModel)
//        viewController.coordinator = self
//        
//        navigationController.setViewControllers([viewController], animated: false)
//    }
//    
//    // 상세 화면 표시
//    func showDetailView(itemId: String) {
//        let viewModel = DetailViewModel(itemId: itemId, webContentService: webContentService)
//        let viewController = DetailViewController(viewModel: viewModel)
//        viewController.coordinator = self
//        
//        navigationController.pushViewController(viewController, animated: true)
//    }
//    
//    // 공유 시트 표시
//    func showShareSheet(content: String, url: URL? = nil) {
//        guard let topViewController = navigationController.topViewController else { return }
//        
//        var itemsToShare: [Any] = [content]
//        if let url = url {
//            itemsToShare.append(url)
//        }
//        
//        let activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
//        topViewController.present(activityVC, animated: true)
//    }
//    
//    // 다른 탭으로 이동
//    func navigateToTab(_ tabIndex: Int) {
//        NotificationCenter.default.post(
//            name: NSNotification.Name("SwitchToTab"),
//            object: nil,
//            userInfo: ["tabIndex": tabIndex]
//        )
//    }
//}
