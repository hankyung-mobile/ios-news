//
//  EnvironmentManager.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - 환경 설정
enum Environment {
    case LIVE
    case STG
    case DEV
    
    var baseURL: String {
        switch self {
        case .LIVE:
            return "https://api-www.hankyung.com"
        case .STG:
            return "https://stg-www.hankyung.com"
        case .DEV:
            return "https://apidev-www.hankyung.com"
        }
    }
    
    var displayName: String {
        switch self {
        case .LIVE: return "운영"
        case .STG: return "스테이징"
        case .DEV: return "개발"
        }
    }
}

// MARK: - 환경 관리자 (Singleton)
class EnvironmentManager {
    static let shared = EnvironmentManager()
    
    private init() {
        // 초기 환경 설정 (앱 시작시 한 번만)
        loadEnvironmentFromUserDefaults()
    }
    
    // 현재 환경
    private(set) var currentEnvironment: Environment = .DEV {
        didSet {
            saveEnvironmentToUserDefaults()
            NotificationCenter.default.post(name: .environmentChanged, object: currentEnvironment)
        }
    }
    
    // 현재 베이스 URL
    var baseURL: String {
        return currentEnvironment.baseURL
    }
    
    // 환경 변경
    func setEnvironment(_ environment: Environment) {
        currentEnvironment = environment
    }
    
    // UserDefaults에서 환경 로드
    private func loadEnvironmentFromUserDefaults() {
        if let savedEnvironment = UserDefaults.standard.string(forKey: "CurrentEnvironment") {
            switch savedEnvironment {
            case "LIVE": currentEnvironment = .LIVE
            case "STG": currentEnvironment = .STG
            case "DEV": currentEnvironment = .DEV
            default: currentEnvironment = .DEV
            }
        }
    }
    
    // UserDefaults에 환경 저장
    private func saveEnvironmentToUserDefaults() {
        let environmentString: String
        switch currentEnvironment {
        case .LIVE: environmentString = "LIVE"
        case .STG: environmentString = "STG"
        case .DEV: environmentString = "DEV"
        }
        UserDefaults.standard.set(environmentString, forKey: "CurrentEnvironment")
    }
}

// MARK: - 네트워크 설정 (수정됨)
struct NetworkConfig {
    // EnvironmentManager 사용
    static var environment: Environment {
        return EnvironmentManager.shared.currentEnvironment
    }
    
    static var baseURL: String {
        return EnvironmentManager.shared.baseURL
    }
    
    static let apiVersion = "v1"
    
    // 헤더 생성 함수
    static func defaultHeaders(withAuth: Bool = true) -> HTTPHeaders {
        var headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "App-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            "Platform": "iOS",
            "Environment": environment.displayName // 환경 정보 추가
        ]
        
        if withAuth, let token = UserDefaults.standard.string(forKey: "authToken") {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        return headers
    }
    
    static func masterHeaders() -> HTTPHeaders {
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "authkey": hkAuthkey,
            "User-Agent": "appinfo/HKAPP_I appversion/\(appVersion) device/\(deviceType)"
        ]
        return headers
    }
    
    static func menuHeaders() -> HTTPHeaders {
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "x-api-key": xApiKey,
            "User-Agent": "appinfo/HKAPP_I appversion/\(appVersion) device/\(deviceType)"
        ]
        return headers
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let environmentChanged = Notification.Name("environmentChanged")
}

// MARK: - API 라우터 열거형 (수정됨)
enum APIRouter: URLRequestConvertible {
    // 기존 케이스들...
    case login(username: String, password: String)
    case refreshToken(token: String)
    case logout
    case getUserProfile
    case getMaster
    case getNews
    case getPremium
    case getMarket
    case getPushList
    case getHKMediaList
    case getSectionList
    case getScrapList
    case getReporters
    case getSearchLatestNews
    case getSearchAi
    case getSearchFinance
    case getSearchReporter
    case getSearchDictionary
    case getSearchDictionaryDetail(seq: Int)
    case deleteScrapList
    case deleteScrapListAll
    case deleteReporter(no: String)
    case getNotifications(page: Int, limit: Int)
    case markNotificationAsRead(id: String)
    case deleteNotification(id: String)
    case getSettings
    
    // MARK: - URLRequestConvertible 구현
    var baseURL: URL {
        // EnvironmentManager 사용
        return URL(string: EnvironmentManager.shared.baseURL) ?? URL(string: Environment.LIVE.baseURL)!
    }
    
    var path: String {
        let apiVersionPath = "/\(NetworkConfig.apiVersion)"
        
        switch self {
        case .login:
            return "\(apiVersionPath)/auth/login"
        case .refreshToken:
            return "\(apiVersionPath)/auth/refresh"
        case .logout:
            return "\(apiVersionPath)/auth/logout"
        case .getUserProfile:
            return "\(apiVersionPath)/user/profile"
        case .getMaster:
            return "/app-data/master/info"
        case .getPushList:
            return "/app-data/push/list"
        case .getHKMediaList:
            return "/app-data/hankyungmedia/list"
        case .getNews:
            return "/app-data/tab/news"
        case .getPremium:
            return "/app-data/tab/premium"
        case .getMarket:
            return "/app-data/tab/market"
        case .getSectionList:
            return "/app-data/news/list"
        case .getScrapList:
            return "/scrap/list"
        case .getReporters:
            return "/subscribe/my/reporters/token"
        case .getSearchLatestNews:
            return "/search/news/list"
        case .getSearchAi:
            return "/search/ai/news"
        case .getSearchFinance:
            return "/search/finance/list"
        case .getSearchReporter:
            return "/search/reporter/list"
        case .getSearchDictionary:
            return "/search/dic/list"
        case .getSearchDictionaryDetail(let seq):
            return "/search/dic/view/\(seq)"
        case .deleteScrapList:
            return "/scrap/delete-multi"
        case .deleteScrapListAll:
            return "/scrap/delete-all"
        case .deleteReporter(let no):
            return "/subscribe/reporters/token/\(no)"
        case .getNotifications:
            return "\(apiVersionPath)/notifications"
        case .markNotificationAsRead(let id):
            return "\(apiVersionPath)/notifications/\(id)/read"
        case .deleteNotification(let id):
            return "\(apiVersionPath)/notifications/\(id)"
        case .getSettings:
            return "\(apiVersionPath)/settings"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login, .getScrapList, .deleteScrapList, .deleteScrapListAll, .getReporters:
            return .post
        case .getSettings, .deleteReporter:
            return .put
        case .markNotificationAsRead:
            return .patch
        case .logout, .deleteNotification:
            return .delete
        default:
            return .get
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .login(let username, let password):
            return ["username": username, "password": password]
        case .refreshToken(let token):
            return ["refresh_token": token]
        case .getNotifications(let page, let limit):
            return ["page": page, "limit": limit]
        default:
            return nil
        }
    }
    
    var encoding: ParameterEncoding {
        switch method {
        case .get:
            return URLEncoding.default
        default:
            return JSONEncoding.default
        }
    }
    
    var headers: HTTPHeaders? {
        switch self {
        case .login, .refreshToken:
            return NetworkConfig.defaultHeaders(withAuth: false)
        case .getMaster, .getNews, .getPremium, .getMarket:
            return NetworkConfig.menuHeaders()
        default:
            return NetworkConfig.menuHeaders()
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = try URLRequest(url: url, method: method, headers: headers)
        request.timeoutInterval = 30
        return try encoding.encode(request, with: parameters)
    }
}
