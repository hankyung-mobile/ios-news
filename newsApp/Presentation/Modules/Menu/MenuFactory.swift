//
//  MenuFactory.swift
//  newsApp
//
//  Created by jay on 6/30/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import RxSwift
import WebKit

class MenuFactory {
    // 미리 준비된 메뉴들
    private static var preloadedNewsMenu: UINavigationController?
    private static var preloadedPremiumMenu: UINavigationController?
    private static var preloadedMarketMenu: UINavigationController?
    private static let disposeBag = DisposeBag()
    private static var preloadImageViews: [UIImageView] = []
    // 기존 create 메서드들은 그대로...
    static func createNewsMenu(delegate: WebNavigationDelegate? = nil) -> UINavigationController {
        if let preloaded = preloadedNewsMenu {
            preloadedNewsMenu = nil
            
            if let menuVC = preloaded.viewControllers.first as? MenuViewController {
                menuVC.webNavigationDelegate = delegate
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                prepareNewsMenuWithData()
            }
            
            print("⚡ 미리 준비된 NEWS 메뉴 사용")
            return preloaded
        }
        
        print("⏰ NEWS 메뉴 새로 생성")
        return createNewNewsMenu(delegate: delegate)
    }
    
    static func createPremiumMenu(delegate: WebNavigationDelegate? = nil) -> UINavigationController {
     
        return createNewPremiumMenu(delegate: delegate)
    }
    
    static func createMarketMenu(delegate: WebNavigationDelegate? = nil) -> UINavigationController {
   
        return createNewMarketMenu(delegate: delegate)
    }
    
    // 🚀 앱 시작 시 호출할 미리 준비 메서드
    static func preloadMenus() {
        print("🚀 메뉴들 미리 준비 시작...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            prepareNewsMenuWithData()
        }
    }
    
    private static func prepareNewsMenuWithData() {
        let storyboard = UIStoryboard(name: "Menu", bundle: nil)
        let menuVC = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        
        menuVC.menuType = .NEWS
        menuVC.webNavigationDelegate = nil
        
        _ = menuVC.view
        
        print("✅ MenuViewController 직접 생성 성공")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard let newsViewModel = menuVC.getNewsViewModel() else {
                print("❌ newsViewModel이 여전히 nil")
                return
            }
            
            print("🔍 1초 후 newsViewModel 확인 성공")
            
            newsViewModel.cellTypes
                .filter { !$0.isEmpty }
                .take(1)
                .subscribe(onNext: { cellTypes in
                    print("📊 NEWS 데이터 로드 완료, SVG 미리 로드 시작...")
                    
                    self.preloadSVGsFromNewsCellTypes(cellTypes) {
                        let navController = UINavigationController(rootViewController: menuVC)
                        navController.modalPresentationStyle = .pageSheet
                        navController.setNavigationBarHidden(true, animated: false)
                        
                        self.preloadedNewsMenu = navController
                        print("✅ NEWS 메뉴 (데이터+SVG) 미리 준비 완료")
                    }
                })
                .disposed(by: disposeBag)
            
            newsViewModel.viewDidLoad.onNext(())
        }
    }
    
    // 🔥 새로운 SVG 미리 로드 메서드들 추가
    private static func preloadSVGsFromNewsCellTypes(_ cellTypes: [NewsCellType], completion: @escaping () -> Void) {
        var imageUrls: [String] = []
        
        for cellType in cellTypes {
            if case .sectionBGrid(let items) = cellType {
                let urls = items.compactMap { $0.iconUrl }.filter { !$0.isEmpty }
                imageUrls.append(contentsOf: urls)
            }
        }
        
        guard !imageUrls.isEmpty else {
            print("📝 로드할 SVG 없음")
            completion()
            return
        }
        
        print("🖼️ \(imageUrls.count)개 SVG 미리 로드 시작...")
        let group = DispatchGroup()
        
        for url in imageUrls {
            group.enter()
            
            preloadSingleSVG(url: url) {
//                print("✅ SVG 미리 로드 완료: \(url)")
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
//            print("🎉 모든 SVG 미리 로드 완료!")
            completion()
        }
    }
    
    private static func preloadSingleSVG(url: String, completion: @escaping () -> Void) {
        let tempImageView = UIImageView()
        
        // 🔥 배열에 추가해서 강한 참조 유지
        preloadImageViews.append(tempImageView)
        
        tempImageView.loadSVG(url: url, defaultImage: nil, size: CGSize(width: 36, height: 36), animated: true) {
//            print("✅ SVG 미리 로드 완료: \(url)")
            
            // 🔥 로드 완료 후 배열에서 제거
            if let index = preloadImageViews.firstIndex(of: tempImageView) {
                preloadImageViews.remove(at: index)
            }
            
            completion()
        }
    }
    
    // 기존 로직을 별도 메서드로 분리
    private static func createNewNewsMenu(delegate: WebNavigationDelegate?) -> UINavigationController {
        let storyboard = UIStoryboard(name: "Menu", bundle: nil)
        let menuVC = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        
        menuVC.menuType = .NEWS
        menuVC.webNavigationDelegate = delegate
        
        let navController = UINavigationController(rootViewController: menuVC)
        navController.modalPresentationStyle = .pageSheet
        navController.setNavigationBarHidden(true, animated: false)
        
        return navController
    }
    
    private static func createNewPremiumMenu(delegate: WebNavigationDelegate?) -> UINavigationController {
        let storyboard = UIStoryboard(name: "Menu", bundle: nil)
        let menuVC = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        
        menuVC.menuType = .PREMIUM
        menuVC.webNavigationDelegate = delegate
        
        let navController = UINavigationController(rootViewController: menuVC)
        navController.modalPresentationStyle = .pageSheet
        navController.setNavigationBarHidden(true, animated: false)
        
        return navController
    }
    
    private static func createNewMarketMenu(delegate: WebNavigationDelegate?) -> UINavigationController {
        let storyboard = UIStoryboard(name: "Menu", bundle: nil)
        let menuVC = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        
        menuVC.menuType = .MARKET
        menuVC.webNavigationDelegate = delegate
        
        let navController = UINavigationController(rootViewController: menuVC)
        navController.modalPresentationStyle = .pageSheet
        navController.setNavigationBarHidden(true, animated: false)
        
        return navController
    }
}
