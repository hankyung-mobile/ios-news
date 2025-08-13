//
//  UIImageView+SVG.swift
//  newsApp
//
//  Created by jay on 6/9/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import RxSwift

extension UIImageView {
    private static var currentRequestKey: UInt8 = 0
    private static var disposeBagKey: UInt8 = 1
    
    private var currentRequestURL: String? {
        get { objc_getAssociatedObject(self, &UIImageView.currentRequestKey) as? String }
        set { objc_setAssociatedObject(self, &UIImageView.currentRequestKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var disposeBag: DisposeBag {
        get {
            if let bag = objc_getAssociatedObject(self, &UIImageView.disposeBagKey) as? DisposeBag {
                return bag
            }
            let bag = DisposeBag()
            objc_setAssociatedObject(self, &UIImageView.disposeBagKey, bag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return bag
        }
    }
    
    func loadSVG(url: String, defaultImage: UIImage? = nil, size: CGSize? = nil, animated: Bool = true, completion: (() -> Void)? = nil) {
        guard !url.isEmpty else {
            self.image = defaultImage
            completion?()
            return
        }
        
        currentRequestURL = url
        
        // 캐시 확인
        if let cached = SVGCacheManager.shared.getCachedSVG(url: url) {
            setSVGImageFromString(cached, requestURL: url, size: size, animated: animated, completion: completion)
            return
        }
        
        // 기존 이미지가 없을 때만 기본 이미지 설정
        if self.image == nil, let defaultImage = defaultImage {
            self.image = defaultImage
        }
        
        SVGCacheManager.shared.getSVG(url: url)
                .do(onSubscribe: {
                    print("🔍 SVGCacheManager.getSVG 구독 시작: \(url)")
                })
                .observe(on: MainScheduler.instance)
                .subscribe(
                    onNext: { svgString in
                        DispatchQueue.main.async { [weak self] in
                            print("✅ SVG 데이터 받음: \(url), 길이: \(svgString.count)")
                            guard let self = self, self.currentRequestURL == url else {
                                print("⚠️ self 없거나 URL 불일치")
                                return
                            }
                            self.setSVGImageFromString(svgString, requestURL: url, size: size, animated: animated, completion: completion)
                        }
                    },
                    onError: { error in
                        print("❌ SVG 로드 에러: \(url), 에러: \(error)")
                        completion?()
                    },
                    onCompleted: {
                        print("🔍 SVG 로드 완료: \(url)")
                    },
                    onDisposed: {
                        print("🔍 SVG 로드 dispose: \(url)")
                    }
                )
                .disposed(by: disposeBag)
    }
    
    // 🚀 public 메서드 추가 (캐시된 SVG 즉시 표시용)
    func setSVGImageFromCachedString(_ svgString: String, requestURL: String, size: CGSize? = nil, animated: Bool = true, completion: (() -> Void)? = nil) {
        currentRequestURL = requestURL
        setSVGImageFromString(svgString, requestURL: requestURL, size: size, animated: animated, completion: completion)
    }
    
    private func setSVGImageFromString(_ svgString: String, requestURL: String, size: CGSize? = nil, animated: Bool = true, completion: (() -> Void)? = nil) {
        if let targetSize = size {
            createWebView(svgString: svgString, requestURL: requestURL, targetSize: targetSize, animated: animated, completion: completion)
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.layoutIfNeeded()
                
                // 🔧 크기 계산 개선 - 기존 방식 유지하되 간소화
                var targetSize = self.bounds.size
                
                if targetSize.width <= 0 || targetSize.height <= 0 {
                    if let superview = self.superview {
                        superview.layoutIfNeeded()
                        targetSize = self.bounds.size
                    }
                }
                
                if targetSize.width <= 0 || targetSize.height <= 0 {
                    targetSize = CGSize(width: 100, height: 100)
                }
                
                self.createWebView(svgString: svgString, requestURL: requestURL, targetSize: targetSize, animated: animated, completion: completion)
            }
        }
    }
    
    private func createWebView(svgString: String, requestURL: String, targetSize: CGSize, animated: Bool, completion: (() -> Void)? = nil) {
        // 🔧 각 요청마다 새로운 WebView 생성 (크기 문제 해결)
        let webView = WKWebView(frame: CGRect(origin: .zero, size: targetSize))
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        
        let loadingDelegate = FastWebViewDelegate { [weak self] in
            guard let self = self, self.currentRequestURL == requestURL else {
                webView.removeFromSuperview()
                completion?()
                return
            }
            self.convertToImage(webView, requestURL: requestURL, animated: animated, completion: completion)
        }
        
        webView.navigationDelegate = loadingDelegate
        objc_setAssociatedObject(webView, "delegate", loadingDelegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // 🔧 정확한 크기의 HTML 생성
        let html = """
        <html>
        <head>
            <meta name="viewport" content="width=\(targetSize.width), height=\(targetSize.height), initial-scale=1.0">
            <style>
                body { 
                    margin:0; padding:0; 
                    width:\(targetSize.width)px; height:\(targetSize.height)px;
                    display:flex; justify-content:center; align-items:center; 
                    background:transparent; overflow:hidden; 
                }
                svg { 
                    max-width:100%; max-height:100%; 
                    width:auto; height:auto;
                }
            </style>
        </head>
        <body>\(svgString)</body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    private func convertToImage(_ webView: WKWebView, requestURL: String, animated: Bool, completion: (() -> Void)? = nil) {
        webView.takeSnapshot(with: nil) { [weak self] image, error in
            guard let self = self,
                  self.currentRequestURL == requestURL,
                  let image = image else {
                DispatchQueue.main.async {
                    webView.removeFromSuperview()
                    completion?()
                }
                return
            }
            
            SVGImageCache.shared.cacheImage(image, for: requestURL)
            
            DispatchQueue.main.async {
                if self.currentRequestURL == requestURL {
                    if animated && self.image != nil {
                        self.animateImageChange(image) {
                            completion?()
                        }
                    } else {
                        self.image = image
                        completion?()
                    }
                }
                webView.removeFromSuperview()
            }
        }
    }
    
    private func animateImageChange(_ newImage: UIImage, completion: (() -> Void)? = nil) {
        UIView.transition(with: self,
                         duration: 0.1,
                         options: [.transitionCrossDissolve, .allowUserInteraction],
                         animations: { self.image = newImage },
                         completion: { _ in completion?() })
    }
}

extension UIImageView {
    var isTopAligned: Bool {
        get {
            return layer.contentsRect.origin.y == 0 && layer.contentsRect.size.height < 1
        }
        set {
            if newValue {
                applyTopAlignment()
            } else {
                layer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: 1)
            }
        }
    }
    
    private func applyTopAlignment() {
        guard let image = image else { return }
        
        contentMode = .scaleAspectFill
        clipsToBounds = true
        
        let imageRatio = image.size.width / image.size.height
        let viewRatio = bounds.width / bounds.height
        
        if imageRatio < viewRatio {
            let scale = bounds.width / image.size.width
            let scaledHeight = image.size.height * scale
            let visibleHeight = bounds.height / scaledHeight
            
            layer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: visibleHeight)
        }
    }
}

private class FastWebViewDelegate: NSObject, WKNavigationDelegate {
    private let onComplete: () -> Void
    
    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onComplete()
    }
}

//
//  SVGImageCache.swift
//  newsApp
//

import UIKit

class SVGImageCache {
    static let shared = SVGImageCache()
    private init() {}
    
    // 단순 URL별 이미지 캐시
    private var imageCache: [String: UIImage] = [:]
    
    func cacheImage(_ image: UIImage, for url: String) {
        imageCache[url] = image
    }
    
    func getCachedImage(for url: String) -> UIImage? {
        return imageCache[url]
    }
    
    func clearCache() {
        imageCache.removeAll()
    }
}
