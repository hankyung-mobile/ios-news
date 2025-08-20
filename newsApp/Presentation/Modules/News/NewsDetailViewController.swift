//
//  NewsDetailViewController.swift
//  newsApp
//
//  Created by jay on 5/23/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import WebKit
import RxSwift

class NewsDetailViewController: UIViewController, UIGestureRecognizerDelegate, WKUIDelegate {
    // 뉴스 정보
    private var url: URL
    private var newsTitle: String?
    
    // WeakScriptMessageHandler 참조 유지
    private var messageHandler: WeakScriptMessageHandler?
    
    // 중첩된 뉴스 링크 처리를 위한 델리게이트 추가
    weak var webNavigationDelegate: WebNavigationDelegate?
    
    // 웹뷰
    private var webView: WKWebView!
    
    private var lastProcessedURL: String?
    private var lastProcessedTime: TimeInterval = 0
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .custom)
        
        // iOS 13+ 에서 SF Symbols 사용
        if #available(iOS 13.0, *) {
            let image = UIImage(named: "backArrow")
            button.setImage(image, for: .normal)
            
        } else {
            button.setTitle("‹", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        }
        
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        return button
    }()
    
    // 로딩 인디케이터
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.color = .gray
        return indicator
    }()
    
    // 에러 메시지 레이블
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 14)
        label.isHidden = true
        return label
    }()
    
    // 프로그레스 바
    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = UIColor(red: 187 / 255, green: 38 / 255, blue: 73 / 255, alpha: 1.0)
        progress.trackTintColor = UIColor.lightGray.withAlphaComponent(0.3)
        progress.isHidden = true
        return progress
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail  // 길면 뒤쪽 생략
        return label
    }()
    
    private var disposeBag = DisposeBag()
    private var isLoaded = false
    
    // 로딩 감지 플래그
    private var hasInitialContent = false
    private var domContentLoaded = false
    
    // 로딩 타이머
    private var loadingTimer: Timer?
    private var loadStartTime: Date?
    
    private static let maxLoadingTime: TimeInterval = 8.0 // 뉴스 상세는 조금 더 긴 시간 허용
    
    private var isFirstLoad = true
    
    init(url: URL, title: String? = nil) {
        self.url = url
        self.newsTitle = title
        super.init(nibName: nil, bundle: nil)
        
        hidesBottomBarWhenPushed = false
        
        // 모달 프레젠테이션 스타일 설정
        self.modalPresentationStyle = .pageSheet
        
        // iOS 15+ 에서 시트 높이 조절 가능하도록 설정
        if #available(iOS 15.0, *) {
            if let sheet = sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.prefersGrabberVisible = false
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupViews()
        setupNavigationBar()
        loadUrl()
        
        // 메모리 최적화 알림 관찰자 설정
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(optimizeMemory),
            name: NSNotification.Name("OptimizeWebViewMemory"),
            object: nil
        )
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // onResume과 같음
        
        if !isFirstLoad {
                    // 최초 로드가 아닐 때만 실행
                    print("다시 나타남 - 최초 로드 아님")
                    callScriptWhenViewClosed(tokensArray: getUserTokensArray())
                }
                
                isFirstLoad = false
    }
    
    // 웹뷰 초기화
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.processPool = WebViewProcessPool.shared.pool
        
        // JavaScript 최적화
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        // 자바스크립트 이벤트 감지를 위한 사용자 컨텐츠 컨트롤러 추가
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: "window.addEventListener('DOMContentLoaded', function() { window.webkit.messageHandlers.domLoaded.postMessage('loaded'); });",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        contentController.addUserScript(script)
        
        // 고유한 메시지 핸들러 이름 사용 (충돌 방지)
        let messageHandlerName = "domLoaded_\(UUID().uuidString.prefix(8))"
        
        // WeakScriptMessageHandler 초기화
        self.messageHandler = WeakScriptMessageHandler(delegate: self)
        contentController.add(self.messageHandler!, name: messageHandlerName)
        
        // 스크립트에서 사용할 핸들러 이름 업데이트
        let updatedScript = WKUserScript(
            source: "window.addEventListener('DOMContentLoaded', function() { window.webkit.messageHandlers.\(messageHandlerName).postMessage('loaded'); });",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        contentController.removeAllUserScripts()
        contentController.addUserScript(updatedScript)
        
        configuration.userContentController = contentController
        
        // 웹뷰 성능 최적화 설정
        configuration.websiteDataStore = .default()
        
        webView = createWebView()
        webView.navigationDelegate = self
        webView.backgroundColor = .systemBackground
        webView.scrollView.delegate = self
        webView.isOpaque = false
        webView.uiDelegate = self
        
        // 엣지 스와이프로 뒤로가기 (네비게이션 컨트롤러가 있는 경우)
        if navigationController != nil {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            navigationController?.interactivePopGestureRecognizer?.delegate = self
        }
        
        
        // 뉴스 상세에서는 줌 비활성화
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.minimumZoomScale = 1.0
        
        self.webView.configuration.userContentController.add(self, name: "openNativeNewsList")
        self.webView.configuration.userContentController.add(self, name: "shareURL")
        self.webView.configuration.userContentController.add(self, name: "setTitle")
    }
    
    private func setupViews() {
        // 웹뷰 추가
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // 프로그레스 바 추가
        view.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        // 로딩 인디케이터 추가
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // 에러 레이블 추가
        view.addSubview(errorLabel)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 프로그레스 바
            progressView.topAnchor.constraint(equalTo: view.topAnchor, constant: 107),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),
            
            // 웹뷰 (프로그레스 바 다음에 위치하도록 임시 설정, setupNavigationBar에서 최종 설정)
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 로딩 인디케이터
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // 에러 레이블
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // 당겨서 새로고침 추가
        webView.scrollView.refreshControl = UIRefreshControl()
        webView.scrollView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
//        webView.scrollView.refreshControl?.tintColor = UIColor(red: 187 / 255, green: 38 / 255, blue: 73 / 255, alpha: 1.0)
        webView.scrollView.refreshControl?.tintColor = .gray
//        webView.scrollView.refreshControl?.attributedTitle = NSAttributedString(string: "당겨서 새로고침", attributes: [.foregroundColor: UIColor(red: 187 / 255, green: 38 / 255, blue: 73 / 255, alpha: 1.0)])
        webView.scrollView.refreshControl?.attributedTitle = NSAttributedString(string: "당겨서 새로고침", attributes: [.foregroundColor: UIColor(.gray)])
    }
    
    // MARK: - setupNavigationBar
    private func setupNavigationBar() {
        // 네비게이션 바 숨기고 커스텀 네비게이션 만들기
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 커스텀 네비게이션 바 컨테이너
        let navContainer = UIView()
        navContainer.backgroundColor = .systemBackground
        
        // 구분선
        let separator = UIView()
//        separator.backgroundColor = .separator.withAlphaComponent(0.3)
        separator.backgroundColor = UIColor(named: "#545456")
//        separator.layer.shadowOpacity = 0.85
//        separator.layer.shadowOffset = CGSize(width: 0, height: -2)
//        separator.layer.shadowRadius = 4
        
        view.addSubview(navContainer)
        navContainer.addSubview(backButton)
        navContainer.addSubview(titleLabel)
        navContainer.addSubview(separator)
        
        navContainer.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 네비게이션 컨테이너
            navContainer.topAnchor.constraint(equalTo: view.topAnchor), // Safe Area가 아닌 전체 top
            navContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navContainer.heightAnchor.constraint(equalToConstant: 60 + view.safeAreaInsets.top), // 상태바 높이 + 네비게이션 높이
            
            // 뒤로가기 버튼
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 55),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerXAnchor.constraint(equalTo: navContainer.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            // 구분선
            separator.leadingAnchor.constraint(equalTo: navContainer.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: navContainer.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: navContainer.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        // 웹뷰 제약조건 업데이트 (기존 제약조건 제거 후 새로 설정)
        webView.topAnchor.constraint(equalTo: navContainer.bottomAnchor).isActive = true
        
        // 프로그레스 바 위치도 업데이트
        progressView.topAnchor.constraint(equalTo: navContainer.bottomAnchor).isActive = true
        
        titleLabel.text = newsTitle ?? ""
    }
    
    deinit {
        print("NewsDetailViewController deinit called for URL: \(url)")
        
        // 알림 관찰자 제거
        NotificationCenter.default.removeObserver(self)
        
        // 델리게이트 참조 제거
        webView?.navigationDelegate = nil
        webView?.scrollView.delegate = nil
        webView?.uiDelegate = nil
        webView?.scrollView.refreshControl?.removeTarget(self, action: nil, for: .valueChanged)
        
        // messageHandler delegate 제거
        messageHandler?.delegate = nil
        
        // 메모리 정리
        webView?.configuration.userContentController.removeAllUserScripts()
        if let userContentController = webView?.configuration.userContentController {
            // 모든 스크립트 메시지 핸들러 제거 (안전하게)
            userContentController.removeAllScriptMessageHandlers()
        }
        
        // 타이머 중지
        stopLoadingTimer()
        
        // 구독 정리
        disposeBag = DisposeBag()
    }
    
    // URL 로드
    private func loadUrl() {
        if isLoaded {
            loadingIndicator.stopAnimating()
            return
        }
        
        loadingIndicator.startAnimating()
        progressView.isHidden = false
        progressView.progress = 0.0
        errorLabel.isHidden = true
        
        // 상태 초기화
        hasInitialContent = false
        domContentLoaded = false
        
        // 로드 시작 시간 기록
        loadStartTime = Date()
        
        // 캐시 정책 설정
        var request = URLRequest(url: url)
        
        let parameter = returnAccountParameter()
        
        //            let paramString = (parameter.compactMap({ (key, value) -> String in return "\(key)=\(value)" }) as Array).joined(separator: "&")
        
        for (key, value) in parameter {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        //            request.httpBody = paramString.data(using: .utf8)
        
        webView.load(request)
        
        // 백업 타이머 시작
        startLoadingTimer()
        
        // 프로그레스 모니터링
        monitorLoadingProgress()
        
    }
    
    // 프로그레스 모니터링
    private func monitorLoadingProgress() {
        disposeBag = DisposeBag()
        
        webView.rx.observe(Double.self, "estimatedProgress")
            .take(until: rx.deallocated)
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance) // 0.5초 간격으로 제한
            .distinctUntilChanged { abs(($0 ?? 0) - ($1 ?? 0)) < 0.1 } // 0.1 이상 변화시만 처리
            .subscribe(onNext: { [weak self] progress in
                guard let self = self, let progress = progress else { return }
                
                if progress > 0.3 && !self.hasInitialContent {
                    self.checkForVisibleContent()
                }
            })
            .disposed(by: disposeBag)
    }
    
    // 썸네일/첫 내용이 보이는지 확인하는 메서드
    private func checkForVisibleContent() {
        if !hasInitialContent && (domContentLoaded || webView.estimatedProgress > 0.3) {
            hasInitialContent = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.hideLoadingIndicator()
            }
        }
    }
    
    // 로딩 인디케이터 숨김
    private func hideLoadingIndicator() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.loadingIndicator.isAnimating else { return }
            
            self.loadingIndicator.stopAnimating()
            self.stopLoadingTimer()
            self.loadStartTime = nil
            self.isLoaded = true
        }
    }
    
    // 로딩 타이머 시작
    private func startLoadingTimer() {
        loadStartTime = Date()
        stopLoadingTimer()
        
        // 1초 → 3초로 간격 늘리기
        loadingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.checkLoadingTimeout()
        }
    }

    private func checkLoadingTimeout() {
        guard let startTime = loadStartTime else { return }
        
        if Date().timeIntervalSince(startTime) > NewsDetailViewController.maxLoadingTime {
            forceCompleteLoading()
        } else {
            // 아직 시간이 남았으면 다시 스케줄링
            loadingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                self?.checkLoadingTimeout()
            }
        }
    }
    
    // 로딩 타이머 중지
    private func stopLoadingTimer() {
        if Thread.isMainThread {
            loadingTimer?.invalidate()
            loadingTimer = nil
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.loadingTimer?.invalidate()
                self?.loadingTimer = nil
            }
        }
    }
    
    // 로딩 강제 완료
    private func forceCompleteLoading() {
        hideLoadingIndicator()
    }
    
    // 메모리 최적화
    @objc func optimizeMemory() {
        let script = """
        // 현재 스크롤 위치만 저장
        var scrollPos = {x: window.scrollX, y: window.scrollY};
        
        // 비효율적인 전체 DOM 순회 대신 특정 요소만 처리
        var lazyImages = document.querySelectorAll('img[loading="lazy"]');
        var offscreenImages = 0;
        
        for (var i = 0; i < Math.min(lazyImages.length, 50); i++) { // 최대 50개만 처리
            var img = lazyImages[i];
            var rect = img.getBoundingClientRect();
            
            if (rect.bottom < -1000 || rect.top > window.innerHeight + 1000) {
                if (!img.hasAttribute('data-src') && img.src) {
                    img.setAttribute('data-src', img.src);
                    img.removeAttribute('src');
                    offscreenImages++;
                    
                    if (offscreenImages > 10) break; // 최대 10개만 처리
                }
            }
        }
        
        window.scrollTo(scrollPos.x, scrollPos.y);
        """
        
        // 메모리 최적화도 throttle 적용
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.webView.evaluateJavaScript(script, completionHandler: nil)
        }
    }
    
    @objc private func retryLoading() {
        errorLabel.isHidden = true
        isLoaded = false
        loadUrl()
    }
    
    @objc private func backButtonTapped() {
        // 네비게이션 컨트롤러가 있고 루트가 아닌 경우 pop
        if let navigationController = navigationController,
           navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            // 모달로 표시된 경우 dismiss
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func shareButtonTapped() {
        // 현재 웹페이지의 제목과 URL을 함께 공유
        var shareItems: [Any] = [url]
        
        if let title = newsTitle, !title.isEmpty, title != "" {
            shareItems.insert(title, at: 0)
        }
        
        let activityVC = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        
        // 제외할 활동 설정 (선택사항)
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks
        ]
        
        present(activityVC, animated: true, completion: nil)
    }
    
    @objc func handleRefreshControl() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.isLoaded = false
            self.loadUrl()
            self.webView.scrollView.refreshControl?.endRefreshing()
        }
    }
    
    @objc private func handleLoginSuccess() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            //            self?.webView?.reload()
//            self?.callScriptWhenViewClosed(tokensArray: getUserTokensArray())
            
//            self?.webView.takeSnapshot(with: nil) { image, error in
//                guard let snapshot = image else {
//                    print("스냅샷 생성 실패 - 리로드")
//                    DispatchQueue.main.async {
//                        self?.errorLabel.isHidden = true
//                        self?.isLoaded = false
//                        self?.loadUrl()
//                    }
//                    return
//                }
//                
//                // 이미지가 대부분 흰색인지 체크
//                if ((isImageMostlyWhite(snapshot)) == true) {
//                    print("화면이 대부분 흰색 - 리로드")
//                    DispatchQueue.main.async {
//                        self?.errorLabel.isHidden = true
//                        self?.isLoaded = false
//                        self?.loadUrl()
//                    }
//                }
//            }
            
        }
    }

    @objc private func handleLogoutSuccess() {
        print("🔥 \(type(of: self)) - 로그아웃 성공, 웹뷰 리로드")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
//            self?.webView?.reload()
            self?.callScriptWhenViewClosed(tokensArray: getUserTokensArray())
        }
    }
}

// MARK: - WKNavigationDelegate
extension NewsDetailViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        handleBrowserRouting(for: navigationAction, decisionHandler: decisionHandler)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        checkForVisibleContent()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if !hasInitialContent {
            hideLoadingIndicator()
        }
        isLoaded = true
        
        // 페이지 제목 가져오기 (없으면 기본값 유지)
//        webView.evaluateJavaScript("document.title") { [weak self] (result, error) in
//            if let title = result as? String, !title.isEmpty, self?.newsTitle == nil {
//                DispatchQueue.main.async {
//                    self?.newsTitle = title
//                }
//            }
//        }
        
        // 텍스트 복사, 붙여넣기 막기
//        webView.evaluateJavaScript("document.documentElement.style.webkitUserSelect='none'", completionHandler: nil)
//        webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none'", completionHandler: nil)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if let urlError = error as? URLError, urlError.code.rawValue == -999 {
            return
        }
        
        hideLoadingIndicator()
        handleLoadError(error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if let urlError = error as? URLError, urlError.code.rawValue == -999 {
            return
        }
        
        let errorDescription = error.localizedDescription
        if errorDescription.contains("프레임 로드 중단됨") ||
           errorDescription.contains("Frame load interrupted") {
            return
        }
        
        hideLoadingIndicator()
        handleLoadError(error)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {

        if let response = navigationResponse.response as? HTTPURLResponse {
//            print("webviw response status code: \(response.statusCode)")
            
            switch response.statusCode {
            case (200...299):
//                print("Note: cookie load success")
                print("")
            case (300...399):
                print("Note: cookie load redirection")
            case (400...499):
                print("Error: clientError code 400...499")
                errorLabel.text = "페이지를 로드할 수 없습니다.\n\(response.statusCode)\n탭하여 다시 시도하세요."
                errorLabel.isHidden = true
                
                // 오류 레이블에 탭 제스처 추가
                if errorLabel.gestureRecognizers == nil {
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(retryLoading))
                    errorLabel.isUserInteractionEnabled = true
                    errorLabel.addGestureRecognizer(tapGesture)
                }

            case (500...599):
                print("Error: serverError code 500...599")
                errorLabel.text = "페이지를 로드할 수 없습니다.\n\(response.statusCode)\n탭하여 다시 시도하세요."
                errorLabel.isHidden = true
                
                // 오류 레이블에 탭 제스처 추가
                if errorLabel.gestureRecognizers == nil {
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(retryLoading))
                    errorLabel.isUserInteractionEnabled = true
                    errorLabel.addGestureRecognizer(tapGesture)
                }

            default:
                print("unknown")
            }
        }
        
        decisionHandler(.allow)
    }
    
    private func handleLoadError(_ error: Error) {
        if hasInitialContent {
            return
        }
        
        errorLabel.text = "뉴스를 로드할 수 없습니다.\n\(error.localizedDescription)\n탭하여 다시 시도하세요."
        errorLabel.isHidden = true
        
        if errorLabel.gestureRecognizers == nil {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(retryLoading))
            errorLabel.isUserInteractionEnabled = true
            errorLabel.addGestureRecognizer(tapGesture)
        }
    }
    
    private func callScriptWhenViewClosed(tokensArray: [String]) {
        do {
            
            let parameters: [String] = [
                               "sino1741%40hankyung.com",
                               "OJCthdnekNFWaUn3Q7+gSDvOvErwLatd5D+lhaH6Jmayih0OQqrD4DRC7qkcmGF+WYSrOz33JA/Rsy0CWapTPlPjOrjB1iJ57V0nteN7duwZwOSyaNrthMCRogPs0pcPWWfTgUo5ZWYalftTIXdrbyHxn96Yprq7FXGLDA7csDzTYD7GIU50opfwKhI9LQ6AlLZyOhlRNgveHBzupTm7M7FWtRjx5lFvr+DeUWx+WiMxCR2DjmAh/hIdrNY1J49G2RfT7pu3HAdZm/qsbnD8AusXiTlRNlJq158dF8RXX0nxosA7SSh+/7xAxQhZwPar",
                               "33242a3e1415f2b886114df883cbb4887b9670aa7e6afa5d7d2f286025232d88f7ab78769bc2784339481a3d4b5ba7a8b136026f45de8193ba64696a9aff4f31a9c66d430a0146e9534bfcf9da1c550e09b057c2a0216bf5e8df958b2b8194cc989dc02a518ecf0ee5ab758bf159da40a4e61b8817c314e15dde3d6e5228eeca8a9d8c33b479867a28c16811ff86d52c0e433ce189ad3674956a5afe10d481e8"
                           ]
            // 2. Swift 배열을 JSON Data로 변환
            let jsonData = try JSONSerialization.data(withJSONObject: tokensArray, options: [])
            // options: [] 는 JSON 출력을 포맷팅하지 않음을 의미합니다. (더 작고 효율적)
            
            // 3. JSON Data를 UTF-8 문자열로 변환
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                // jsonString의 예시: ["33242a...", "another_sso...", "yet_another..."]
                
                // 4. JavaScript 함수 호출 스크립트 생성
                // JSON 문자열을 직접 JavaScript 함수의 파라미터로 삽입
                // **주의**: JSON 문자열 자체는 JavaScript에서 유효한 배열/객체 리터럴이므로,
                // 스크립트 내에서 다시 작은따옴표로 감싸지 않습니다!
                let script = "window.onGetMobileInfo(\(jsonString))"
                
                print("실행될 JavaScript 스크립트:\n\(script)") // 디버깅을 위해 출력해보면 좋습니다.
                
                // 5. JavaScript 실행
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
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
       
       DispatchQueue.main.async {
           // 이미 alert가 떠있거나 뷰가 준비되지 않았으면 바로 completion 호출
           guard self.view.window != nil,
                 self.presentedViewController == nil else {
               completionHandler()
               return
           }
           
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
           // 이미 alert가 떠있거나 뷰가 준비되지 않았으면 바로 false로 completion 호출
           guard self.view.window != nil,
                 self.presentedViewController == nil else {
               completionHandler(false)
               return
           }
           
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
}

// MARK: - WKScriptMessageHandler
extension NewsDetailViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name.hasPrefix("domLoaded_") {
            domContentLoaded = true
            checkForVisibleContent()
        }
        
        if message.name == "openNativeNewsList" {
            
            let body = message.body
            
            guard let dictionary = body as? [String: Any] else {
                
                let msg = "오류가 발생했습니다. 다시 시도해 주세요."

                let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "확인", style: .default, handler: nil)
                alert.addAction(defaultAction)
                
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: {
                        self.presentingViewController?.dismiss(animated: true)
                    })
                }
                return
            }
            
            let type = dictionary["type"] as? String ?? ""
            let sectionid = dictionary["sectionid"] as? String ?? ""
            let sectionName = dictionary["sectionName"] as? String ?? ""
            let cid = dictionary["cid"] as? String ?? ""
            let mediaid = dictionary["mediaid"] as? String ?? ""
            let tagid = dictionary["tagid"] as? String ?? ""
            let period = dictionary["period"] as? Int
            let placeCode = dictionary["placeCode"] as? String ?? ""
            let deptid = dictionary["deptid"] as? String ?? ""
            
            
            if type == "newsList" {
                
                let storyboard = UIStoryboard(name: "SectionList", bundle: nil)
                let sectionListVC = storyboard.instantiateViewController(withIdentifier: "SectionListViewController") as! SectionListViewController
                sectionListVC.webNavigationDelegate = self.webNavigationDelegate

                // 받은 데이터로 파라미터 전달
                 sectionListVC.parameters = [
                     "sectionid": sectionid,
                     "cid": cid,
                     "mediaid": mediaid,
                     "tagid": tagid,
                     "period": period ?? "",
                     "place_code": placeCode,
                     "deptid": deptid
                 ]
                
                // 벋은 데이터로 타이틀 전달
                sectionListVC.viewTitle = sectionName
                
                navigationController?.pushViewController(sectionListVC, animated: true)
                
            } else if type == "photoSlide" {
                //                self.accountInfoCallback(dictionary)
                let imgUrl = dictionary["imgUrl"] as? [String] ?? []
                guard let photoVC = UIStoryboard(name: "PhotoSlide", bundle: nil).instantiateViewController(withIdentifier: "PhotoSlideViewController") as? PhotoSlideViewController else {
                    return
                }
                photoVC.configure(with: imgUrl)
//                newsDetailVC.webNavigationDelegate = self
                photoVC.hidesBottomBarWhenPushed = true
                
                navigationController?.pushViewController(photoVC, animated: true)
            }
        }
        
        if message.name == "shareURL" {
            
            let body = message.body
            
            guard let dictionary = body as? [String: Any] else {
                
                let msg = "오류가 발생했습니다. 다시 시도해 주세요."
                
                let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "확인", style: .default, handler: nil)
                alert.addAction(defaultAction)
                
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: {
                        self.presentingViewController?.dismiss(animated: true)
                    })
                }
                return
            }
            
            let url = dictionary["url"] as? String ?? ""
            
            let activityViewController = UIActivityViewController(
                activityItems: [url],
                applicationActivities: nil
            )
            
            present(activityViewController, animated: true)
        }
        
        if message.name == "setTitle" {
            
            let body = message.body
            
            guard let dictionary = body as? [String: Any] else {
                
                let msg = "오류가 발생했습니다. 다시 시도해 주세요."
                
                let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "확인", style: .default, handler: nil)
                alert.addAction(defaultAction)
                
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: {
                        self.presentingViewController?.dismiss(animated: true)
                    })
                }
                return
            }
            
            let title = dictionary["title"] as? String ?? ""
            self.titleLabel.text = title
            
        }
    }
}

// MARK: - UIScrollViewDelegate
extension NewsDetailViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 뉴스 상세에서는 스크롤 위치 저장 불필요 (한 번만 읽는 콘텐츠)
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
}

// MARK: - WKUserContentController Extension for Safe Handler Removal
extension WKUserContentController {
    func removeAllScriptMessageHandlers() {
        // iOS에서 기본 제공하지 않는 메서드이므로 직접 구현
        // 실제로는 각 핸들러 이름을 저장해두고 개별적으로 제거해야 합니다
        // 여기서는 안전을 위한 더미 구현
    }
}

extension NewsDetailViewController {
    
    /// 브라우저 라우팅 로직을 기존 decidePolicyFor에 통합
    func handleBrowserRouting(for navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
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
        
        let urlString = url.absoluteString
        print("Navigation to: \(urlString), Type: \(navigationAction.navigationType.rawValue)")
        
        // 같은 URL을 클릭한 경우 - 사용자가 직접 클릭한 경우에만 처리
        if url == webView.url {
            if navigationAction.navigationType == .linkActivated {
                handleSpecialUrlsAndRouting(url: url, urlString: urlString, decisionHandler: decisionHandler)
                return
            }
            decisionHandler(.allow)
            return
        }
        
        // 다른 URL로의 네비게이션 처리
        handleSpecialUrlsAndRouting(url: url, urlString: urlString, decisionHandler: decisionHandler)
    }

    // MARK: - Private Helper Methods
    private func handleSpecialUrlsAndRouting(url: URL, urlString: String, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let checkUrl = extractBaseUrl(from: urlString)
        let urlType = checkUrlPattern(url: checkUrl)
        
        // 특수 URL 패턴 처리
        if handleSpecialUrlPattern(urlType: urlType, url: url, urlString: urlString, decisionHandler: decisionHandler) {
            return
        }
        
        // 브라우저 라우팅 처리
        handleBrowserTypeRouting(urlString: urlString, url: url, decisionHandler: decisionHandler)
    }

    private func extractBaseUrl(from urlString: String) -> String {
        let index = urlString.firstIndex(of: "?") ?? urlString.endIndex
        let hostpath = urlString[..<index]
        return String(hostpath)
    }

    private func handleSpecialUrlPattern(urlType: String, url: URL, urlString: String, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) -> Bool {
        switch urlType {
        case "plusMain":
            decisionHandler(.cancel)
            let appURL: URL = URL(string: "hkplus://plus")!
            if UIApplication.shared.canOpenURL(appURL) {
                UIApplication.shared.open(appURL, options: [:])
            } else {
                UIApplication.shared.open(url, options: [:])
            }
            return true
            
        case "login":
            decisionHandler(.cancel)
            presentAccountViewController(type: "login")
            return true
            
        case "logout":
            decisionHandler(.cancel)
            presentLogoutViewController()
            return true
            
        case "join":
            decisionHandler(.cancel)
            presentAccountViewController(type: "join")
            return true
            
        case "accountInfo":
            decisionHandler(.cancel)
            presentAccountViewController(type: "accountInfo")
            return true
            
        case "pdf":
            decisionHandler(.cancel)
            presentPdfViewController(url: urlString)
            return true
            
        case "consensus":
            decisionHandler(.cancel)
            addHeadersToCurrentPage(urlString: urlString)
            return true
            
        case "member":
            decisionHandler(.cancel)
            UIApplication.shared.open(url, options: [:])
            return true
            
        default:
            return false
        }
    }

    private func handleBrowserTypeRouting(urlString: String, url: URL, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let browserType = BrowserRouterService.shared.determineBrowserType(for: urlString)
        
        switch browserType {
        case .newWindow:
            print("Opening in new window (browser routing): \(urlString)")
            decisionHandler(.cancel)
            webNavigationDelegate?.openNewsDetail(url: url, title: nil)
            
        case .internalBrowser:
            print("Opening in internal browser: \(urlString)")
            decisionHandler(.cancel)
            openInternalBrowser(url: url)
            
        case .externalBrowser:
            print("Opening in external browser: \(urlString)")
            decisionHandler(.cancel)
            UIApplication.shared.open(url, options: [:])
            
        // 기본값 - 현재 웹뷰에서 처리
        default:
            decisionHandler(.allow)
        }
    }
    
    // MARK: - Internal Browser Opening
    private func openInternalBrowser(url: URL) {
        let internalBrowserVC = InternalBrowserViewController(url: url)
        let navigationController = UINavigationController(rootViewController: internalBrowserVC)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)
    }
    
    // MARK: - Helper Methods (기존 로직들)
    private func presentAccountViewController(type: String) {
        guard let accountView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AccountViewController") as? AccountViewController else {
            return
        }

        accountView.accountViewType = "login"
        accountView.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        
        accountView.onDismiss = { [weak self] in
            self?.callScriptWhenViewClosed(tokensArray: getUserTokensArray())
        }
        
        // Root view controller에서 present
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(accountView, animated: true, completion: nil)
        }
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
}

// MARK: - UIGestureRecognizerDelegate
//extension NewsDetailViewController: UIGestureRecognizerDelegate {
//    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        // 네비게이션 컨트롤러의 interactivePopGestureRecognizer인 경우
//        if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
//            return true  // 항상 허용
//        }
//        
//        // 팬 제스처 관련 코드...
//        if gestureRecognizer == panGestureRecognizer {
//            // 기존 코드...
//        }
//        
//        return true
//    }
//}
