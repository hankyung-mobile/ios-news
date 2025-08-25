//
//  InternalBrowserViewController.swift
//  newsApp
//
//  Created by jay on 6/12/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import RxSwift

class InternalBrowserViewController: UIViewController, WKUIDelegate {
    private var webView: WKWebView!
    private let url: URL
    private let disposeBag = DisposeBag()
    
    // Safari 스타일 상단 바
    private lazy var safariTopBar: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // 상단 바 구분선
    private lazy var topBarSeparator: UIView = {
        let separator = UIView()
        separator.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }()
    
    // 완료 버튼 (왼쪽)
    private lazy var doneButton: UIButton = {
//        let button = UIButton(type: .system)
//        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .light)
//        let image = UIImage(systemName: "xmark", withConfiguration: config)
//        button.setImage(image, for: .normal)
//        button.tintColor = UIColor(named: "#1A1A1A")
        
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .light)
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // 새로고침 버튼 (오른쪽)
    private lazy var refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "internal_refresh"), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(refreshButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // 하단 툴바
    private lazy var bottomToolbar: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // 하단 툴바 구분선
    private lazy var bottomSeparator: UIView = {
        let separator = UIView()
        separator.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }()
    
    // 하단 버튼들 (3개만)
    private lazy var bottomButtonsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "internal_back"), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var forwardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "internal_forward"), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(forwardButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var bottomShareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "internal_refresh"), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // 진행률 바
    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .systemBlue
        progress.trackTintColor = .clear
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.alpha = 0
        return progress
    }()
    
    private var lastProcessedURL: String?
    private var lastProcessedTime: TimeInterval = 0
    
    private var lastHeaderURL: String?
    private var lastHeaderTime: TimeInterval = 0

    
    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 네비게이션 바 숨김
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 웹뷰 설정
        let webConfiguration = WKWebViewConfiguration()
        let userAgent = webConfiguration.applicationNameForUserAgent ?? "Mobile/15E148"
          webConfiguration.applicationNameForUserAgent = " Version/14.0.1 \(userAgent) Safari/604.1 appos/iOS appinfo/HKAPP_I appversion/\(appVersion) appdevice/\(deviceType)"
        
        webConfiguration.processPool = WebViewProcessPool.shared.pool
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        webConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = false
        let contentController = WKUserContentController()
        
        webConfiguration.userContentController = contentController
        
        // 뷰 계층 구조 설정
        view.addSubview(safariTopBar)
        view.addSubview(topBarSeparator)
        view.addSubview(progressView)
        view.addSubview(webView)
        view.addSubview(bottomSeparator)
        view.addSubview(bottomToolbar)
        
        // 상단 바 구성
        safariTopBar.addSubview(doneButton)
  
        
        
        // 하단 툴바 구성 (3개 버튼만)
//        bottomToolbar.addSubview(bottomButtonsStack)
        
        bottomToolbar.addSubview(backButton)
        bottomToolbar.addSubview(forwardButton)
        bottomToolbar.addSubview(refreshButton)
        
        // 당겨서 새로고침
//        webView.scrollView.refreshControl = UIRefreshControl()
//        webView.scrollView.refreshControl?.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        
        webView.scrollView.bounces = false
        
        setupConstraints()
        updateButtonStates()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 상단 바
            safariTopBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            safariTopBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            safariTopBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            safariTopBar.heightAnchor.constraint(equalToConstant: 44),
            
            // 상단 구분선
            topBarSeparator.topAnchor.constraint(equalTo: safariTopBar.bottomAnchor),
            topBarSeparator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBarSeparator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBarSeparator.heightAnchor.constraint(equalToConstant: 0.5),
            
            // 진행률 바
            progressView.topAnchor.constraint(equalTo: topBarSeparator.bottomAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),
            
            // 웹뷰
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomSeparator.topAnchor),
            
            // 하단 구분선
            bottomSeparator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSeparator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSeparator.bottomAnchor.constraint(equalTo: bottomToolbar.topAnchor),
            bottomSeparator.heightAnchor.constraint(equalToConstant: 0.5),
            
            // 하단 툴바
            bottomToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomToolbar.heightAnchor.constraint(equalToConstant: 44),
            
            // 상단 바 내부 요소들
            doneButton.leadingAnchor.constraint(equalTo: safariTopBar.leadingAnchor, constant: 20),
            doneButton.centerYAnchor.constraint(equalTo: safariTopBar.centerYAnchor),
            doneButton.widthAnchor.constraint(equalToConstant: 24),
            
            // 🔧 하단 버튼들 constraint로 직접 배치 (균등 분할)
            // 백 버튼 - 왼쪽
            backButton.leadingAnchor.constraint(equalTo: bottomToolbar.leadingAnchor, constant: 10),
            backButton.topAnchor.constraint(equalTo: bottomToolbar.topAnchor, constant: 5), // 상단에 딱 붙임
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            // 포워드 버튼
            forwardButton.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 16),
            forwardButton.topAnchor.constraint(equalTo: bottomToolbar.topAnchor, constant: 5), // 상단에 딱 붙임
            forwardButton.widthAnchor.constraint(equalToConstant: 44),
            forwardButton.heightAnchor.constraint(equalToConstant: 44),

            // 새로고침 버튼
            refreshButton.trailingAnchor.constraint(equalTo: bottomToolbar.trailingAnchor, constant: -10),
            refreshButton.topAnchor.constraint(equalTo: bottomToolbar.topAnchor, constant: 5), // 상단에 딱 붙임
            refreshButton.widthAnchor.constraint(equalToConstant: 44),
            refreshButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }
    
    private func setupWebView() {
        // 진행률 관찰
        webView.rx.observe(Double.self, "estimatedProgress")
            .subscribe(onNext: { [weak self] progress in
                guard let self = self, let progress = progress else { return }
                
                DispatchQueue.main.async {
                    if progress < 1.0 {
                        if self.progressView.alpha == 0 {
                            UIView.animate(withDuration: 0.2) {
                                self.progressView.alpha = 1.0
                            }
                        }
                        self.progressView.setProgress(Float(progress), animated: true)
                    } else {
                        UIView.animate(withDuration: 0.2, delay: 0.1, options: []) {
                            self.progressView.alpha = 0
                        } completion: { _ in
                            self.progressView.setProgress(0, animated: false)
                        }
                    }
                }
            })
            .disposed(by: disposeBag)
        
        // 네비게이션 상태 관찰
        webView.rx.observe(Bool.self, "canGoBack")
            .subscribe(onNext: { [weak self] _ in
                self?.updateButtonStates()
            })
            .disposed(by: disposeBag)
        
        webView.rx.observe(Bool.self, "canGoForward")
            .subscribe(onNext: { [weak self] _ in
                self?.updateButtonStates()
            })
            .disposed(by: disposeBag)
    }
    
    private func loadURL() {
        
        var request = URLRequest(url: url)
        
        let parameter = returnAccountParameter()
        
//        let paramString = (parameter.compactMap({ (key, value) -> String in return "\(key)=\(value)" }) as Array).joined(separator: "&")
        for (key, value) in parameter {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
//        request.httpBody = paramString.data(using: .utf8)
        
        webView.load(request)
    }
    
    
    private func updateButtonStates() {
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
        
        backButton.tintColor = webView.canGoBack ? .label : .systemGray3
        forwardButton.tintColor = webView.canGoForward ? .label : .systemGray3
    }
    
    // MARK: - Actions
    @objc private func doneButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func backButtonTapped() {
        webView.goBack()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
//            self?.addHeadersToCurrentPage()
        }
        
        if webView.canGoBack {
            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
//                if let newURL = self?.webView.url {
//                    var request = URLRequest(url: newURL)
//                    
//                    let parameter = returnAccountParameter()
//                    for (key, value) in parameter {
//                        request.setValue(value, forHTTPHeaderField: key)
//                    }
//                    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//                    request.httpMethod = "POST"
//                    
//                    self?.webView.load(request)
//                }
//            }
        }
    }
    
    @objc private func forwardButtonTapped() {
        webView.goForward()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
//            self?.addHeadersToCurrentPage()
        }
        
        if webView.canGoForward {
            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
//                if let newURL = self?.webView.url {
//                    var request = URLRequest(url: newURL)
//                    
//                    let parameter = returnAccountParameter()
//                    for (key, value) in parameter {
//                        request.setValue(value, forHTTPHeaderField: key)
//                    }
//                    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//                    request.httpMethod = "POST"
//                    
//                    self?.webView.load(request)
//                }
//            }
        }
    }
    
    @objc private func refreshButtonTapped() {
        self.loadURL()
    }
    
//    @objc private func pullToRefresh() {
//        webView.reload()
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            self.webView.scrollView.refreshControl?.endRefreshing()
//        }
//    }
    
    private func addHeadersToCurrentPage(urlString: String?) {
        
        guard let url = urlString, !url.isEmpty,
              let validURL = URL(string: url) else {
            print("유효하지 않은 URL: \(urlString ?? "nil")")
            return
        }
        
        var request = URLRequest(url: validURL)
        let parameter = returnAccountParameter()
        
        for (key, value) in parameter {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        print("헤더 추가하여 페이지 리로드: \(validURL)")
        webView.load(request)
        
    }
    
    @objc private func shareButtonTapped() {
        guard let currentURL = webView.url else { return }
        
        let activityViewController = UIActivityViewController(
            activityItems: [currentURL],
            applicationActivities: nil
        )
        
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = bottomShareButton
            popover.sourceRect = bottomShareButton.bounds
        }
        
        present(activityViewController, animated: true)
    }
    
    private func showToastMessage(_ message: String) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 8
        toastLabel.clipsToBounds = true
        
        view.addSubview(toastLabel)
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            toastLabel.widthAnchor.constraint(equalToConstant: 180),
            toastLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.3, animations: {
            toastLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.0, animations: {
                toastLabel.alpha = 0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
    
    @objc private func handleLoginSuccess() {
        print("🔥 \(type(of: self)) - 로그인 성공, 웹뷰 리로드")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            //            self?.webView?.reload()
            if self?.url.absoluteString.contains("comment-test.hankyung.com") ?? false || self?.url.absoluteString.contains("comment.hankyung.com") ?? false {
                self?.loadURL()
                return
            }
            self?.callScriptWhenViewClosed(tokensArray: getUserTokensArray())
        }
    }

    @objc private func handleLogoutSuccess() {
        print("🔥 \(type(of: self)) - 로그아웃 성공, 웹뷰 리로드")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
//            self?.webView?.reload()
//            self?.loadURL()
            self?.callScriptWhenViewClosed(tokensArray: getUserTokensArray())
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "로딩 오류",
            message: "페이지를 로드할 수 없습니다.\n\(error.localizedDescription)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "다시 시도", style: .default) { _ in
            self.loadURL()
        })
        
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
        
        present(alert, animated: true)
    }
    
    deinit {
        print("InternalBrowserViewController deinit")
        webView?.stopLoading()
        webView?.navigationDelegate = nil
    }
}

// MARK: - WKNavigationDelegate
extension InternalBrowserViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // 진행률 바가 처리
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        
//        guard let currentURL = webView.url?.absoluteString else { return }
//        let currentTime = Date().timeIntervalSince1970
//        
//        // 중복 방지: 같은 URL에 1초 내 헤더 추가했으면 무시
//        if lastHeaderURL == currentURL && (currentTime - lastHeaderTime) < 2.0 {
//            return
//        }
//        
//        lastHeaderURL = currentURL
//        lastHeaderTime = currentTime
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
//            self?.addHeadersToCurrentPage()
//        }
        
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if let urlError = error as? URLError, urlError.code.rawValue == -999 {
            return
        }
        showError(error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if let urlError = error as? URLError, urlError.code.rawValue == -999 {
            return
        }
        showError(error)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        DispatchQueue.main.async {
            
            let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "확인", style: UIAlertAction.Style.cancel) {
                _ in completionHandler()
            })
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func webView(
        _ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void
    ) {
        DispatchQueue.main.async {
            
            let alertController = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "취소", style: .cancel) { _ in
                completionHandler(false)
            }
            let okAction = UIAlertAction(title: "확인", style: .default) { _ in
                completionHandler(true)
            }
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        guard let loadURL = navigationAction.request.url?.absoluteString else {
            decisionHandler(.cancel)
            return
        }
        
        if loadURL == "about:blank" {
            decisionHandler(.allow)
            return
        }
        
        if navigationAction.targetFrame?.isMainFrame == false {
            decisionHandler(.allow)
            return
        }
        
        // 같은 URL을 클릭한 경우 - 사용자가 직접 클릭한 경우에만 처리
        if url == webView.url && navigationAction.navigationType == .linkActivated {
            handleUrlPatternRouting(url: url, decisionHandler: decisionHandler)
            return
        }
        
        // 같은 URL이지만 직접 클릭이 아닌 경우 허용
        if url == webView.url {
            decisionHandler(.allow)
            return
        }
        
        // 다른 URL로의 네비게이션 처리
        handleUrlPatternRouting(url: url, decisionHandler: decisionHandler)
    }

    // MARK: - Private Helper Methods
    private func handleUrlPatternRouting(url: URL, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let urlString = url.absoluteString
        print("Navigation to: \(urlString)")
        
        let checkUrl = extractBaseUrl(from: urlString)
        let urlType = checkUrlPattern(url: checkUrl)
        
        switch urlType {
        case "plusMain":
            decisionHandler(.cancel)
            openPlusMainApp(fallbackUrl: url)
            
        case "login":
            decisionHandler(.cancel)
            presentAccountViewController(type: "login")
            
        case "logout":
            decisionHandler(.cancel)
            presentLogoutViewController()
            
        case "join":
            decisionHandler(.cancel)
            presentAccountViewController(type: "join")
            
        case "accountInfo":
            decisionHandler(.cancel)
            presentAccountViewController(type: "accountInfo")
            
        case "pdf":
            decisionHandler(.cancel)
            presentPdfViewController(url: urlString)
            
        case "member":
            decisionHandler(.cancel)
            UIApplication.shared.open(url, options: [:])
            
        default:
            // 나머지 모든 경우
            decisionHandler(.cancel)
            addHeadersToCurrentPage(urlString: urlString)
        }
    }

    private func extractBaseUrl(from urlString: String) -> String {
        let index = urlString.firstIndex(of: "?") ?? urlString.endIndex
        let hostpath = urlString[..<index]
        return String(hostpath)
    }

    private func openPlusMainApp(fallbackUrl: URL) {
        let appURL = URL(string: "hkplus://plus")!
        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL, options: [:])
        } else {
            UIApplication.shared.open(fallbackUrl, options: [:])
        }
    }
    
    // MARK: - Helper Methods
    private func presentAccountViewController(type: String) {
        let accountView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AccountViewController") as! AccountViewController
        accountView.accountViewType = "login"
        accountView.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        self.present(accountView, animated: true, completion: nil)
    }
    
    private func presentLogoutViewController() {
        let logoutView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LogoutViewController") as! LogoutViewController
        self.present(logoutView, animated: false)
        return
    }
    
    private func presentPdfViewController(url: String) {
        guard let pvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PdfWebViewViewController") as? PdfWebViewViewController else {
            return
        }
        pvc.pdfUrl = url
        self.present(pvc, animated: true)
        return
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
            } else {
                print("JSON Data를 문자열로 변환 실패")
            }
        } catch {
            print("JSON 직렬화 오류: \(error.localizedDescription)")
        }
    }
}

// MARK: - RxSwift Extensions
extension Reactive where Base: WKWebView {
    var estimatedProgress: Observable<Double> {
        return observe(Double.self, "estimatedProgress")
            .map { $0 ?? 0.0 }
    }
}
