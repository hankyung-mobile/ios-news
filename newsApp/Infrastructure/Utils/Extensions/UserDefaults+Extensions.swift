//
//  UserDefaults+Extensions.swift
//  newsApp
//
//  Created by jay on 5/30/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

extension UserDefaults {
    // MARK: - Keys
    enum Key: String {
        case appData = "app_master_data"
        case newsData = "news_data"
        case premiumData = "premium_data"
        case marketData = "market_data"
        case authToken = "auth_token"
        case userSettings = "user_settings"
        case pushData = "push_data"
        
        var key: String { "com.app.\(rawValue)" }
    }
    
    // MARK: - Generic Save/Load
    func save<T: Codable>(_ object: T, forKey key: Key) {
        let data = try? JSONEncoder().encode(object)
        set(data, forKey: key.key)
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: Key) -> T? {
        guard let data = data(forKey: key.key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    func remove(forKey key: Key) {
        removeObject(forKey: key.key)
    }
    
    // MARK: - 마스터 데이터
    func saveAppData(_ data: Master) {
        save(data, forKey: .appData)
    }
    
    func loadAppData() -> Master? {
        return load(Master.self, forKey: .appData)
    }
    
    // MARK: - 뉴스 데이터
    func saveNewsData(_ data: News) {
        save(data, forKey: .newsData)
    }
    
    func loadNewsData() -> News? {
        return load(News.self, forKey: .newsData)
    }
    
    // MARK: - 프리미엄 데이터
    func savePremiumData(_ data: Premium) {
        save(data, forKey: .premiumData)
    }
    
    func loadPremiumData() -> Premium? {
        return load(Premium.self, forKey: .premiumData)
    }
    
    // MARK: - 마켓 데이터
    func saveMarketData(_ data: Market) {
        save(data, forKey: .marketData)
    }
    
    func loadMarketData() -> Market? {
        return load(Market.self, forKey: .marketData)
    }
    
    // MARK: - 푸시 데이터
    func savePushData(_ data: [PushItem]) {
        save(data, forKey: .pushData)
    }
    
    func loadPushData() -> [PushItem]? {
        return load([PushItem].self, forKey: .pushData)
    }
    
    func saveAuthToken(_ token: String) {
        save(token, forKey: .authToken)
    }
    
    func loadAuthToken() -> String? {
        return string(forKey: Key.authToken.key)
    }
    
    func removeAuthToken() {
        remove(forKey: .authToken)
    }
}
