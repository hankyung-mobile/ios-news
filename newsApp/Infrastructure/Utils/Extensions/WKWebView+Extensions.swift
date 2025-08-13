//
//  WKWebView+Extensions.swift
//  newsApp
//
//  Created by jay on 6/5/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import WebKit

extension WKWebView {
    /// 공통 쿠키 스토어와 동기화
    func syncWithCommonCookies(completion: (() -> Void)? = nil) {
        // commonWebView의 쿠키를 이 웹뷰에 복사
        commonWebView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else {
                completion?()
                return
            }
            
            let group = DispatchGroup()
            for cookie in cookies {
                // hankyung.com 도메인 쿠키만 동기화
                if cookie.domain.contains("hankyung.com") {
                    group.enter()
                    self.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                print("✅ Cookies synced to webview")
                completion?()
            }
        }
    }
}
