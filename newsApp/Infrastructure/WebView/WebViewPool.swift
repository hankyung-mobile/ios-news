//
//  WebViewPool.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import WebKit

/// WebView 재사용을 위한 풀 관리 클래스
class WebViewPool {
    // 최대 웹뷰 풀 크기
    private let maxPoolSize = 3
    
    // 재사용 가능한 웹뷰 큐
    private var recycledWebViews = [WKWebView]()
    
    // 동시성 제어를 위한 직렬 큐
    private let serialQueue = DispatchQueue(label: "com.yourapp.webviewpool")
    
    // 마지막 사용 시간 추적을 위한 딕셔너리
    private var lastUsedTimes = [WKWebView: Date]()
    
    // 웹뷰 풀에서 재사용 가능한 웹뷰 가져오기
    func dequeueWebView() -> WKWebView? {
        var webView: WKWebView?
        
        serialQueue.sync {
            if !recycledWebViews.isEmpty {
                webView = recycledWebViews.removeFirst()
                // 재사용 시 마지막 사용 시간 업데이트
                if let webView = webView {
                    lastUsedTimes[webView] = Date()
                }
            }
        }
        
        return webView
    }
    
    // 사용 완료된 웹뷰를 풀에 반환
    func enqueueWebView(_ webView: WKWebView) {
        serialQueue.sync {
            // 풀 크기 제한 확인
            if recycledWebViews.count < maxPoolSize {
                // 이미 풀에 포함되어 있는지 확인
                if !recycledWebViews.contains(where: { $0 === webView }) {
                    recycledWebViews.append(webView)
                    lastUsedTimes[webView] = Date()
                }
            } else {
                // 풀이 가득 찬 경우, 가장 오래된 웹뷰 제거
                removeOldestWebView()
                recycledWebViews.append(webView)
                lastUsedTimes[webView] = Date()
            }
        }
    }
    
    // 가장 오래된(사용되지 않은) 웹뷰 제거
    private func removeOldestWebView() {
        guard !recycledWebViews.isEmpty else { return }
        
        var oldestWebView: WKWebView?
        var oldestTime = Date()
        
        for webView in recycledWebViews {
            if let lastUsed = lastUsedTimes[webView], lastUsed < oldestTime {
                oldestTime = lastUsed
                oldestWebView = webView
            }
        }
        
        if let webView = oldestWebView {
            recycledWebViews.removeAll { $0 === webView }
            lastUsedTimes.removeValue(forKey: webView)
            cleanupWebView(webView)
        }
    }
    
    // 메모리 경고 시 사용되지 않는 웹뷰 정리
    func clearUnusedWebViews() {
        serialQueue.sync {
            // 현재 시간
            let now = Date()
            
            // 일정 시간(5분) 이상 사용되지 않은 웹뷰 찾기
            let unusedTimeout: TimeInterval = 5 * 60
            
            let outdatedWebViews = recycledWebViews.filter { webView in
                if let lastUsed = lastUsedTimes[webView] {
                    return now.timeIntervalSince(lastUsed) > unusedTimeout
                }
                return true
            }
            
            // 사용되지 않은 웹뷰 정리
            for webView in outdatedWebViews {
                recycledWebViews.removeAll { $0 === webView }
                lastUsedTimes.removeValue(forKey: webView)
                cleanupWebView(webView)
            }
        }
    }
    
    // 웹뷰 완전 정리 (메모리 해제)
    private func cleanupWebView(_ webView: WKWebView) {
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
    
    // 풀에 있는 모든 웹뷰 정리
    func clearAllWebViews() {
        serialQueue.sync {
            for webView in recycledWebViews {
                cleanupWebView(webView)
            }
            
            recycledWebViews.removeAll()
            lastUsedTimes.removeAll()
        }
    }
    
    // 현재 풀 크기 확인
    var poolSize: Int {
        var size = 0
        serialQueue.sync {
            size = recycledWebViews.count
        }
        return size
    }
}
