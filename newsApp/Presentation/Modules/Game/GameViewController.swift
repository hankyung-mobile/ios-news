//
//  GameViewController.swift
//  newsApp
//
//  Created by jay on 8/1/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import WebKit

class GameViewController: UIViewController {
    
    // MARK: - Properties
    private var webView: WKWebView!
    
    // 여기서 URL 직접 설정
    private let urlString = "https://stg-webview.hankyung.com/game" // 원하는 URL로 변경
    
    private var isFirstLoad = true
    
    // MARK: - Initializer
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadURL()
        
        // 로그인 성공 알림 구독
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLoginSuccess),
            name: .loginSuccess,
            object: nil
        )
        
        // 로그아웃 성공 알림 구독
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLogoutSuccess),
            name: .logoutSuccess,
            object: nil
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !isFirstLoad {
            callScriptWhenViewClosed(tokensArray: getUserTokensArray())
        }
        
        isFirstLoad = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupWebView() {
        // WKWebView 설정
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // Auto Layout 설정
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        // 제약 조건 설정 (탭바를 고려한 safe area 사용)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func loadURL() {
        var customUrl: String = ""
        if currentServer == .DEV {
            customUrl = "stg-"
        }
        guard let url = URL(string: "https://\(customUrl)webview.hankyung.com/game") else {
            showAlert(message: "올바르지 않은 URL입니다.")
            return
        }
        
        var request = URLRequest(url: url)
        
        let parameter = returnAccountParameter()
        
        for (key, value) in parameter {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        webView.load(request)
    }
    
    // MARK: - Helper Methods
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func handleLoginSuccess() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.callScriptWhenViewClosed(tokensArray: getUserTokensArray())
        }
    }

    @objc private func handleLogoutSuccess() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.callScriptWhenViewClosed(tokensArray: getUserTokensArray())
        }
    }
    
    private func callScriptWhenViewClosed(tokensArray: [String]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: tokensArray, options: [])
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let script = "window.onGetMobileInfo(\(jsonString))"
                print("실행될 JavaScript 스크립트:\n\(script)")
                
                self.webView.evaluateJavaScript(script) { result, error in
                    if let error = error {
                        print("JavaScript 호출 오류: \(error.localizedDescription)")
                    } else {
                        print("JavaScript 함수 호출 성공, 결과: \(result ?? "없음")")
                    }
                }
            }
        } catch {
            print("JSON 직렬화 오류: \(error.localizedDescription)")
        }
    }
}

// MARK: - WKNavigationDelegate
extension GameViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // 로딩 시작
        print("웹뷰 로딩 시작")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // 로딩 완료
        print("웹뷰 로딩 완료")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // 로딩 실패
        print("웹뷰 로딩 실패: \(error.localizedDescription)")
        showAlert(message: "페이지를 불러올 수 없습니다.")
    }
}

// MARK: - WKUIDelegate
extension GameViewController: WKUIDelegate {
    
    // alert 처리
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completionHandler()
        })
        present(alert, animated: true)
    }
    
    // confirm 처리
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completionHandler(true)
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
            completionHandler(false)
        })
        present(alert, animated: true)
    }
}
