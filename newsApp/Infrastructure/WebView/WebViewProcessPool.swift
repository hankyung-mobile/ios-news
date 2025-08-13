//
//  WebViewProcessPool.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import WebKit

// 프로세스 풀을 공유하여 웹뷰 간 리소스 공유 및 최적화
class WebViewProcessPool {
    static let shared = WebViewProcessPool()
    
    let pool: WKProcessPool
    
    private init() {
        pool = WKProcessPool()
//        pool = sharedWKProcessPool
    }
}
