//
//  LoginWebViewController.swift
//  newsApp
//
//  Created by InTae Gim on 2023/02/06.
//  Copyright © 2023 hkcom. All rights reserved.
//

import Foundation
import UIKit
@preconcurrency import WebKit

class AccountViewController:UIViewController {
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    var webView:WKWebView!
    
    var accountViewType:String?
    
    // Completion handler 프로퍼티
    var onDismiss: (() -> Void)?
    
    override func loadView() {
        super.loadView()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.setBackgroundImage(UIImage(), for:.default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.layoutIfNeeded()
        
        self.webView = createWebView()

        self.webView.uiDelegate = self
        self.webView.navigationDelegate = self
        
        self.contentView.addSubview(self.webView)
        
        self.webView.translatesAutoresizingMaskIntoConstraints = false

        
        self.webView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor).isActive = true
        self.webView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true
        self.webView.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        self.webView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        
        
        guard accountViewType != nil else {
            self.presentingViewController?.dismiss(animated: true)
            return
        }
        
        guard let accountURL = returnAccountURL(accountViewType ?? "") else {
            self.presentingViewController?.dismiss(animated: true)
            return
        }
        
        
        self.webView.configuration.userContentController.add(self, name: "hankyunggascriptCallbackHandler")
        
        // 로그인 정보
        self.webView.configuration.userContentController.add(self, name: "accountResult")
        
        // 취소 또는 닫기 버튼
        let script = WKUserScript(source: "window.close = function() { window.webkit.messageHandlers.close.postMessage('close') }", injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
        self.webView.configuration.userContentController.addUserScript(script)
        self.webView.configuration.userContentController.add(self, name: "close")
        
        
        let url = URL(string: accountURL)
//        let url = URL(string:"https://member.hankyung.com/apps.frame/common_dev.login?site=webview.hankyung.com&user_agent=app")
        var request = URLRequest(url: url!)
        
        let parameter = returnAccountParameterForLogin()
        
        // 로그인된 상태에서 로그인 또는 회원가입 경로로 들어왔을 경우
        if (self.accountViewType == "login" || self.accountViewType == "join") && UserDefaults.standard.bool(forKey: "_ISLOGIN") {
            // 로그아웃 처리
            deleteLoginData()
        }
        
        if self.accountViewType == "accountInfo" || self.accountViewType == "join" {
            
            let paramString = (parameter.compactMap({ (key, value) -> String in return "\(key)=\(value)" }) as Array).joined(separator: "&")
            
            
            for (key, value) in parameter {
                request.setValue(value, forHTTPHeaderField: key)
            }
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = paramString.data(using: .utf8)
            
        }
        
        self.webView.load(request)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {

        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.webView.configuration.userContentController.removeScriptMessageHandler(forName: "accountResult")
        self.webView.configuration.userContentController.removeScriptMessageHandler(forName: "close")
        self.webView.configuration.userContentController.removeAllUserScripts()
        
        if
            tabBarViewController?.selectedIndex == 1,
            let nvc = tabBarViewController?.selectedViewController as? UINavigationController,
            let stvc = nvc.topViewController as? SettingTableViewController
        {
            stvc.reloadLoginCell()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
                onDismiss?()
                onDismiss = nil
        }
    
    @IBAction func closeView(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    private func handleLoginSuccess() {
         print("🔥 로그인 성공, 전체 알림 발송")
         NotificationCenter.default.post(name: .loginSuccess, object: nil)
         dismiss(animated: true)
     }
     
     private func handleLogoutSuccess() {
         print("🔥 로그아웃 성공, 전체 알림 발송")
         NotificationCenter.default.post(name: .logoutSuccess, object: nil)
         dismiss(animated: true)
     }
    
}


extension AccountViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Swift.Void){
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let otherAction = UIAlertAction(title: "확인", style: .default, handler: {action in completionHandler()})
        alert.addAction(otherAction)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Swift.Void){
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: {(action) in completionHandler(false)})
        let okAction = UIAlertAction(title: "확인", style: .default, handler: {(action) in completionHandler(true)})
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension AccountViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let mainDocumentURL = navigationAction.request.mainDocumentURL?.absoluteString else {
            decisionHandler(.cancel)
            return
        }

        guard let loadURL = navigationAction.request.url?.absoluteString else {
            decisionHandler(.cancel)
            return
        }
        
        if loadURL == "about:blank" {
            decisionHandler(.allow)
            return
        }
        
        if let url = navigationAction.request.url , ["kakaolink"].contains(url.scheme) {

            // 카카오톡 실행 가능 여부 확인 후 실행
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }

            decisionHandler(.cancel)
            return
        }
        
        
        guard navigationAction.request.url?.scheme == "https" || navigationAction.request.url?.scheme == "http" else {
            decisionHandler(.cancel)
            UIApplication.shared.open(navigationAction.request.url!, options: [:])
            return
        }

        if mainDocumentURL != loadURL && navigationAction.navigationType != WKNavigationType.linkActivated {
            decisionHandler(.allow)
            return
        }
        
        let index = loadURL.firstIndex(of: "?") ?? loadURL.endIndex
        let hostpath = loadURL[..<index]
        let checkUrl = String(hostpath)
        
        if checkHKSite(url: checkUrl) == "www" && !checkUrl.contains("app-data/auth-callback") {
            
//            if tabBarViewController?.selectedIndex != 0 {
//                tabBarViewController?.selectedIndex = 0
//            }
            
            self.presentingViewController?.dismiss(animated: true)
            
            decisionHandler(.cancel)
            return
        }
        
        if externalDomain.count > 0 {
            for url in externalDomain {
                if checkUrl.contains("/login/joinPage.do") {
                    continue
                }
                if checkUrl.contains(url) {
                    decisionHandler(.cancel)
                    UIApplication.shared.open(navigationAction.request.url!, options: [:])
                    return
                }
            }
        }
        
        decisionHandler(.allow)
        
    }
    
    
}


extension AccountViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if message.name == "close" {
            self.presentingViewController?.dismiss(animated: true)
        }
        else if message.name == "accountResult" {
            
            let body = message.body
            
            guard let dictionary = body as? [String: Any] else {
                
                let msg = "오류가 발생했습니다. 다시 시도해 주세요."

                let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "확인", style: .default, handler: nil)
                alert.addAction(defaultAction)

                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: {
                        self.presentingViewController?.dismiss(animated: true)
                    })
                }
                return
            }
            
            let type = dictionary["type"] as? String ?? ""
            
            if type == "login" {
                self.loginCallback(dictionary)
            } else if type == "mypage" {
                self.accountInfoCallback(dictionary)
            }
        }
        else if message.name == "hankyunggascriptCallbackHandler" {
            
            let ga4 = GA4()
            
            do {
                try ga4.hybridData(message: message)
            } catch {
                print("Error: \(error)")
            }
        }
    }
}


extension AccountViewController {
    
    // 로그인
    func loginCallback(_ dictionary:Dictionary<String,Any>) {
        
        let code = dictionary["code"] as? String ?? ""
        let data = dictionary["data"] as? Dictionary<String, Any> ?? [:]
        
        guard code == "0000" else {
            
            let msg = "오류가 발생했습니다.(\(code))"

            let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "확인", style: .default, handler: nil)
            alert.addAction(defaultAction)

            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: {
                    self.presentingViewController?.dismiss(animated: true)
                })
            }
            return
        }

        // 로그인 데이터 및 쿠키 저장
        saveLoginData(data: data)

        DispatchQueue.main.async {
            self.presentingViewController?.dismiss(animated: true)
            self.handleLoginSuccess()
        }
    }

    // 내 계정 정보 보기
    func accountInfoCallback(_ dictionary:Dictionary<String,Any>) {
        
        let code = dictionary["code"] as? String ?? ""
        let handlingCode = dictionary["handling"] as? String ?? ""
        
        guard code == "0000" else {
            self.presentingViewController?.dismiss(animated: true)
            return
        }
        
        // 0900: 회원탈퇴, 0410: 마케팅 동의 변경, 0400: 비밀번호 변경
        
        if handlingCode == "0900" {
            
            // 로그아웃 처리
            deleteLoginData()
            
            DispatchQueue.main.async {
                self.handleLogoutSuccess()
            }
        }
        
        if handlingCode == "0420" {
            self.presentingViewController?.dismiss(animated: true)
            return
        }
        
        self.presentingViewController?.dismiss(animated: true)
    }
    
}


