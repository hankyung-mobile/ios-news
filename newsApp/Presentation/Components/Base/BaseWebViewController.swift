////
////  BaseWebViewController.swift
////  newsApp
////
////  Created by jay on 5/20/25.
////  Copyright © 2025 hkcom. All rights reserved.
////
//
//import Foundation
//import UIKit
//import WebKit
//
//class BaseWebViewController: UIViewController {
//    // 웹뷰 (lazy로 설정하여 초기화 지연)
//    lazy var webView: WKWebView = {
//        // 웹뷰 풀에서 재사용 가능한 웹뷰 가져오기
//        let webView = WebViewPool.shared.dequeueWebView()
//        return webView
//    }()
//    
//    // UI 컴포넌트
//    private let progressView = UIProgressView(progressViewStyle: .default)
//    private let refreshControl = UIRefreshControl()
//    private let errorView = ErrorView()
//    private let loadingView = LoadingView()
//    
//    // 웹뷰 관련 매니저
//    private let webViewManager = WebViewManager.shared
//    private let jsBridgeManager = JSBridgeManager.shared
//    
//    // KVO 옵저버
//    private var progressObserver: NSKeyValueObservation?
//    private var titleObserver: NSKeyValueObservation?
//    
//    // 자바스크립트 핸들러 목록
//    private var jsHandlers: [String] = []
//    
//    // MARK: - 생명주기 메서드
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupWebView()
//        setupUI()
//        setupObservers()
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        // 필요한 경우 웹뷰 복원
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        // 필요한 경우 웹뷰 상태 저장
//    }
//    
//    deinit {
//        // KVO 옵저버 해제
//        progressObserver?.invalidate()
//        titleObserver?.invalidate()
//        
//        // 웹뷰 풀에 반환
//        WebViewPool.shared.enqueueWebView(webView)
//        
//        print("♻️ BaseWebViewController deinit")
//    }
//    
//    // MARK: - 웹뷰 설정
//    
//    private func setupWebView() {
//        // 웹뷰 델리게이트 설정
//        webView.navigationDelegate = self
//        webView.uiDelegate = self
//        
//        // 새로고침 설정
//        webView.scrollView.refreshControl = refreshControl
//        refreshControl.addTarget(self, action: #selector(refreshWebView), for: .valueChanged)
//        
//        // 기본 핸들러 설정
//        registerJSHandlers()
//    }
//    
//    // 자바스크립트 핸들러 등록
//    func registerJSHandlers() {
//        // 기본 핸들러 등록
//        jsHandlers = ["bridgeReady", "navigate", "share", "openUrl"]
//        
//        // 서브클래스에서 추가 핸들러 설정 가능
//        setupAdditionalHandlers()
//        
//        // 브릿지 설정
//        jsBridgeManager.setupBridge(for: webView, handlers: jsHandlers)
//        
//        // 핸들러 함수 등록
//        setupHandlerFunctions()
//    }
//    
//    // 추가 핸들러 설정 (서브클래스에서 오버라이드)
//    func setupAdditionalHandlers() {
//        // 서브클래스에서 구현
//    }
//    
//    // 핸들러 함수 등록
//    private func setupHandlerFunctions() {
//        // 네비게이션 핸들러
//        jsBridgeManager.registerHandler("navigate") { [weak self] data in
//            guard let self = self,
//                  let dict = data as? [String: Any],
//                  let route = dict["route"] as? String else { return }
//            
//            DispatchQueue.main.async {
//                self.handleNavigation(route: route, params: dict["params"] as? [String: Any])
//            }
//        }
//        
//        // 공유 핸들러
//        jsBridgeManager.registerHandler("share") { [weak self] data in
//            guard let self = self,
//                  let dict = data as? [String: Any],
//                  let content = dict["content"] as? String else { return }
//            
//            DispatchQueue.main.async {
//                self.handleShare(content: content, url: dict["url"] as? String)
//            }
//        }
//        
//        // URL 열기 핸들러
//        jsBridgeManager.registerHandler("openUrl") { [weak self] data in
//            guard let self = self,
//                  let dict = data as? [String: Any],
//                  let urlString = dict["url"] as? String,
//                  let url = URL(string: urlString) else { return }
//            
//            DispatchQueue.main.async {
//                self.handleOpenUrl(url)
//            }
//        }
//    }
//    
//    // MARK: - UI 설정
//    
//    private func setupUI() {
//        // 웹뷰 및 관련 UI 추가
//        view.addSubview(webView)
//        view.addSubview(progressView)
//        view.addSubview(errorView)
//        view.addSubview(loadingView)
//        
//        // 오토레이아웃 설정
//        webView.translatesAutoresizingMaskIntoConstraints = false
//        progressView.translatesAutoresizingMaskIntoConstraints = false
//        errorView.translatesAutoresizingMaskIntoConstraints = false
//        loadingView.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            
//            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            progressView.heightAnchor.constraint(equalToConstant: 2),
//            
//            errorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            
//            loadingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//        
//        // 초기 상태 설정
//        progressView.progress = 0
//        errorView.isHidden = true
//        loadingView.isHidden = false
//        
//        // 오류 시 재시도 버튼 액션
////        errorView.retryButton.addTarget(self, action: #selector(retryLoading), for: .touchUpInside)
//    }
//    
//    // MARK: - 옵저버 설정
//    
//    private func setupObservers() {
//        // 웹뷰 로딩 진행 상황 관찰
//        progressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, change in
//            guard let self = self else { return }
//            let progress = Float(webView.estimatedProgress)
//            
//            self.progressView.progress = progress
//            self.progressView.isHidden = progress >= 1.0
//        }
//        
//        // 웹페이지 제목 관찰 (필요한 경우)
//        titleObserver = webView.observe(\.title, options: [.new]) { [weak self] webView, change in
//            guard let self = self, let newTitle = webView.title, !newTitle.isEmpty else { return }
//            self.title = newTitle
//        }
//        
//        // 네트워크 상태 변화 관찰
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(networkStatusChanged),
//            name: NSNotification.Name("NetworkStatusChanged"),
//            object: nil
//        )
//        
//        // 메모리 경고 관찰
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(didReceiveMemoryWarning),
//            name: UIApplication.didReceiveMemoryWarningNotification,
//            object: nil
//        )
//    }
//    
//    // MARK: - 웹뷰 로딩 메서드
//    
//    // URL 로드
//    func loadURL(_ urlString: String) {
//        showLoading()
//        webViewManager.loadURL(urlString, on: webView)
//    }
//    
//    // HTML 문자열 로드
//    func loadHTMLString(_ html: String, baseURL: URL? = nil) {
//        showLoading()
//        webViewManager.loadHTMLString(html, baseURL: baseURL, on: webView)
//    }
//    
//    // JavaScript 실행
//    func executeJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)? = nil) {
//        webViewManager.executeJavaScript(script, on: webView, completion: completion)
//    }
//    
//    // MARK: - 웹뷰 액션 메서드
//    
//    // 웹뷰 새로고침
//    @objc func refreshWebView() {
//        webView.reload()
//    }
//    
//    // 로딩 실패 시 재시도
//    @objc func retryLoading() {
//        errorView.isHidden = true
//        showLoading()
//        webView.reload()
//    }
//    
//    // 네트워크 상태 변경 처리
//    @objc func networkStatusChanged(_ notification: Notification) {
//        guard let isConnected = notification.userInfo?["isConnected"] as? Bool else { return }
//        
//        if !isConnected {
////            errorView.configure(message: "인터넷 연결이 끊어졌습니다.")
//            errorView.isHidden = false
//        } else if errorView.isHidden == false {
//            errorView.isHidden = true
//            webView.reload()
//        }
//    }
//    
//    // 메모리 경고 처리
//    @objc override func didReceiveMemoryWarning() {
//        // 현재 보이지 않는 이미지 등 웹뷰 리소스 정리
//        let script = """
//            (function() {
//                var images = document.querySelectorAll('img');
//                for (var i = 0; i < images.length; i++) {
//                    var img = images[i];
//                    var rect = img.getBoundingClientRect();
//                    var isVisible = rect.top < window.innerHeight && rect.bottom > 0;
//                    if (!isVisible) {
//                        img.src = '';
//                        img.setAttribute('data-src', img.src);
//                    }
//                }
//            })();
//            """
//        
//        executeJavaScript(script)
//    }
//    
//    // MARK: - UI 상태 관리
//    
//    // 로딩 화면 표시
//    func showLoading() {
//        loadingView.isHidden = false
////        loadingView.startAnimating()
//    }
//    
//    // 로딩 화면 숨김
//    func hideLoading() {
//        loadingView.isHidden = true
////        loadingView.stopAnimating()
//        refreshControl.endRefreshing()
//    }
//    
//    // MARK: - 핸들러 메서드
//    
//    // 네비게이션 핸들러 (서브클래스에서 오버라이드)
//    func handleNavigation(route: String, params: [String: Any]?) {
//        print("🔄 Navigation requested to route: \(route), params: \(String(describing: params))")
//        // 서브클래스에서 구현
//    }
//    
//    // 공유 핸들러
//    func handleShare(content: String, url: String?) {
//        var itemsToShare: [Any] = [content]
//        
//        if let urlString = url, let url = URL(string: urlString) {
//            itemsToShare.append(url)
//        }
//        
//        let activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
//        present(activityVC, animated: true)
//    }
//    
//    // URL 열기 핸들러
//    func handleOpenUrl(_ url: URL) {
//        if UIApplication.shared.canOpenURL(url) {
//            UIApplication.shared.open(url)
//        }
//    }
//    
//    // 네이티브 -> 웹 데이터 전송
//    func sendDataToWeb(event: String, data: Any) {
//        jsBridgeManager.sendToWeb(event: event, data: data, webView: webView)
//    }
//}
//
//// MARK: - WKNavigationDelegate
//extension BaseWebViewController: WKNavigationDelegate {
//    // 웹뷰 탐색 시작
//    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
//        progressView.isHidden = false
//    }
//    
//    // 웹뷰 탐색 완료
//    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        hideLoading()
//        errorView.isHidden = true
//    }
//    
//    // 웹뷰 탐색 실패
//    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
//        hideLoading()
//        
//        // 네트워크 오류 처리
//        let nsError = error as NSError
//        if nsError.domain == NSURLErrorDomain &&
//            (nsError.code == NSURLErrorNotConnectedToInternet || nsError.code == NSURLErrorNetworkConnectionLost) {
////            errorView.configure(message: "인터넷 연결을 확인해주세요.")
//        } else {
////            errorView.configure(message: "페이지를 로드할 수 없습니다.")
//        }
//        
//        errorView.isHidden = false
//    }
//    
//    // 탐색 결정 (URL 처리)
//    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        // URL 스킴 처리
//        if let url = navigationAction.request.url,
//           let scheme = url.scheme,
//           scheme != "http" && scheme != "https" {
//            
//            if UIApplication.shared.canOpenURL(url) {
//                UIApplication.shared.open(url)
//                decisionHandler(.cancel)
//                return
//            }
//        }
//        
//        decisionHandler(.allow)
//    }
//}
//
//// MARK: - WKUIDelegate
//extension BaseWebViewController: WKUIDelegate {
//    // Alert 다이얼로그 표시
//    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
//        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//        alertController.addAction(UIAlertAction(title: "확인", style: .default) { _ in
//            completionHandler()
//        })
//        
//        present(alertController, animated: true)
//    }
//    
//    // Confirm 다이얼로그 표시
//    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
//        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//        
//        alertController.addAction(UIAlertAction(title: "확인", style: .default) { _ in
//            completionHandler(true)
//        })
//        
//        alertController.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
//            completionHandler(false)
//        })
//        
//        present(alertController, animated: true)
//    }
//    
//    // Prompt 다이얼로그 표시
//    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
//        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
//        
//        alertController.addTextField { textField in
//            textField.text = defaultText
//        }
//        
//        alertController.addAction(UIAlertAction(title: "확인", style: .default) { _ in
//            completionHandler(alertController.textFields?.first?.text)
//        })
//        
//        alertController.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
//            completionHandler(nil)
//        })
//        
//        present(alertController, animated: true)
//    }
//    
//    // 새 창 열기 처리 (웹뷰 내에서 처리)
//    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
//        // 팝업을 현재 웹뷰에서 열도록 처리
//        if let url = navigationAction.request.url {
//            webView.load(URLRequest(url: url))
//        }
//        return nil
//    }
//}
