//
//  NewsViewController.swift
//  newsApp
//
//  Created by hkcom on 2020/07/24.
//  Copyright © 2020 hkcom. All rights reserved.
//
import Foundation
import UIKit
@preconcurrency import WebKit
import AppTrackingTransparency
import FirebaseAnalytics

class NewsViewController: UIViewController {
    
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var networkView: UIView!
    @IBOutlet weak var homeButton: UIButton!
    
    
    var webView: WKWebView!
    
    var isShowHomeButton:Bool = false
    var goMainUrl:String = SITEURL
    var trackingAuthorizationCheck:Bool = true
    
    override func loadView() {
        super.loadView()
        newsViewController = self

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView = createWebView()
        
        self.webView.uiDelegate = self
        self.webView.navigationDelegate = self
        
        self.contentView.addSubview(self.webView)
        
        // webview 레이아웃
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor).isActive = true
        self.webView.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor).isActive = true
        self.webView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        self.webView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true


        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshWebView(_:)), for: UIControl.Event.valueChanged)

        self.webView.scrollView.addSubview(refreshControl)
        self.webView.scrollView.bounces = true
        
        self.webView.configuration.userContentController.add(self, name: "imageView")
        self.webView.configuration.userContentController.add(self, name: "getUserInfo")
        self.webView.configuration.userContentController.add(self, name: "hankyunggascriptCallbackHandler")
        self.webView.configuration.userContentController.add(self, name: "getAnalyticsInstanceId")
        
        
        let script = WKUserScript(source: "window.close = function() { window.webkit.messageHandlers.close.postMessage('close') }", injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
        self.webView.configuration.userContentController.addUserScript(script)
        self.webView.configuration.userContentController.add(self, name: "close")
        
        self.webView.allowsBackForwardNavigationGestures = true


        guard UserDefaults.standard.value(forKey: "masterInfo") != nil else {
            return
        }
        let masterInfo: Dictionary<String, Any> = UserDefaults.standard.dictionary(forKey: "masterInfo")!
        
        if let ad: Array<String> = masterInfo["acceptedDomain"] as? Array<String> {
            acceptedDomain = ad
        }
        
        if let ed: Array<String> = masterInfo["externalDomain"] as? Array<String> {
            externalDomain = ed
        }

        
        // 전면광고
        if masterInfo["adFullShow"] as! Bool {
            let dateFormat = DateFormatter()
            dateFormat.dateFormat = "yyyy-MM-dd"
            
            let mainFullAdStopDay: String? = UserDefaults.standard.string(forKey: "isMainFullAdStopDay")
            if mainFullAdStopDay == nil || dateFormat.string(from: Date()) != mainFullAdStopDay {
                
                if #available(iOS 14, *) {
                    if ATTrackingManager.trackingAuthorizationStatus != .notDetermined {
                        loadFullAd()
                    }
                } else {
                    loadFullAd()
                }
            }
        }
        
        if(pushArticleUrl.isEmpty){
            DispatchQueue.main.async {
                let url = URL(string:SITEURL)
                let request = URLRequest(url: url!)
                self.webView.load(request)
            }
        }else{
            DispatchQueue.main.async {
                let url = URL(string:pushArticleUrl)
                let request = URLRequest(url: url!)
                pushArticleUrl = ""
                self.webView.load(request)
            }
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {

    }
    
    override func viewDidLayoutSubviews() {

    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if #available(iOS 14, *), trackingAuthorizationCheck {
            trackingAuthorizationCheck = false
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                ATTrackingManager.requestTrackingAuthorization { (status) in
                    
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {}
    
    override func viewDidDisappear(_ animated: Bool) {}
    
    func loadFullAd() {
        let bound: CGRect = CGRect(x:0, y:0, width:320, height:480)
        let adnextDynamicAdView: AdnextDynamicAdView = AdnextDynamicAdView.init(frame: bound)
        
        adnextDynamicAdView.setRequestAdStateHandler { (state) in
            
            if state == .receivedAd {
                //광고를 받으면 호출
                guard let favc = self.storyboard!.instantiateViewController(withIdentifier: "FullAdViewController") as? FullAdViewController else {
                    return
                }
                
                favc.banner = adnextDynamicAdView
                self.present(favc, animated: true)
            }
        }
        adnextDynamicAdView.startBannerRequest(withAdnextKey: adnextSdkKey, bannerSize: CGSize(width: 320, height: 480))
    }
    
    @objc func refreshWebView(_ sender: UIRefreshControl) {
        webView.reload()
        sender.endRefreshing()
    }
    
    @IBAction func networkReload(_ sender: Any) {
        self.webView.reload()
    }
    
    func checkNetworkMessage() {
        guard Reachability.isConnectedToNetwork() else {
            self.networkView.isHidden = false
            return
        }
        self.networkView.isHidden = true
    }
    
    @IBAction func goMain(_ sender: UIButton) {
        let url = URL(string:self.goMainUrl)
        let request = URLRequest(url: url!)
        self.webView.load(request)
    }
    
    func reload() {
        let url = URL(string:self.goMainUrl)
        let request = URLRequest(url: url!)
        self.webView.load(request)
    }
    
}

extension NewsViewController: WKUIDelegate {
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

extension NewsViewController: WKNavigationDelegate {
    
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
        
        guard navigationAction.request.url?.scheme == "https" || navigationAction.request.url?.scheme == "http" else {
            decisionHandler(.cancel)
            UIApplication.shared.open(navigationAction.request.url!, options: [:])
            return
        }

        if mainDocumentURL != loadURL && navigationAction.navigationType != WKNavigationType.linkActivated {
            decisionHandler(.allow)
            return
        }
        
        // 홈버튼 숨김
        self.isShowHomeButton = false
        
        let index = loadURL.firstIndex(of: "?") ?? loadURL.endIndex
        let hostpath = loadURL[..<index]
        let checkUrl = String(hostpath)
        
        
        if (checkUrl.contains("shift") && checkUrl.contains("hankyung.com"))
            || checkUrl.contains("amplifyapp.com")
            || checkUrl.contains("klipwallet.com")
        {
            self.isShowHomeButton = true
            self.goMainUrl = "\(SITEURL)/klay"
        } else {
            self.goMainUrl = SITEURL
        }
        
        
        let urlType = checkUrlPattern(url: checkUrl)
        
        
        if urlType == "plusMain" {
            decisionHandler(.cancel)
            
            let appURL: URL = URL(string: "hkplus://plus")!
            if UIApplication.shared.canOpenURL(appURL) {
                UIApplication.shared.open(appURL, options: [:])
            }else {
                UIApplication.shared.open(navigationAction.request.url!, options: [:])
            }
            return
        }
            
        if urlType == "login" {
            decisionHandler(.cancel)
            
            let accountView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AccountViewController") as! AccountViewController

            accountView.accountViewType = "login"

            accountView.modalTransitionStyle = UIModalTransitionStyle.coverVertical
            self.present(accountView, animated: true, completion: nil)
            
            return
        } else if urlType == "logout" {
            decisionHandler(.cancel)
            
            let logoutView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LogoutViewController") as! LogoutViewController
            self.present(logoutView, animated: false)

            return
        } else if urlType == "join" {
            decisionHandler(.cancel)
            
            let accountView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AccountViewController") as! AccountViewController

            accountView.accountViewType = "join"

            accountView.modalTransitionStyle = UIModalTransitionStyle.coverVertical
            self.present(accountView, animated: true, completion: nil)
            
            return
            
        } else if urlType == "accountInfo" {
            decisionHandler(.cancel)
            
            let accountView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AccountViewController") as! AccountViewController

            accountView.accountViewType = "accountInfo"

            accountView.modalTransitionStyle = UIModalTransitionStyle.coverVertical
            self.present(accountView, animated: true, completion: nil)
            
            return
        }
        
        
        if urlType == "pdf" {
            decisionHandler(.cancel)
            
            guard let pvc = self.storyboard?.instantiateViewController(withIdentifier: "PdfWebViewViewController") as? PdfWebViewViewController else {
                return
            }
            pvc.pdfUrl = loadURL
            self.present(pvc, animated: true)
            return
        }

        
        //앱내에서 호출 할 외부 도메인
        if acceptedDomain.count > 0 {
            for url in acceptedDomain {
                if checkUrl.contains(url) {
                    self.isShowHomeButton = true
                    decisionHandler(.allow)
                    return
                }
            }
        }
        
        if externalDomain.count > 0 {
            for url in externalDomain {
                if checkUrl.contains(url) {
                    decisionHandler(.cancel)
                    UIApplication.shared.open(navigationAction.request.url!, options: [:])
                    return
                }
            }
        }

        guard urlType != "other" else {
            decisionHandler(.cancel)
            UIApplication.shared.open(navigationAction.request.url!, options: [:])
            return
        }
        
        decisionHandler(.allow)

    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {

    }
    
    
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {

    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if self.isShowHomeButton {
            self.homeButton.isHidden = false
        } else {
            self.homeButton.isHidden = true
        }
        checkNetworkMessage()
        
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.url?.absoluteString == breakingNewsUrl {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        checkNetworkMessage()
    }
}

extension NewsViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "imageView" {
            guard let ivc = self.storyboard?.instantiateViewController(withIdentifier: "ImageViewController") as? ImageViewController else {
                return
            }
            let src:String = message.body as! String
            ivc.src = src
            self.present(ivc, animated: false)
        }
        else if message.name == "close" {
            if self.webView.canGoBack {
                self.webView.goBack()
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
        else if message.name == "getAnalyticsInstanceId" {
            self.callJSmakeRecommendNews(Analytics.appInstanceID() ?? "")
        }

    }
    
    func callJSmakeRecommendNews(_ instansid: String){
        let script = "window.makeRecommendNews('\(instansid)')"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
}

extension NewsViewController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.panGestureRecognizer.translation(in: scrollView).y < 0 {
            changeTabBar(hidden: true, animated: true)
        }else{
            changeTabBar(hidden: false, animated: true)
        }

    }
    
    func changeTabBar(hidden:Bool, animated: Bool){
        guard let tabBar = self.tabBarController?.tabBar else { return }
        if tabBar.isHidden == hidden{ return }
        let frame = tabBar.frame
        let offset = hidden ? frame.size.height : -frame.size.height
        let duration:TimeInterval = (animated ? 0.5 : 0.0)
        tabBar.isHidden = false

        UIView.animate(withDuration: duration, animations: {
            tabBar.frame = frame.offsetBy(dx: 0, dy: offset)
        }, completion: { (true) in
            tabBar.isHidden = hidden
        })
    }
}
