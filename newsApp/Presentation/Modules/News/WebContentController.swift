//
//  WebViewController.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import WebKit
import RxSwift

class WebContentController: UIViewController, WKUIDelegate {
    // 관리할 URL
    private var url: URL
    
    // WeakScriptMessageHandler 참조 유지
    private var messageHandler: WeakScriptMessageHandler?
    
    // 뉴스 네비게이션 델리게이트 추가
    weak var webNavigationDelegate: WebNavigationDelegate?
    
    // 웹뷰를 lazy가 아닌 일반 프로퍼티로 변경
    private var webView: WKWebView!
    
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
    
    private lazy var errorContainerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground // 또는 원하는 배경색
        containerView.isHidden = true
        containerView.isUserInteractionEnabled = true
        return containerView
    }()

    // 에러 이미지뷰
    private lazy var errorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "network_error") // 커스텀 이미지
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var disposeBag = DisposeBag()
    private var isLoaded = false
    private var isFirstAppearance = true
    private var savedScrollPosition: CGPoint = .zero
    
    // 로딩 감지 플래그
    private var hasInitialContent = false
    private var domContentLoaded = false
    
    // 로딩 타이머
    private var loadingTimer: Timer?
    private var loadStartTime: Date?
    
    // 로딩 상태 감지 백업 메커니즘
    private static let maxLoadingTime: TimeInterval = 10.0 // 미리 로드 시 더 긴 시간 허용
    private var lastProcessedURL: String?
    private var lastProcessedTime: TimeInterval = 0
    
    // 스크롤 이벤트 throttling
    private var lastScrollTime: TimeInterval = 0
    
    private var isFirstLoad = true
    
    // 웹뷰 로드 완료 상태
    var isWebViewLoaded: Bool {
        return isLoaded
    }
    
    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
        
        // 초기화 시점에 웹뷰 설정
        setupWebView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
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
    
    // 웹뷰 초기화 메서드 분리
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
        
        // WeakScriptMessageHandler 초기화
        self.messageHandler = WeakScriptMessageHandler(delegate: self)
        contentController.add(self.messageHandler!, name: "domLoaded")
        configuration.userContentController = contentController
        
        // 웹뷰 성능 최적화 설정
        configuration.websiteDataStore = .default()
        
        webView = createWebView()
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        
        // 백그라운드에서 렌더링 허용
        webView.isOpaque = false
        webView.uiDelegate = self
        
        self.webView.configuration.userContentController.add(self, name: "openNativeNewsList")
        self.webView.configuration.userContentController.add(self, name: "shareURL")
        self.webView.configuration.userContentController.add(self, name: "moveToNewsTab")
        self.webView.configuration.userContentController.add(self, name: "doReload")
    }
    
    private func setupViews() {
        // 웹뷰 추가 (이미 초기화된 상태)
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 에러 레이블 추가
        view.addSubview(errorLabel)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // 에러 컨테이너 뷰 추가 (웹뷰 다음에 추가해서 위에 표시)
        view.addSubview(errorContainerView)
        errorContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 컨테이너 뷰 내부에 이미지뷰만 추가
        errorContainerView.addSubview(errorImageView)
        
        NSLayoutConstraint.activate([
            // 에러 컨테이너 뷰 - 웹뷰와 같은 영역
            errorContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            errorContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 컨테이너 뷰 내부 - 이미지뷰 (실사이즈, 중앙 정렬)
            errorImageView.centerXAnchor.constraint(equalTo: errorContainerView.centerXAnchor),
            errorImageView.centerYAnchor.constraint(equalTo: errorContainerView.centerYAnchor, constant: -53)
        ])
        
        // 로딩 인디케이터 추가 (가장 마지막에 추가해서 최상위에 표시)
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -53)
        ])
        
        webView.scrollView.refreshControl = UIRefreshControl()
        webView.scrollView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
        webView.scrollView.refreshControl?.tintColor = .gray
        webView.scrollView.refreshControl?.attributedTitle = NSAttributedString(string: "당겨서 새로고침", attributes: [.foregroundColor: UIColor(.gray)])
    }

    
    // 에러 이미지 표시 함수
    private func showErrorImage() {
        errorContainerView.isHidden = false
        
//        // 에러 이미지뷰에 탭 제스처 추가
//        if errorImageView.gestureRecognizers == nil {
//            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(retryLoading))
//            errorImageView.addGestureRecognizer(tapGesture)
//        }
    }
    
    // 미리 로드 메서드 추가
    func preloadWebView() {
        // 이미 로드된 경우 스킵
        guard !isLoaded else { return }
        
        print("🌐 웹뷰 미리 로드 시작: \(url)")
        loadUrl()
    }
    
    deinit {
        print("WebContentController deinit called for URL: \(url)")
        
        // 알림 관찰자 제거
        NotificationCenter.default.removeObserver(self)
        
        // 델리게이트 참조 제거
        webView?.navigationDelegate = nil
        webView?.uiDelegate = nil
        webView?.scrollView.delegate = nil
        webView?.scrollView.refreshControl?.removeTarget(self, action: nil, for: .valueChanged)
        
        // messageHandler delegate 제거
        messageHandler?.delegate = nil
        
        // 메모리 정리
        webView?.configuration.userContentController.removeAllUserScripts()
        if let userContentController = webView?.configuration.userContentController {
            userContentController.removeScriptMessageHandler(forName: "domLoaded")
        }
        
        // 타이머 중지
        stopLoadingTimer()
        
        // 구독 정리
        disposeBag = DisposeBag()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 타임아웃 확인
        if loadingIndicator.isAnimating && !hasInitialContent {
            if let startTime = loadStartTime, Date().timeIntervalSince(startTime) > WebContentController.maxLoadingTime {
                forceCompleteLoading()
            }
        }
        
        // 이미 로드된 경우 스크롤 위치 복원
        if isLoaded && savedScrollPosition != .zero {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
//                self.webView.scrollView.setContentOffset(self.savedScrollPosition, animated: false)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 로딩 타이머 시작
        if !hasInitialContent && loadStartTime == nil {
            startLoadingTimer()
        }
        
        // 포그라운드 최적화 적용
        optimizeForForeground()
        
        // 스크롤 위치 재확인 및 복원
        if isLoaded && savedScrollPosition != .zero {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                let currentOffset = self.webView.scrollView.contentOffset
                if abs(currentOffset.y - self.savedScrollPosition.y) > 10 {
//                    self.webView.scrollView.setContentOffset(self.savedScrollPosition, animated: false)
                }
            }
        }
        
        if !isFirstLoad {
            print("다시 나타남 - 최초 로드 아님")
            callScriptWhenViewClosed(tokensArray: getUserTokensArray())
        }
        
        isFirstLoad = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 스크롤 위치 저장
        savedScrollPosition = webView.scrollView.contentOffset
        
        // 타이머 중지
        stopLoadingTimer()
        
        // 백그라운드 최적화 적용
        optimizeForBackground()
    }
    
    // 로딩 타이머 시작
    private func startLoadingTimer() {
        loadStartTime = Date()
        stopLoadingTimer()
        
        loadingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.checkLoadingTimeout()
        }
    }
    
    private func checkLoadingTimeout() {
        guard let startTime = loadStartTime else { return }
        
        if Date().timeIntervalSince(startTime) > WebContentController.maxLoadingTime {
            forceCompleteLoading()
        } else {
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
    
    // 로딩 강제 완료 (타임아웃 시)
    private func forceCompleteLoading() {
        hideLoadingIndicator()
    }
    
    // 로딩 인디케이터 숨김 (중복 호출 방지)
    private func hideLoadingIndicator() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.loadingIndicator.isAnimating else { return }
            
            self.loadingIndicator.stopAnimating()
            self.stopLoadingTimer()
            self.loadStartTime = nil
            self.isLoaded = true
        }
    }
    
    // 썸네일/첫 내용이 보이는지 확인하는 메서드
    private func checkForVisibleContent() {
        // DOM 콘텐츠가 로드되었거나 첫 내용이 시각적으로 표시된 경우
        if !hasInitialContent && (domContentLoaded || webView.estimatedProgress > 0.3) {
            hasInitialContent = true
            
            // 약간의 지연 후 인디케이터 숨김 (더 많은 콘텐츠 로드 기회 제공)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.hideLoadingIndicator()
            }
        }
    }
    
    // URL 로드
    private func loadUrl() {
        // 이미 로드된 상태면 인디케이터만 숨김
        if isLoaded {
            loadingIndicator.stopAnimating()
//            return
        }
        
        loadingIndicator.startAnimating()
        errorLabel.isHidden = true
        
        // 상태 초기화
        hasInitialContent = false
        domContentLoaded = false
        
        // 로드 시작 시간 기록
        loadStartTime = Date()
        
        var request = URLRequest(url: url)
        
        let parameter = returnAccountParameter()
//        let paramString = (parameter.compactMap({ (key, value) -> String in return "\(key)=\(value)" }) as Array).joined(separator: "&")
        
        for (key, value) in parameter {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
//        request.httpBody = paramString.data(using: .utf8)
        
        // 캐시 정책 설정 - 캐시 우선
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
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged { abs(($0 ?? 0) - ($1 ?? 0)) < 0.1 }
            .subscribe(onNext: { [weak self] progress in
                guard let self = self, let progress = progress else { return }
                
                if progress > 0.3 && !self.hasInitialContent {
                    self.checkForVisibleContent()
                }
            })
            .disposed(by: disposeBag)
    }
    
    // 뉴스 상세 URL인지 판단
    private func shouldOpenInNewController(_ urlString: String) -> Bool {
        return urlString.contains("/news/") ||
               urlString.contains("/article/") ||
               urlString.contains("/detail/") ||
               urlString.contains("/item/") ||
               urlString.contains("read.nhn") ||
               urlString.contains("article.naver") ||
               urlString.contains("/board/") ||
               urlString.contains("oid=") ||
               urlString.contains("aid=") ||
               urlString.contains("/view/") ||
               urlString.contains("articleId=")
    }
    
    // 백그라운드 최적화 개선
    func optimizeForBackground() {
        guard let webView = webView else { return }
        
        let currentOffset = webView.scrollView.contentOffset
        
        let script = """
        // 스크롤 위치 저장 (네이티브와 동기화)
        window._savedScroll = {x: \(currentOffset.x), y: \(currentOffset.y)};
        
        // 비디오 일시정지
        document.querySelectorAll('video').forEach(function(video) {
            video.pause();
        });
        
        // 애니메이션 중지
        document.querySelectorAll('*').forEach(function(element) {
            element.style.animationPlayState = 'paused';
            element.style.webkitAnimationPlayState = 'paused';
        });
        """
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    // 포그라운드 최적화 개선
    func optimizeForForeground() {
        guard let webView = webView else { return }
        
        let script = """
        // 애니메이션 재시작
        document.querySelectorAll('*').forEach(function(element) {
            element.style.animationPlayState = 'running';
            element.style.webkitAnimationPlayState = 'running';
        });
        
        // 저장된 스크롤 위치가 있으면 복원
        if (window._savedScroll) {
            window.scrollTo(window._savedScroll.x, window._savedScroll.y);
        }
        """
        
//        webView.evaluateJavaScript(script) { [weak self] (_, error) in
//            if error != nil {
//                DispatchQueue.main.async {
//                    guard let self = self, let webView = self.webView, self.savedScrollPosition != .zero else { return }
//                    webView.scrollView.setContentOffset(self.savedScrollPosition, animated: false)
//                }
//            }
//        }
    }
    
    // 메모리 최적화
    @objc func optimizeMemory() {
        let script = """
        // 현재 스크롤 위치만 저장
        var scrollPos = {x: window.scrollX, y: window.scrollY};
        
        // 비효율적인 전체 DOM 순회 대신 특정 요소만 처리
        var lazyImages = document.querySelectorAll('img[loading="lazy"]');
        var offscreenImages = 0;
        
        for (var i = 0; i < Math.min(lazyImages.length, 50); i++) {
            var img = lazyImages[i];
            var rect = img.getBoundingClientRect();
            
            if (rect.bottom < -1000 || rect.top > window.innerHeight + 1000) {
                if (!img.hasAttribute('data-src') && img.src) {
                    img.setAttribute('data-src', img.src);
                    img.removeAttribute('src');
                    offscreenImages++;
                    
                    if (offscreenImages > 10) break;
                }
            }
        }
        
        window.scrollTo(scrollPos.x, scrollPos.y);
        """
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.webView.evaluateJavaScript(script, completionHandler: nil)
        }
    }
    
    // 로드 재시도
    @objc private func retryLoading() {
        errorLabel.isHidden = true
        isLoaded = false
        loadUrl()
    }
    
    var currentURL: URL {
        return url
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
            // self?.webView?.reload()
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
            // self?.webView?.reload()
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
            } else {
                print("JSON Data를 문자열로 변환 실패")
            }
        } catch {
            print("JSON 직렬화 오류: \(error.localizedDescription)")
        }
    }

}

// MARK: - WKNavigationDelegate 개선
extension WebContentController: WKNavigationDelegate {
    // 새 기능: 링크 클릭 시 새 화면으로 이동할지 결정
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        handleBrowserRouting(for: navigationAction, decisionHandler: decisionHandler)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        // 첫 내용이 표시되기 시작할 때 호출됨
        checkForVisibleContent()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // 페이지 로드 완료
        if !hasInitialContent {
            hideLoadingIndicator()
        }
        isLoaded = true
        
        print("✅ 웹뷰 로드 완료: \(url)")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // 취소 오류(-999)는 무시
        if let urlError = error as? URLError, urlError.code.rawValue == -999 {
            return
        }
        
        hideLoadingIndicator()
        handleLoadError(error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // 취소 오류(-999)는 무시
        if let urlError = error as? URLError, urlError.code.rawValue == -999 {
            return
        }
        
        // 프레임 로드 중단 오류 무시
        let errorDescription = error.localizedDescription
        if errorDescription.contains("프레임 로드 중단됨") ||
           errorDescription.contains("Frame load interrupted") {
            return
        }
        
        hideLoadingIndicator()
        handleLoadError(error)
    }
    
    private func handleLoadError(_ error: Error) {
        // 실패했지만 이미 콘텐츠가 표시되고 있다면 무시
        if hasInitialContent {
            return
        }
        
        // 오류 메시지 표시
        errorLabel.text = "페이지를 로드할 수 없습니다.\n\(error.localizedDescription)\n탭하여 다시 시도하세요."
        errorLabel.isHidden = true
        
        // 오류 레이블에 탭 제스처 추가
        if errorLabel.gestureRecognizers == nil {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(retryLoading))
            errorLabel.isUserInteractionEnabled = true
            errorLabel.addGestureRecognizer(tapGesture)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {

        if let response = navigationResponse.response as? HTTPURLResponse {
//            print("webview response status code: \(response.statusCode)")
            
            switch response.statusCode {
            case (200...299):
//                print("Note: cookie load success")
                errorContainerView.isHidden = true
                print("")
            case (300...399):
                print("Note: cookie load redirection")
                errorContainerView.isHidden = true
            case (400...499):
                print("Error: clientError code 400...499")
                errorLabel.text = "페이지를 로드할 수 없습니다.\n\(response.statusCode)\n탭하여 다시 시도하세요."
                errorLabel.isHidden = true
                
                if errorLabel.gestureRecognizers == nil {
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(retryLoading))
                    errorLabel.isUserInteractionEnabled = true
                    errorLabel.addGestureRecognizer(tapGesture)
                }
                showErrorImage()
            case (500...599):
                print("Error: serverError code 500...599")
                errorLabel.text = "페이지를 로드할 수 없습니다.\n\(response.statusCode)\n탭하여 다시 시도하세요."
                errorLabel.isHidden = true
                
                if errorLabel.gestureRecognizers == nil {
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(retryLoading))
                    errorLabel.isUserInteractionEnabled = true
                    errorLabel.addGestureRecognizer(tapGesture)
                }
                showErrorImage()
            default:
                print("unknown")
            }
        }
        
        decisionHandler(.allow)
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
extension WebContentController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "domLoaded" {
            // DOM 콘텐츠가 로드되었다는 메시지를 받음
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
            let slug = dictionary["slug"] as? String ?? ""
            
            
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
                     "deptid": deptid,
                     "slug": slug
                 ]
                
                // 벋은 데이터로 타이틀 전달
                sectionListVC.viewTitle = sectionName
                
                navigationController?.pushViewController(sectionListVC, animated: true)
                
            } else if type == "photoSlide" {
                //                self.accountInfoCallback(dictionary)
                let imgUrl = dictionary["imgUrl"] as? [String] ?? []
                let photoVC = PhotoSlideViewController()
                photoVC.configure(with: imgUrl)
//                newsDetailVC.webNavigationDelegate = self
                photoVC.hidesBottomBarWhenPushed = false
                
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
        
        if message.name == "moveToNewsTab" {
            
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
            
            let id = dictionary["id"] as? String ?? ""
            let url = dictionary["url"] as? String ?? ""
            
            NotificationCenter.default.post(
                name: .moveToNewsPage,
                object: nil,
                userInfo: ["id": id]
            )
        }
        
        if message.name == "doReload" {
            loadUrl()
        }

    }
}

// MARK: - UIScrollViewDelegate 개선
extension WebContentController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentTime = Date().timeIntervalSince1970
        
        // 0.1초마다만 처리 (부드러움 유지하면서 CPU 부하 감소)
        if currentTime - lastScrollTime > 0.1 {
            if isLoaded {
                savedScrollPosition = scrollView.contentOffset
            }
            lastScrollTime = currentTime
        }
    }
    
    // 스크롤이 끝났을 때도 저장 (더 정확한 위치)
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if isLoaded {
            savedScrollPosition = scrollView.contentOffset
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if isLoaded && !decelerate {
            savedScrollPosition = scrollView.contentOffset
        }
    }
}

// MARK: - WebNavigationDelegate Protocol
protocol WebNavigationDelegate: AnyObject {
    func openNewsDetail(url: URL, title: String?)
}

protocol ScrollableViewController {
    func scrollToTop()
}

extension WebContentController {
    
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

extension WebContentController: ScrollableViewController {
    func scrollToTop() {
        webView.evaluateJavaScript("window.scrollTo({top: 0, behavior: 'smooth'})", completionHandler: nil)
    }
}
