//
//  WebViewManager.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import WebKit
import RxSwift
import RxCocoa

class WebViewManager {
    // 싱글톤 인스턴스
    static let shared = WebViewManager()
    
    // 웹뷰 풀
    private let webViewPool = WebViewPool()
    
    // 자바스크립트 브릿지 관리자
    private let jsBridgeManager = JSBridgeManager()
    
    // 쿠키 관리자
    private let cookieManager = CookieManager()
    
    private init() {
        // 메모리 경고 관찰
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 웹뷰 생성 및 관리
    
    /// 새 웹뷰 생성 또는 풀에서 재사용 (기본 설정 적용)
    func createWebView(configuration: WKWebViewConfiguration? = nil) -> WKWebView {
        // 풀에서 재사용 가능한 웹뷰가 있는지 확인
        if let webView = webViewPool.dequeueWebView() {
            webView.reload()
            return webView
        }
        
        // 웹뷰 구성 설정
        let config = configuration ?? createDefaultConfiguration()
        
        // 새 웹뷰 생성
        let webView = WKWebView(frame: .zero, configuration: config)
        setupDefaultSettings(for: webView)
        
        return webView
    }
    
    /// 웹뷰를 풀에 반환 (메모리 관리)
    func recycleWebView(_ webView: WKWebView) {
        // 웹뷰 내용 정리
        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
        
        // WKWebView 캐시 데이터 삭제
        if #available(iOS 15.0, *) {
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { _ in }
        }
        
        // 풀에 반환
        webViewPool.enqueueWebView(webView)
    }
    
    /// 웹뷰 완전 제거 (메모리에서 해제)
    func disposeWebView(_ webView: WKWebView) {
        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
        
        // WKWebView의 모든 delegate 제거
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.scrollView.delegate = nil
        
        // WKWebView 캐시 데이터 삭제
        if #available(iOS 15.0, *) {
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { _ in }
        }
    }
    
    // MARK: - 웹뷰 설정
    
    /// 기본 WKWebViewConfiguration 생성
    private func createDefaultConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        
        // 웹뷰 환경 설정
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = false
        
        if #available(iOS 14.0, *) {
            let pagePreferences = WKWebpagePreferences()
            pagePreferences.allowsContentJavaScript = true
            config.defaultWebpagePreferences = pagePreferences
        }
        
        config.preferences = preferences
        
        // 프로세스 풀 설정 (메모리 관리)
        if #available(iOS 14.0, *) {
            config.limitsNavigationsToAppBoundDomains = true
            config.processPool = WKProcessPool()
        }
        
        // 사용자 콘텐츠 컨트롤러 설정 (JS 브릿지 등록)
        let contentController = WKUserContentController()
        jsBridgeManager.registerBridgeHandlers(for: contentController)
        config.userContentController = contentController
        
        return config
    }
    
    /// 웹뷰 기본 설정 적용
    private func setupDefaultSettings(for webView: WKWebView) {
        // 웹뷰 기본 설정
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = true
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = true
        webView.isOpaque = false
        webView.backgroundColor = .white
        
        // 콘텐츠 모드 설정
        if #available(iOS 15.0, *) {
            webView.underPageBackgroundColor = .white
        }
        
        // 디바이스별 확대/축소 조정
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.minimumZoomScale = 1.0
        
        // iOS 11 이상에서는 SafeArea 설정
        if #available(iOS 11.0, *) {
            webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        }
    }
    
    // MARK: - 메모리 관리
    
    /// 메모리 경고 처리
    @objc private func handleMemoryWarning() {
        // 메모리 경고 시 재활용 큐 정리
        webViewPool.clearUnusedWebViews()
        
        // 디스크 및 메모리 캐시 정리
        clearWebViewCaches()
    }
    
    /// 웹뷰 캐시 정리
    func clearWebViewCaches() {
        // 모든 유형의 웹사이트 데이터 삭제
        let dataTypes = Set([WKWebsiteDataTypeDiskCache,
                            WKWebsiteDataTypeMemoryCache,
                            WKWebsiteDataTypeOfflineWebApplicationCache])
        
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes,
                                               modifiedSince: date) {
            print("✅ WebView caches cleared")
        }
    }
    
    // MARK: - 쿠키 관리
    
    /// 웹뷰에 쿠키 추가
    func setCookie(for webView: WKWebView, name: String, value: String, domain: String, path: String = "/", isSecure: Bool = false) {
        cookieManager.setCookie(for: webView, name: name, value: value, domain: domain, path: path, isSecure: isSecure)
    }
    
    /// 웹뷰에서 쿠키 가져오기
    func getCookies(for webView: WKWebView, domain: String? = nil) -> Observable<[HTTPCookie]> {
        return cookieManager.getCookies(for: webView, domain: domain)
    }
    
    /// 웹뷰 쿠키 삭제
    func deleteCookies(for webView: WKWebView, domain: String? = nil) -> Observable<Void> {
        return cookieManager.deleteCookies(for: webView, domain: domain)
    }
    
    // MARK: - URL 로드
    
    /// URL 로드 (문자열)
    func loadUrl(_ urlString: String, in webView: WKWebView) -> Observable<Bool> {
        guard let url = URL(string: urlString) else {
            return Observable.just(false)
        }
        
        return loadUrl(url, in: webView)
    }
    
    /// URL 로드 (URL 객체)
    func loadUrl(_ url: URL, in webView: WKWebView) -> Observable<Bool> {
        return Observable.create { observer in
            let request = URLRequest(url: url)
            webView.load(request)
            
            // 로드 성공으로 간주 (실제 로드 완료는 delegate에서 처리)
            observer.onNext(true)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    /// HTML 문자열 로드
    func loadHTML(_ htmlString: String, in webView: WKWebView, baseURL: URL? = nil) -> Observable<Bool> {
        return Observable.create { observer in
            webView.loadHTMLString(htmlString, baseURL: baseURL)
            
            // 로드 성공으로 간주
            observer.onNext(true)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    // MARK: - JavaScript 실행
    
    /// 자바스크립트 코드 실행
    func evaluateJavaScript(_ script: String, in webView: WKWebView) -> Observable<Any?> {
        return Observable.create { observer in
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    observer.onError(error)
                } else {
                    observer.onNext(result)
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
    
    /// 자바스크립트 함수 호출 (매개변수 전달)
    func callJavaScriptFunction(_ functionName: String, withParameters parameters: [Any], in webView: WKWebView) -> Observable<Any?> {
        // 매개변수를 JSON으로 직렬화
        let jsonParameters = parameters.map { param -> String in
            if let string = param as? String {
                return "\"\(string.replacingOccurrences(of: "\"", with: "\\\""))\""
            } else if let data = try? JSONSerialization.data(withJSONObject: param),
                      let jsonString = String(data: data, encoding: .utf8) {
                return jsonString
            } else {
                return "\(param)"
            }
        }.joined(separator: ",")
        
        // 함수 호출 스크립트 구성
        let script = "\(functionName)(\(jsonParameters));"
        
        return evaluateJavaScript(script, in: webView)
    }
    
    // MARK: - 자바스크립트 브릿지 관리
    
    /// 네이티브 메서드 등록 (자바스크립트에서 호출 가능)
    func registerNativeHandler(for webView: WKWebView, handlerName: String, handler: @escaping (Any) -> Any?) {
        jsBridgeManager.registerNativeHandler(for: webView, handlerName: handlerName, handler: handler)
    }
    
    /// 네이티브 이벤트 발생 (자바스크립트에 알림)
    func emitNativeEvent(to webView: WKWebView, eventName: String, data: [String: Any]) -> Observable<Void> {
        return jsBridgeManager.emitNativeEvent(to: webView, eventName: eventName, data: data)
    }
}
