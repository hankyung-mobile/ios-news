//
//  WeakScriptMessageHandler.swift
//  newsApp
//
//  Created by jay on 5/21/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import WebKit

// 약한 참조를 사용하는 프록시 클래스
class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    
    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // delegate가 nil인지 확인하고 안전하게 호출
        guard let delegate = delegate else {
            print("WeakScriptMessageHandler: delegate is nil, ignoring message: \(message.name)")
            return
        }
        
        // 메인 스레드에서 실행되는지 확인
        if Thread.isMainThread {
            delegate.userContentController(userContentController, didReceive: message)
        } else {
            DispatchQueue.main.async {
                // delegate가 여전히 존재하는지 다시 확인
                guard let delegate = self.delegate else { return }
                delegate.userContentController(userContentController, didReceive: message)
            }
        }
    }
}
