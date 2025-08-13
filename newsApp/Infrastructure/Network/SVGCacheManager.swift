//
//  SVGCacheManager.swift
//  newsApp
//
//  Created by jay on 6/9/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import RxSwift
import RxAlamofire

class SVGCacheManager {
    static let shared = SVGCacheManager()
    
    private let cache = NSCache<NSString, NSString>()
    
    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 50 * 1024 * 1024
        
        NotificationCenter.default.addObserver(
             self,
             selector: #selector(memoryWarning),
             name: UIApplication.didReceiveMemoryWarningNotification,
             object: nil
         )
    }
    
    
    @objc private func memoryWarning() {
        // 메모리 경고 시 일부만 제거 (전체 삭제 X)
        cache.removeAllObjects()
        print("⚠️ 메모리 경고로 SVG 캐시 일부 정리")
    }
    
    // 즉시 캐시 확인 (깜빡거림 방지용)
    func getCachedSVG(url: String) -> String? {
        guard !url.isEmpty, URL(string: url) != nil else { return nil }
        let key = url as NSString
        return cache.object(forKey: key) as String?
    }
    
    func getSVG(url: String) -> Observable<String> {
        // URL 유효성 검사
        guard !url.isEmpty, let validURL = URL(string: url) else {
            return Observable.error(SVGCacheError.invalidURL)
        }
        
        let key = url as NSString
        
        if let cached = cache.object(forKey: key) {
            return Observable.just(cached as String)
        }
        
        return RxAlamofire.string(.get, validURL)
            .do(onNext: { [weak self] svgData in
                // 캐시에 저장할 때 비용 계산 (문자열 길이 기반)
                let cost = svgData.count
                self?.cache.setObject(svgData as NSString, forKey: key, cost: cost)
                print("💾 SVG 캐시 저장: \(url) (크기: \(cost) bytes)")
            })
            .catch { error in
                return Observable.error(SVGCacheError.networkError(error))
            }
    }
}

enum SVGCacheError: Error, LocalizedError {
    case invalidURL
    case invalidData
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .invalidData:
            return "Invalid SVG data received"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
