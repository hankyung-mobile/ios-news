//
//  PdfWebViewController.swift
//  newsApp
//
//  Created by InTae Gim on 2023/10/12.
//  Copyright © 2023 hkcom. All rights reserved.
//

import Foundation
import UIKit
@preconcurrency import WebKit

class PdfWebViewViewController: UIViewController {
    
    var webView: WKWebView!
    
    var closeButton = UIButton()
    
    let indicator = UIActivityIndicatorView()
    
    var pdfUrl:String = ""
    
    override func loadView() {
        super.loadView()

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // webview
        self.webView = createWebView()
        
        self.webView.uiDelegate = self
        self.webView.navigationDelegate = self
        
        self.view.addSubview(self.webView)
        
        
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor).isActive = true
        self.webView.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor).isActive = true
        self.webView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        self.webView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        self.webView.scrollView.bounces = false
        
        // indicator
        self.view.addSubview(self.indicator)
        self.indicator.translatesAutoresizingMaskIntoConstraints = false
        self.indicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.indicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        if #available(iOS 13.0, *) {
            self.indicator.style = .large
        }
        
        // close button
        self.view.addSubview(self.closeButton)
        
        self.closeButton.translatesAutoresizingMaskIntoConstraints = false
        self.closeButton.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        self.closeButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true

        let closeImage = UIImage(named: "close-circle-40")
        self.closeButton.setImage(closeImage, for: .normal)
        
        self.closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        
        guard let url = URL(string: self.pdfUrl) else {
            self.presentingViewController?.dismiss(animated: false)
            return
        }
        
        let request = URLRequest(url: url)
        
        DispatchQueue.main.async {
            self.webView.load(request)
        }
        
    }
    
    @objc func close() {
        self.presentingViewController?.dismiss(animated: true)
    }
}


extension PdfWebViewViewController: WKUIDelegate {
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

extension PdfWebViewViewController: WKNavigationDelegate {
    
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
        
        guard mainDocumentURL == self.pdfUrl else {
            decisionHandler(.cancel)
            self.presentingViewController?.dismiss(animated: false)
            return
        }
        
        decisionHandler(.allow)

    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.indicator.startAnimating()
    }
    
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.indicator.stopAnimating()
    }
    
    
    
}
