//
//  resources.swift
//  newsApp
//
//  Created by hkcom on 14/05/2020.
//  Copyright © 2020 hkcom. All rights reserved.
//

import Foundation
import UIKit
import WebKit


var newsViewController: NewsViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NewsViewController") as! NewsViewController

var settingTableViewController: SettingTableViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingTableViewController") as! SettingTableViewController

var marketIndexViewController: MarketIndexViewController?

var tabBarViewController: TabBarController?

let masterUrl: String = "https://img.hankyung.com/pdsdata/mms.hankyung.com/news/config.json"
//let masterUrl: String = "https://mms.hankyung.com/hknews/data/app_setting/preview/config.json"

let SITEURL: String = "https://www.hankyung.com"
let MEMBERURL: String = "https://member.hankyung.com"

var mainUrl: String = SITEURL
let breakingNewsUrl: String = "\(SITEURL)/realtime"




var acceptedDomain: Array<String> = []
var externalDomain: Array<String> = []

var isFcmSubscribe: Bool = false

var pushArticleUrl: String = ""
var isArticlepushTouch: Bool = false

let currentServer = EnvironmentManager.shared.currentEnvironment


enum TopicName: String {
    case news = "hknews2024"
    case newsOld = "hknews.ios"
    case letterCFO = "hkletter.cfo.ios"
    case letterCHO = "hkletter.cho.ios"
    case letterGSR = "hkletter.gsr.ios"
    
    func toString() -> String {
        return self.rawValue
    }
}

enum IsNotificationKey: String {
    case all = "isAllNotification"
    case news = "isNotification"
    case letterCFO = "isLetterCFONotification"
    case letterCHO = "isLetterCHONotification"
    case letterGSR = "isLeeterGSRNotification"
    
    func toString() -> String {
        return self.rawValue
    }
}

let appStoreUrl: String = "itms-apps://itunes.apple.com/kr/app/id406614875?mt=8"

let adnextSdkKey = "5ba05cb80cf2475f6670deac"

let hkAuthkey = "7a04c8471b5850a07a47537ff309f0726e57ce9e2d9d081663a94de24ecaf6c7"

let xApiKey = "c8e5f276-46a1-4136-b112-55ad53d387fe"

var applicationDidEnterBackgroundTime: Date = Date()

var appVersion: String {
    guard let dictionary = Bundle.main.infoDictionary,
        let version = dictionary["CFBundleShortVersionString"] as? String else {return "4.10.3"}

    return version
}

var appBuild: String? {
    guard let dictionary = Bundle.main.infoDictionary,
        let build = dictionary["CFBundleVersion"] as? String else {return nil}
    
    return build
}

var osVersion: String {
    return UIDevice.current.systemVersion
}

var deviceType: String {
    
    if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
        return "pad"
    }
    return "phone"
}

let apiHeader: Dictionary = ["Content-Type":"application/json", "authkey":hkAuthkey, "User-Agent":"appinfo/HKAPP_I appversion/\(appVersion) device/\(deviceType)"]

extension CATransition {

    
    func segueFromBottom() -> CATransition {
        self.duration = 0.375
        self.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        self.type = CATransitionType.moveIn
        self.subtype = CATransitionSubtype.fromTop
        return self
    }
    
    func segueFromTop() -> CATransition {
        self.duration = 0.375
        self.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        self.type = CATransitionType.moveIn
        self.subtype = CATransitionSubtype.fromBottom
        return self
    }
    
    func segueFromLeft() -> CATransition {
        self.duration = 0.5
        self.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        self.type = CATransitionType.moveIn
        self.subtype = CATransitionSubtype.fromLeft
        return self
    }
    
    func popFromRight() -> CATransition {
        self.duration = 0.5
        self.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        self.type = CATransitionType.reveal
        self.subtype = CATransitionSubtype.fromRight
        return self
    }
    
    func popFromLeft() -> CATransition {
        self.duration = 0.5
        self.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        self.type = CATransitionType.reveal
        self.subtype = CATransitionSubtype.fromLeft
        return self
   }
}

func getCustomRequest(url: String) -> URLRequest{
    var encodingUrl: String = ""
    
    if let decodingUrl = url.removingPercentEncoding {
        encodingUrl = decodingUrl.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!
    }
    else {
        encodingUrl = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!
    }
    
    let url = URL(string: encodingUrl)
    
    var customRequest = URLRequest(url: url!)
    
    customRequest.httpShouldHandleCookies = true
    customRequest.addValue("HKAPP_I", forHTTPHeaderField: "appinfo")
    customRequest.addValue(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String, forHTTPHeaderField: "appversion")
    customRequest.addValue(UIDevice.current.systemVersion, forHTTPHeaderField: "osversion")
    
    return customRequest
}

func getCustomRequest(url: URL) -> URLRequest{
    
    var customRequest = URLRequest(url: url)
    
    customRequest.httpShouldHandleCookies = true
    customRequest.addValue("HKAPP_I", forHTTPHeaderField: "appinfo")
    customRequest.addValue(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String, forHTTPHeaderField: "appversion")
    customRequest.addValue(UIDevice.current.systemVersion, forHTTPHeaderField: "osversion")
    
    return customRequest
}

func masterDataDecode() -> Dictionary<String, Any> {
    
    var masterInfo: Dictionary<String, Any> = Dictionary()
    let masterURL: URL! = URL(string: masterUrl)
    
    do {
        let masterData: Data = try Data(contentsOf: masterURL)
        let master = try JSONSerialization.jsonObject(with: masterData, options: []) as! NSDictionary

        masterInfo["masterVersion"] = (master.object(forKey: "version") as? NSDictionary)?.object(forKey: "master") as? Int
        masterInfo["appVersion"] = ((master.object(forKey: "version") as? NSDictionary)?.object(forKey: "app") as? NSDictionary)?.object(forKey: "ios") as? String
        masterInfo["forceVersion"] = ((master.object(forKey: "version") as? NSDictionary)?.object(forKey: "force") as? NSDictionary)?.object(forKey: "ios") as? String
        masterInfo["mainUrl"] = (master.object(forKey: "main") as? NSDictionary)?.object(forKey: "url") as? String

        masterInfo["adFullShow"] = ((master.object(forKey: "advertising") as? NSDictionary)?.object(forKey: "full") as? NSDictionary)?.object(forKey: "show") as? Bool
        masterInfo["acceptedDomain"] = ((master.object(forKey: "accepted") as? NSDictionary)?.object(forKey: "domain") as? String)?.components(separatedBy: "\n")
        masterInfo["externalDomain"] = ((master.object(forKey: "external") as? NSDictionary)?.object(forKey: "domain") as? String)?.components(separatedBy: "\n")
        
        if masterInfo["masterVersion"] == nil {
            masterInfo = Dictionary()
        }
        
        
    } catch {
        // 마스터 데이터 호출 문제 발생
//        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
    }
    
    return masterInfo
}

func checkUrlPattern(url: String) -> String {
    var customUrl: String = ""
    
    if currentServer == .DEV {
        customUrl = "_dev"
    }
    
    do {
        //메인
        var regex = try NSRegularExpression(pattern: "^(http|https)://(stg-www\\.|www\\.)?hankyung\\.com(/?|\\?.*|/\\?.*)$")
        var matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "main"
        }
        
        //메뉴
        regex = try NSRegularExpression(pattern: "^(http|https)://(stg-www\\.|www\\.)?hankyung\\.com/hamburgermenu(/?|\\?.*|/\\?.*)$")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "menu"
        }
        
        //알림뷰
        regex = try NSRegularExpression(pattern: "^(http|https)://(stg-www\\.|www\\.)?hankyung\\.com/article/app(.+)?")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "appView"
        }
        
        // PDF
        regex = try NSRegularExpression(pattern: "^(http|https)://(stg-www|www|markets)\\.hankyung\\.com(.+)?/pdf/(.+)")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "pdf"
        }
        
        regex = try NSRegularExpression(pattern: "\\.pdf(\\?[^#]*)?(\\#.*)?$", options: .caseInsensitive)
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))

        if matchCheck > 0 {
            return "pdf"
        }
        
        //www
        regex = try NSRegularExpression(pattern: "^(http|https)://(stg-www\\.|www\\.)?hankyung\\.com(/?|\\?.*|/\\?.*)(.+)?")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "www"
        }
        
        //로그인
        //https://member.hankyung.com/apps.frame/login?url=https%3A//www.hankyung.com/
        regex = try NSRegularExpression(pattern: "^(http|https)://(stg-)?member\\.hankyung\\.com/apps.frame/common\(customUrl).login(/?|\\?.*|/\\?.*)$")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "login"
        }
        //https://id.hankyung.com/login/login.do
        regex = try NSRegularExpression(pattern: "^(http|https)://id\\.hankyung\\.com/login/login.do(\\?.*)?$")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "login"
        }
        
        
        //회원가입
        //https://member.hankyung.com/apps.frame/sso.join
        regex = try NSRegularExpression(pattern: "^(http|https)://(stg-)?member\\.hankyung\\.com/apps\\.frame/sso\\.join(\\?.*)?$")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "join"
        }
        
        regex = try NSRegularExpression(pattern: "^(http|https)://(stg-)?member\\.hankyung\\.com/apps.frame/common\(customUrl).join(/?|\\?.*|/\\?.*)$")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "join"
        }
        
        //https://id.hankyung.com/login/joinPage.do
        regex = try NSRegularExpression(pattern: "^(http|https)://id\\.hankyung\\.com/login/joinPage.do(\\?.*)?$")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "join"
        }
        
        
        //로그아웃
        //https://member.hankyung.com/apps.frame/login.work.logout?url=https%3A//www.hankyung.com/
        regex = try NSRegularExpression(pattern: "^(http|https)://(stg-)?member\\.hankyung\\.com/apps.frame/common\(customUrl).logout(/?|\\?.*|/\\?.*)$")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "logout"
        }
        
        //계정정보
        //https://member.hankyung.com/apps.frame/member.main?url=https%3A//www.hankyung.com/
        regex = try NSRegularExpression(pattern: "^(http|https)://(stg-)?member\\.hankyung\\.com/apps.frame/member.main(/?|\\?.*|/\\?.*)$")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "accountInfo"
        }
        
        //https://member.hankyung.com/apps.frame/common_dev.mypage/
        regex = try NSRegularExpression(pattern: "^(http|https)://(stg-)?member\\.hankyung\\.com/apps.frame/common\(customUrl).mypage(/?|\\?.*|/\\?.*)$")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "accountInfo"
        }

        
        //id
        regex = try NSRegularExpression(pattern: "^(http|https)://id\\.hankyung\\.com(/?|\\?.*|/\\?.*)(.+)?")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "id"
        }
        
        //플러스(모바일) 메인
        regex = try NSRegularExpression(pattern: "^(http|https)://(plus|mobile)\\.hankyung\\.com(/?|\\?.*|/\\?.*)$")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "plusMain"
        }
   
        regex = try NSRegularExpression(pattern: "^(http|https)://members\\.hankyung\\.com.*$")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))

        if matchCheck > 0 {
            return "member"
        }
        
        //한경
        regex = try NSRegularExpression(pattern: "^(http|https)://([a-zA-Z0-9]+\\.)?hankyung\\.com(/?|\\?.*|/\\?.*)(.+)?")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "hk"
        }
        
        // 컨센서스
        // consensus
        regex = try NSRegularExpression(pattern: "^(http|https)://[^/]+\\.hankyung\\.com/koreamarket/consensus(/?|/.*|\\?.*|/\\?.*)$")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))

        if matchCheck > 0 {
            return "consensus"
        }
        
        regex = try NSRegularExpression(pattern: "^(http|https)://[^/]+/esg/gx200(/?)(\\?.*)?$")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "consensus"
        }
        
        regex = try NSRegularExpression(pattern: "^(http|https)://[^/]+/politics/legi-explorer(/?)(\\?.*)?$")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "consensus"
        }
        
        regex = try NSRegularExpression(pattern: "^(http|https)://[^/]+/lawbiz/index-lawyer(/?)(\\?.*)?$")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "consensus"
        }
        
        // 하위 경로 포함 버전
        regex = try NSRegularExpression(pattern: "^(http|https)://(stg-)?webview\\.hankyung\\.com/game(/.*)?$")
        matchCheck = regex.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: (url as NSString).length))
        
        if matchCheck > 0 {
            return "consensus" // 또는 원하는 리턴값
        }
        
        //klay 이벤트
        

    } catch let error {
        print(error)
        return "error"
    }
    
    return "other"
}

func checkHKSite(url: String) -> String {
    
    let hkDomain = "hankyung.com"
    
    guard let url = URL(string: url), let host = url.host else {
        return "other"
    }
    
    if !host.hasSuffix(hkDomain) {
        return "other"
    }
    
    let domainWithoutTarget = host.replacingOccurrences(of: "." + hkDomain, with: "")
    
    if domainWithoutTarget.isEmpty {
        return "www"
    }
    
    return domainWithoutTarget

}

func sendData(request: URLRequest) {
    let session = URLSession.shared
    session.dataTask(with: request, completionHandler: { (data, response, error) in
        
    }).resume()
}

func sendDataRequest(url: String, dic: Dictionary<String, String>) -> URLRequest{
    let url = URL(string: url)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    let param = try! JSONSerialization.data(withJSONObject: dic, options: [])
    
    request.httpBody = param
    
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept-Type")
    
    return request
}

func sendFormDataRequest(url: String, dic:Dictionary<String, String>, header:Dictionary<String,String> = [:]) -> URLRequest {
    
    let url = URL(string: url)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    // URLComponents 생성
    var components = URLComponents()
    components.queryItems = dic.map { key, value in
        URLQueryItem(name: key, value: value)
    }

    // URL 문자열로 변환
    if let queryString = components.percentEncodedQuery {
        request.httpBody = queryString.data(using: .utf8)
    }
    
    
    header.forEach { key, value in
        request.setValue(value, forHTTPHeaderField: key)
    }
    
    return request
}


extension Notification.Name {
    static let articleWebViewLoadEvent = Notification.Name("articleWebViewLoadEvent")
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int, a: Int = 0xFF) {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: CGFloat(a) / 255.0
        )
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
    
    convenience init(argb: Int) {
        self.init(
            red: (argb >> 16) & 0xFF,
            green: (argb >> 8) & 0xFF,
            blue: argb & 0xFF,
            a: (argb >> 24) & 0xFF
        )
    }
}


class PaddingLabel: UILabel {
    
    var insets = UIEdgeInsets.zero
    
    func padding(_ top: CGFloat, _ bottom: CGFloat, _ left: CGFloat, _ right: CGFloat) {
        self.frame = CGRect(x: 0, y: 0, width: self.frame.width + left + right, height: self.frame.height + top + bottom)
        insets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
    
    override var intrinsicContentSize: CGSize {
        get {
            var contentSize = super.intrinsicContentSize
            contentSize.height += insets.top + insets.bottom
            contentSize.width += insets.left + insets.right
            return contentSize
        }
    }
}

extension CALayer {
    func addBorder(_ arr_edge: [UIRectEdge], color: UIColor, width: CGFloat) {
        for edge in arr_edge {
            let border = CALayer()
            switch edge {
            case UIRectEdge.top:
                border.frame = CGRect.init(x: 0, y: 0, width: frame.width, height: width)
                break
            case UIRectEdge.bottom:
                border.frame = CGRect.init(x: 0, y: frame.height - width, width: frame.width, height: width)
                break
            case UIRectEdge.left:
                border.frame = CGRect.init(x: 0, y: 0, width: width, height: frame.height)
                break
            case UIRectEdge.right:
                border.frame = CGRect.init(x: frame.width - width, y: 0, width: width, height: frame.height)
                break
            default:
                break
            }
            border.backgroundColor = color.cgColor;
            self.addSublayer(border)
        }
    }
}

extension URL {
    public var queryParameters: [String: String]? {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}

extension URL {
    func valueOf(_ queryParamaterName: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParamaterName })?.value
    }
}

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}

func returnAccountURL(_ type: String) -> String? {
    
    if currentServer == .DEV {
        let urlDictionary: Dictionary<String, String> = [
            "login":"\(MEMBERURL)/apps.frame/common_dev.login?site=webview.hankyung.com&user_agent=app",
            "join":"\(MEMBERURL)/apps.frame/common_dev.join?site=webview.hankyung.com",
            "accountInfo":"\(MEMBERURL)/apps.frame/common_dev.mypage",
            "logout":"\(MEMBERURL)/apps.frame/common_dev.logout.direct",
            "check":"\(MEMBERURL)/apps.frame/common_dev.check"
        ]
        
        return urlDictionary[type]
    }
    
    let urlDictionary: Dictionary<String, String> = [
        "login":"\(MEMBERURL)/apps.frame/common.login?site=webview.hankyung.com&user_agent=app",
        "join":"\(MEMBERURL)/apps.frame/common.join?site=webview.hankyung.com",
        "accountInfo":"\(MEMBERURL)/apps.frame/common.mypage",
        "logout":"\(MEMBERURL)/apps.frame/common.logout.direct",
        "check":"\(MEMBERURL)/apps.frame/common.check"
    ]
    
    return urlDictionary[type]
}

func returnAccountParameter(_ type: String) -> Dictionary<String,String> {
    
    guard let accountData = UserDefaults.standard.object(forKey: "_ACCOUNTDATA") as? [String: Any] else {
        return [:]
    }
    
    var parameter = ["site":"webview.hankyung.com", "user_agent":"app", "client_ip":getIpAddress() ?? "1.1.1.1"]
//    var parameter = ["site":"stg-www.hankyung.com", "user_agent":"app", "client_ip":getIpAddress() ?? "1.1.1.1"]
    
    if let token:String = accountData["ssoToken"] as? String {
        parameter["token"] = token
    }
    
    if type == "check", let token:String = accountData["_hk_token"] as? String {
        parameter["_hk_token"] = token
    }
    
    return parameter
}

// 웹뷰 첫 호출 시 헤더용
func returnAccountParameter() -> Dictionary<String,String> {
    
    var parameter: Dictionary<String,String> = [:]
    
    if deviceId != nil, ((deviceId?.isEmpty) == false) {
        parameter["DEVICE-ID"] = deviceId ?? ""
    }
    
    guard let accountData = UserDefaults.standard.object(forKey: "_ACCOUNTDATA") as? [String: Any] else {
        return parameter
    }
    
    if let token:String = accountData["ssoToken"] as? String {
        parameter["SSO-TOKEN"] = token
    } else {
        parameter["SSO-TOKEN"] = ""
    }
    
    if let token:String = accountData["_hk_token"] as? String {
        parameter["HK-TOKEN"] = token
    } else {
        parameter["HK-TOKEN"] = ""
    }
    
    if let id:String = accountData["SSOid"] as? String {
        parameter["SSO_ID"] = id.urlDecoded
    } else {
        parameter["SSO_ID"] = ""
    }
    
    parameter["DEVICE-ID"] = deviceId ?? ""
    
    return parameter
}

func returnAccountParameterForLogin() -> Dictionary<String,String> {
    
    guard let accountData = UserDefaults.standard.object(forKey: "_ACCOUNTDATA") as? [String: Any] else {
        return [:]
    }
    
    var parameter: Dictionary<String,String> = [:]

    
    if let token:String = accountData["ssoToken"] as? String {
        parameter["token"] = token
    } else {
        parameter["token"] = ""
    }
    
    parameter["site"] = "webview.hankyung.com"
    parameter["user_agent"] = "app"
    
    return parameter
}




extension UIView {
    func showToast(_ message : String, withDuration: Double, delay: Double) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.frame.size.width/2 - 75, y: self.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = UIColor.white
        toastLabel.font = UIFont.systemFont(ofSize: 14.0)
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds  =  true
            
        self.addSubview(toastLabel)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIView.animate(withDuration: withDuration, delay: 0.0, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0.0
            }, completion: {(isCompleted) in
                toastLabel.removeFromSuperview()
            })
        }
        
    }
    
}

func returnDateTime() -> String {
    let dateFormatter = DateFormatter()

    // 날짜 포맷 설정 (연도-월-일 시:분:초)
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

    // 현재 시간 가져오기
    let currentTime = Date()

    // 현재 시간을 문자열로 변환
    let currentTimeString = dateFormatter.string(from: currentTime)

    return currentTimeString
}

func getUserIdAndUserNo() -> (userId: String?, userNo: String?) {
    guard let accountData = UserDefaults.standard.object(forKey: "_ACCOUNTDATA") as? [String: Any] else {
        return ("", "")
    }
    
    let userId = accountData["UserId"] as? String
    let userNo = accountData["UserNo"] as? String
    
    return (userId, userNo)
}

func getThatAsYN(for key: String) -> String {
    let isEnabled = UserDefaults.standard.bool(forKey: key)
    return isEnabled ? "Y" : "N"
}

func getUserTokensArray() -> [String] {
    let deviceId = deviceId ?? ""
    
    guard let accountData = UserDefaults.standard.object(forKey: "_ACCOUNTDATA") as? [String: Any] else {
        return ["", "", "", deviceId]
    }
    
    let ssoId = accountData["SSOid"] as? String ?? ""
    let hkToken = accountData["_hk_token"] as? String ?? ""
    let ssoToken = accountData["ssoToken"] as? String ?? ""
    
    return [ssoId.urlDecoded, hkToken, ssoToken, deviceId]
}

// 서버에 api 호출용 SSOid 인코딩 없이
func getUserTokensParams() -> Dictionary<String,String> {
    guard let accountData = UserDefaults.standard.object(forKey: "_ACCOUNTDATA") as? [String: Any] else {
        return ["ssoToken" : "", "hk_token" : "", "SSOid" : ""]
    }
    
    var parameter: Dictionary<String,String> = [:]

    
    if let token:String = accountData["ssoToken"] as? String {
        parameter["ssoToken"] = token
    } else {
        parameter["ssoToken"] = ""
    }
    
    if let token:String = accountData["_hk_token"] as? String {
        parameter["hk_token"] = token
    } else {
        parameter["hk_token"] = ""
    }
    
    if let id:String = accountData["SSOid"] as? String {
        parameter["SSOid"] = id.urlDecoded
    } else {
        parameter["SSOid"] = ""
    }
    
    return parameter
}

func isImageMostlyWhite(_ image: UIImage) -> Bool {
    guard let cgImage = image.cgImage else { return false }
    
    let width = cgImage.width
    let height = cgImage.height
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(data: nil,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        return false
    }
    
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    
    guard let data = context.data else { return false }
    
    let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
    
    // 히스토그램 생성
    var histogram = [Int](repeating: 0, count: 256)
    let totalPixels = width * height
    let sampleRate = 10
    
    for i in stride(from: 0, to: totalPixels, by: sampleRate) {
        let pixelIndex = i * bytesPerPixel
        let red = pixels[pixelIndex]
        let green = pixels[pixelIndex + 1]
        let blue = pixels[pixelIndex + 2]
        
        // 그레이스케일 값 계산
        let gray = Int(0.299 * Double(red) + 0.587 * Double(green) + 0.114 * Double(blue))
        histogram[gray] += 1
    }
    
    // 히스토그램 분석
    let sampledPixels = totalPixels / sampleRate
    let whiteRange = 240...255  // 흰색 범위
    let whitePixels = whiteRange.reduce(0) { $0 + histogram[$1] }
    let whiteRatio = Double(whitePixels) / Double(sampledPixels)
    
    // 색상 분포 분석
    let nonWhitePixels = sampledPixels - whitePixels
    let colorDistribution = histogram[0..<240].filter { $0 > 0 }.count
    
    print("히스토그램 분석: 흰색 비율 \(whiteRatio * 100)%, 색상 분포 \(colorDistribution)")
    
    // 빈 페이지 판단: 흰색이 많고 색상 분포가 적으면 빈 페이지
    return whiteRatio > 0.8 && colorDistribution < 30
}

func checkNetworkStatus() {
    guard NetworkStatusManager.shared.isConnected() else {
        CustomAlert.shared.showNetworkError()
        return
    }
    // API 호출...
}


