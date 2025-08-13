//
//  JSBridgeManager.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import WebKit
import RxSwift

/// JavaScript <-> Native 통신을 위한 브릿지 관리자
class JSBridgeManager {
    // 자바스크립트 핸들러 맵
    private var jsHandlers = [WKWebView: [String: (Any) -> Any?]]()
    
    // 통신을 위한 메시지 핸들러 이름
    private let nativeMessageHandlerName = "nativeApp"
    
    // MARK: - 초기화 및 설정
    
    /// 웹뷰 컨트롤러에 기본 브릿지 핸들러 등록
    func registerBridgeHandlers(for contentController: WKUserContentController) {
        // 네이티브 메시지 핸들러 등록
        let messageHandler = BridgeMessageHandler(manager: self)
        contentController.add(messageHandler, name: nativeMessageHandlerName)
        
        // 자바스크립트 브릿지 인터페이스 주입
        if let bridgeScript = createBridgeScript() {
            let userScript = WKUserScript(
                source: bridgeScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
            contentController.addUserScript(userScript)
        }
    }
    
    /// 자바스크립트 브릿지 스크립트 생성
    private func createBridgeScript() -> String? {
        return """
        // 네이티브 브릿지 객체 정의
        window.NativeBridge = {
            // 네이티브로 메시지 전송
            callNative: function(handlerName, data, callback) {
                // ID 생성
                var callbackId = 'cb_' + Date.now() + '_' + Math.floor(Math.random() * 1000);
                
                // 콜백 저장
                if (typeof callback === 'function') {
                    window.NativeBridge._callbacks = window.NativeBridge._callbacks || {};
                    window.NativeBridge._callbacks[callbackId] = callback;
                }
                
                // 메시지 객체 생성
                var message = {
                    handlerName: handlerName,
                    data: data || {},
                    callbackId: callback ? callbackId : null
                };
                
                // 네이티브로 메시지 전송
                window.webkit.messageHandlers.\(nativeMessageHandlerName).postMessage(message);
            },
            
            // 네이티브 이벤트 리스너 등록
            on: function(eventName, listener) {
                window.NativeBridge._eventListeners = window.NativeBridge._eventListeners || {};
                window.NativeBridge._eventListeners[eventName] = window.NativeBridge._eventListeners[eventName] || [];
                window.NativeBridge._eventListeners[eventName].push(listener);
            },
            
            // 네이티브 이벤트 리스너 제거
            off: function(eventName, listener) {
                if (!window.NativeBridge._eventListeners || !window.NativeBridge._eventListeners[eventName]) {
                    return;
                }
                
                if (!listener) {
                    // 모든 리스너 제거
                    delete window.NativeBridge._eventListeners[eventName];
                } else {
                    // 특정 리스너만 제거
                    window.NativeBridge._eventListeners[eventName] = window.NativeBridge._eventListeners[eventName].filter(
                        function(l) { return l !== listener; }
                    );
                }
            },
            
            // 네이티브에서 이벤트 수신 (네이티브에서 호출됨)
            _receiveEvent: function(eventName, data) {
                if (!window.NativeBridge._eventListeners || !window.NativeBridge._eventListeners[eventName]) {
                    return;
                }
                
                window.NativeBridge._eventListeners[eventName].forEach(function(listener) {
                    listener(data);
                });
            },
            
            // 네이티브에서 콜백 수신 (네이티브에서 호출됨)
            _handleCallback: function(callbackId, data, error) {
                if (!window.NativeBridge._callbacks || !window.NativeBridge._callbacks[callbackId]) {
                    return;
                }
                
                var callback = window.NativeBridge._callbacks[callbackId];
                callback(error, data);
                
                // 콜백 제거
                delete window.NativeBridge._callbacks[callbackId];
            }
        };
        
        // 하위 호환성 지원
        window.webkit = window.webkit || {};
        window.webkit.messageHandlers = window.webkit.messageHandlers || {};
        """
    }
    
    // MARK: - 네이티브 핸들러 등록 및 관리
    
    /// 네이티브 핸들러 등록 (자바스크립트에서 호출 가능)
    func registerNativeHandler(for webView: WKWebView, handlerName: String, handler: @escaping (Any) -> Any?) {
        if jsHandlers[webView] == nil {
            jsHandlers[webView] = [:]
        }
        
        jsHandlers[webView]?[handlerName] = handler
    }
    
    /// 네이티브 핸들러 호출 (자바스크립트에서 호출됨)
    func callNativeHandler(for webView: WKWebView, handlerName: String, data: Any, callbackId: String?) -> Any? {
        guard let handler = jsHandlers[webView]?[handlerName] else {
            return nil
        }
        
        let result = handler(data)
        
        // 콜백 호출 (있는 경우)
        if let callbackId = callbackId {
            handleCallback(for: webView, callbackId: callbackId, result: result, error: nil)
        }
        
        return result
    }
    
    /// 콜백 처리 (자바스크립트로 결과 전달)
    private func handleCallback(for webView: WKWebView, callbackId: String, result: Any?, error: Error?) {
        var errorObj: [String: Any]? = nil
        
        if let error = error {
            errorObj = [
                "message": error.localizedDescription,
                "code": (error as NSError).code
            ]
        }
        
        // 자바스크립트 콜백 함수 호출
        let script = """
        window.NativeBridge._handleCallback(
            '\(callbackId)',
            \(jsonString(from: result) ?? "null"),
            \(jsonString(from: errorObj) ?? "null")
        );
        """
        
        webView.evaluateJavaScript(script) { _, _ in }
    }
    
    // MARK: - 이벤트 발생 (네이티브 -> 자바스크립트)
    
    /// 네이티브 이벤트 발생 (자바스크립트에 알림)
    func emitNativeEvent(to webView: WKWebView, eventName: String, data: [String: Any]) -> Observable<Void> {
        return Observable.create { observer in
            // 자바스크립트 이벤트 수신 함수 호출
            let script = """
            window.NativeBridge._receiveEvent(
                '\(eventName)',
                \(self.jsonString(from: data) ?? "{}")
            );
            """
            
            webView.evaluateJavaScript(script) { _, error in
                if let error = error {
                    print("⚠️ JS 이벤트 발생 오류: \(error.localizedDescription)")
                    observer.onError(error)
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - 유틸리티
    
    /// 객체를 JSON 문자열로 변환
    private func jsonString(from object: Any?) -> String? {
        guard let object = object else { return nil }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: object, options: [])
            return String(data: data, encoding: .utf8)
        } catch {
            print("⚠️ JSON 변환 오류: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 웹뷰 해제 시 핸들러 제거
    func removeHandlers(for webView: WKWebView) {
        jsHandlers.removeValue(forKey: webView)
    }
}

// MARK: - WKScriptMessageHandler 구현
class BridgeMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var manager: JSBridgeManager?
    
    init(manager: JSBridgeManager) {
        self.manager = manager
        super.init()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let webView = message.webView,
              let body = message.body as? [String: Any],
              let handlerName = body["handlerName"] as? String else {
            return
        }
        
        let data = body["data"]
        let callbackId = body["callbackId"] as? String
        
        // 네이티브 핸들러 호출
        manager?.callNativeHandler(for: webView, handlerName: handlerName, data: data ?? [:], callbackId: callbackId)
    }
}
