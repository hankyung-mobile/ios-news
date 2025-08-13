//
//  CookieManager.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import WebKit
import RxSwift

/// 웹뷰 쿠키 관리 클래스
class CookieManager {
    // 쿠키 저장소
    private let cookieStore = WKWebsiteDataStore.default().httpCookieStore
    
    // MARK: - 쿠키 설정
    
    /// 웹뷰에 쿠키 추가
    func setCookie(for webView: WKWebView, name: String, value: String, domain: String, path: String = "/", isSecure: Bool = false) {
        var properties: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: value,
            .domain: domain,
            .path: path,
        ]
        
        if isSecure {
            properties[.secure] = "TRUE"
        }
        
        if let cookie = HTTPCookie(properties: properties) {
            if #available(iOS 14.0, *) {
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            } else {
                cookieStore.setCookie(cookie)
            }
        }
    }
    
    // MARK: - 쿠키 가져오기
    
    /// 웹뷰에서 쿠키 가져오기
    func getCookies(for webView: WKWebView, domain: String? = nil) -> Observable<[HTTPCookie]> {
        return Observable.create { observer in
            let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
            
            cookieStore.getAllCookies { cookies in
                var filteredCookies = cookies
                
                // 특정 도메인의 쿠키만 필터링
                if let domain = domain {
                    filteredCookies = cookies.filter { $0.domain.contains(domain) }
                }
                
                observer.onNext(filteredCookies)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - 쿠키 삭제
    
    /// 웹뷰 쿠키 삭제
    func deleteCookies(for webView: WKWebView, domain: String? = nil) -> Observable<Void> {
        return Observable.create { observer in
            let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
            
            cookieStore.getAllCookies { cookies in
                let dispatchGroup = DispatchGroup()
                var cookiesToDelete = cookies
                
                // 특정 도메인의 쿠키만 필터링
                if let domain = domain {
                    cookiesToDelete = cookies.filter { $0.domain.contains(domain) }
                }
                
                // 각 쿠키 삭제
                for cookie in cookiesToDelete {
                    dispatchGroup.enter()
                    cookieStore.delete(cookie) {
                        dispatchGroup.leave()
                    }
                }
                
                // 모든 쿠키 삭제 완료 대기
                dispatchGroup.notify(queue: .main) {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - 쿠키 문자열 생성
    
    /// 요청 헤더에 포함할 쿠키 문자열 생성
    func cookieString(for cookies: [HTTPCookie]) -> String {
        return cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
    }
    
    /// 쿠키 헤더를 포함한 URLRequest 생성
    func requestWithCookies(request: URLRequest, cookies: [HTTPCookie]) -> URLRequest {
        var mutableRequest = request
        
        if !cookies.isEmpty {
            let headerFields = HTTPCookie.requestHeaderFields(with: cookies)
            for (field, value) in headerFields {
                mutableRequest.addValue(value, forHTTPHeaderField: field)
            }
        }
        
        return mutableRequest
    }
    
    // MARK: - 공유 쿠키 관리
    
    /// HTTPCookieStorage와 WKHTTPCookieStore 간 쿠키 동기화
    func synchronizeCookies(webView: WKWebView, completion: (() -> Void)? = nil) {
        if #available(iOS 14.0, *) {
            let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
            
            cookieStore.getAllCookies { cookies in
                // WKHTTPCookieStore의 쿠키를 HTTPCookieStorage에 복사
                for cookie in cookies {
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
                
                // HTTPCookieStorage의 쿠키를 WKHTTPCookieStore에 복사
                for cookie in HTTPCookieStorage.shared.cookies ?? [] {
                    cookieStore.setCookie(cookie)
                }
                
                completion?()
            }
        } else {
            completion?()
        }
    }
    
    /// 모든 쿠키 삭제 (디버깅용)
    func clearAllCookies() -> Observable<Void> {
        return Observable.create { observer in
            // HTTPCookieStorage 쿠키 삭제
            if let cookies = HTTPCookieStorage.shared.cookies {
                for cookie in cookies {
                    HTTPCookieStorage.shared.deleteCookie(cookie)
                }
            }
            
            // WKWebsiteDataStore 쿠키 삭제
            let dataTypes = Set([WKWebsiteDataTypeCookies])
            let date = Date(timeIntervalSince1970: 0)
            
            WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: date) {
                observer.onNext(())
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
}
