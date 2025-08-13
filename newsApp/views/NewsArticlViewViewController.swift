//
//  NewsArticleViewViewController.swift
//  newsApp
//
//  Created by hkcom on 2020/08/24.
//  Copyright © 2020 hkcom. All rights reserved.
//

import Foundation
import UIKit
@preconcurrency import WebKit

class NewsArticlViewViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var titleView: UINavigationItem!
    
    
    var url: String = ""
    var viewTitleText = "알림"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            self.webView.configuration.defaultWebpagePreferences.preferredContentMode = .mobile
        }
        
        self.webView.uiDelegate = self
        self.webView.navigationDelegate = self
        
        self.webView.configuration.userContentController.add(self, name: "hankyunggascriptCallbackHandler")
        
        
        if #available(iOS 16.4, *) {
            #if DEBUG
            self.webView.isInspectable = true
            #endif
        }
        
        self.titleView.title = self.viewTitleText
        
        
        guard let url = URL(string: self.url) else { return }

        var request = URLRequest(url: url)
        request.setValue(hkAuthkey, forHTTPHeaderField: "authkey")
        
        self.webView.load(request)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }

    
    @IBAction func closeArticleView(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}


extension NewsArticlViewViewController: WKUIDelegate {
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


extension NewsArticlViewViewController: WKNavigationDelegate {
    
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

        if navigationAction.navigationType == WKNavigationType.linkActivated {

            
            if externalDomain.count > 0 {
                for url in externalDomain {
                    if mainDocumentURL.contains(url) {
                        UIApplication.shared.open(navigationAction.request.url!, options: [:])
                        decisionHandler(.cancel)
                        return
                    }
                }
            }
            
            let urlType = checkUrlPattern(url: mainDocumentURL)
            
            if urlType == "www" || urlType == "main" || urlType == "hk" {
                self.closeArticleView("")
                guard let tabbarViewControllers = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController else { return }
                tabbarViewControllers.selectedIndex = 0
                
                
                let url = URL(string:mainDocumentURL)
                let request = URLRequest(url: url!)
                
                DispatchQueue.main.async {
                    newsViewController.webView.load(request)
                }
                
                decisionHandler(.cancel)
                return
            }

            UIApplication.shared.open(navigationAction.request.url!, options: [:])
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)

    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.activityIndicator.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.activityIndicator.isHidden = true
    }
}

extension NewsArticlViewViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "hankyunggascriptCallbackHandler" {
            
            let ga4 = GA4()
            
            do {
                try ga4.hybridData(message: message)
            } catch {
                print("Error: \(error)")
            }
        }
    }
}
