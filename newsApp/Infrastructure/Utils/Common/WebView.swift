//
//  WebView.swift
//  newsApp
//
//  Created by hkcom on 2021/10/26.
//  Copyright © 2021 hkcom. All rights reserved.
//

import WebKit

let sharedWKProcessPool = WKProcessPool()

func createWebView() -> WKWebView {
    
    
    let preferences = WKPreferences()
    preferences.javaScriptCanOpenWindowsAutomatically = true
    preferences.setValue(false, forKey: "developerExtrasEnabled")
    
    
    let configuration = WKWebViewConfiguration()
    configuration.preferences = preferences
    configuration.processPool = sharedWKProcessPool
    if #available(iOS 13.0, *) {
        configuration.defaultWebpagePreferences.preferredContentMode = .mobile
    }
    
    let userAgent:String = configuration.applicationNameForUserAgent ?? "Mobile/15E148"
    
    configuration.applicationNameForUserAgent = " Version/14.0.1 \(userAgent) Safari/604.1 appos/iOS appinfo/HKAPP_I appversion/\(appVersion) appdevice/\(deviceType)"
    
    let webView = WKWebView(frame: .zero, configuration: configuration)
    
    webView.isOpaque = false
    
    if #available(iOS 16.4, *) {
        #if DEBUG
        webView.isInspectable = true
        #endif
    }
    
    return webView
    
}


func createNewWebView() -> WKWebView {
    
    
    let preferences = WKPreferences()
    preferences.javaScriptCanOpenWindowsAutomatically = true
    preferences.setValue(false, forKey: "developerExtrasEnabled")
    
    
    let configuration = WKWebViewConfiguration()
    configuration.preferences = preferences
    configuration.processPool =  WKProcessPool()
    if #available(iOS 13.0, *) {
        configuration.defaultWebpagePreferences.preferredContentMode = .mobile
    }
    
    let userAgent:String = configuration.applicationNameForUserAgent ?? "Mobile/15E148"
    
    configuration.applicationNameForUserAgent = " Version/14.0.1 \(userAgent) Safari/604.1 appos/iOS appinfo/HKAPP_I appversion/\(appVersion) appdevice/\(deviceType)"
    
    let webView = WKWebView(frame: .zero, configuration: configuration)
    
    webView.isOpaque = false
    
    return webView
}

let commonWebView: WKWebView = createWebView()

func createCookie(name: String, value: String) {
    
    let propertie: [HTTPCookiePropertyKey : Any] = [
        .domain: ".hankyung.com",
        .path: "/",
        .name: name,
        .value: value
    ]
    
    let cookie = HTTPCookie(properties: propertie)!
    
//    commonWebView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
//    HTTPCookieStorage.shared.setCookie(cookie)
    
}

func deleteCookie(name: String) {
    
//    let propertie: [HTTPCookiePropertyKey : Any] = [
//        .domain: ".hankyung.com",
//        .path: "/",
//        .name: name,
//        .value: ""
//    ]
//
//    let cookie = HTTPCookie(properties: propertie)!
//
//    commonWebView.configuration.websiteDataStore.httpCookieStore.delete(cookie)
//    HTTPCookieStorage.shared.deleteCookie(cookie)
    
    
}

func deleteLoginCookie() {
    commonWebView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
        for cookie in cookies {
            commonWebView.configuration.websiteDataStore.httpCookieStore.delete(cookie)
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
        
        // 완료 후 리로드
        DispatchQueue.main.async {
            commonWebView.reload()
            print("✅ 모든 쿠키 삭제 완료")
        }
    }
}
