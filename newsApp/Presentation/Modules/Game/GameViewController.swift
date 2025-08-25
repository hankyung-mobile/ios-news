//
//  GameViewController.swift
//  newsApp
//
//  Created by jay on 8/1/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import WebKit
import RxSwift
import RxCocoa

class GameViewController: UIViewController {
    
    // MARK: - Properties
    private var webContentController: WebContentController!
    private let disposeBag = DisposeBag()
    
    // 하드코딩된 URL
    
    private let urlString = "https://stg-webview.hankyung.com/game"
    
    private var hasShownAd: Bool = false
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupWebContentController()
        
        // 메모리 경고 관찰
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !hasShownAd {
            hasShownAd = true
            
            // 약간의 딜레이로 더 자연스럽게
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // AdMobManager.shared.showAd(from: self)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 화면이 나타나기 전에 웹뷰 활성화
        webContentController?.optimizeForForeground()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup Methods
    private func setupWebContentController() {
        var customUrl: String = ""
        if currentServer == .DEV {
            customUrl = "stg-"
        }
        guard let url = URL(string: "https://\(customUrl)webview.hankyung.com/game") else {
            showAlert(message: "올바르지 않은 URL입니다.")
            return
        }
        
        // WebContentController 생성 및 설정
        webContentController = WebContentController(url: url)
        webContentController.webNavigationDelegate = self
        
        // Child View Controller로 추가
        addChild(webContentController)
        view.addSubview(webContentController.view)
        webContentController.didMove(toParent: self)
        
        // Auto Layout 설정 - 전체 화면
        webContentController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webContentController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webContentController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webContentController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webContentController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 즉시 로드 시작
        webContentController.preloadWebView()
    }
    
    // MARK: - Helper Methods
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Memory Management
    @objc private func handleMemoryWarning() {
        NotificationCenter.default.post(name: NSNotification.Name("OptimizeWebViewMemory"), object: nil)
        webContentController?.optimizeForBackground()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        handleMemoryWarning()
    }
}

// MARK: - WebNavigationDelegate
extension GameViewController: WebNavigationDelegate {
    func openNewsDetail(url: URL, title: String?) {
        print("AIViewController: Opening news detail for URL: \(url)")
        
        let newsDetailVC = NewsDetailViewController(url: url, title: title)
        newsDetailVC.webNavigationDelegate = self
        newsDetailVC.hidesBottomBarWhenPushed = false
        
        navigationController?.pushViewController(newsDetailVC, animated: true)
    }
}

// MARK: - 사용 예시
/*
// Storyboard에서 사용하는 경우:
// 1. Storyboard에서 UIViewController를 추가
// 2. Class를 AIViewController로 설정
// 3. IBOutlet 연결 불필요

// 코드로 생성하는 경우:
let aiViewController = AIViewController()
navigationController?.pushViewController(aiViewController, animated: true)
*/
