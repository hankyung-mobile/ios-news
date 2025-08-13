//
//  AppDataRepository.swift
//  newsApp
//
//  Created by jay on 5/30/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class AppDataManager {
    static let shared = AppDataManager()
    
    private let appDataSubject = BehaviorSubject<Master?>(value: nil)
    private let newsDataSubject = BehaviorSubject<News?>(value: nil)
    private let premiumDataSubject = BehaviorSubject<Premium?>(value: nil)
    private let marketDataSubject = BehaviorSubject<Market?>(value: nil)
    private let pushDataSubject = BehaviorSubject<[PushItem]?>(value: nil)
    
    var appData: Observable<Master?> {
        return appDataSubject.asObservable()
    }
    
    var newsData: Observable<News?> {
        return newsDataSubject.asObservable()
    }
    
    var premiumData: Observable<Premium?> {
        return premiumDataSubject.asObservable()
    }
    
    var marketData: Observable<Market?> {
        return marketDataSubject.asObservable()
    }
    
    init() {}
    
    // MARK: - 마스터 데이터
    func saveAppData(_ response: Master) {
        
        appDataSubject.onNext(response)
        UserDefaults.standard.saveAppData(response)
    }
   
    func getMasterData() -> Master? {
        return UserDefaults.standard.loadAppData()
    }
    
    // MARK: - 뉴스 데이터
    
    func saveNewsData(_ response: News) {
        
        newsDataSubject.onNext(response)
        UserDefaults.standard.saveNewsData(response)
    }
   
    func getNewsData() -> News? {
        return UserDefaults.standard.loadNewsData()
    }
    
    func getNewsSlideData() -> [NewsSlideItem] {
        return UserDefaults.standard.loadNewsData()?.data?.slide ?? []
    }
    
    func getAllNewsMenuSectionsWithKeys() -> [(key: String, section: NewsMenuSection)] {
        guard let menu = UserDefaults.standard.loadNewsData()?.data?.menu else {
            return []
        }
        
        return menu.sortedSectionKeys.compactMap { key in
            guard let section = menu.getSection(key) else { return nil }
            return (key: key, section: section)
        }
    }
    // MARK: - 프리미엄 데이터
    func savePremiumData(_ response: Premium) {
        
        premiumDataSubject.onNext(response)
        UserDefaults.standard.savePremiumData(response)
    }
   
    func getPremiumData() -> Premium? {
        return UserDefaults.standard.loadPremiumData()
    }
    
    func getPremiumSlideData() -> [PremiumSlideItem] {
        return UserDefaults.standard.loadPremiumData()?.data?.slide ?? []
    }
    
    func getAllPremiumMenuSections() -> [PremiumMenuSection] {
        guard let menu = UserDefaults.standard.loadPremiumData()?.data?.menu else {
            return []
        }
        
        var sections: [PremiumMenuSection] = []
        
        // A, B, C, D 섹션을 순서대로 배열에 추가 (nil이 아닌 것만)
        if let sectionA = menu.A { sections.append(sectionA) }
        if let sectionB = menu.B { sections.append(sectionB) }
        if let sectionC = menu.C { sections.append(sectionC) }
        if let sectionD = menu.D { sections.append(sectionD) }
        
        return sections
    }
    
    // MARK: - 마켓 데이터
    func saveMarketData(_ response: Market) {
        
        marketDataSubject.onNext(response)
        UserDefaults.standard.saveMarketData(response)
    }
   
    func getMarketData() -> Market? {
        return UserDefaults.standard.loadMarketData()
    }
    
    func getMarketSlideData() -> [MarketSlideItem] {
        return UserDefaults.standard.loadMarketData()?.data?.slide ?? []
    }
    
    func getAllMarketMenuSectionsWithKeys() -> [(key: String, section: MarketMenuSection)] {
        guard let menu = UserDefaults.standard.loadMarketData()?.data?.menu else {
            return []
        }
        
        return menu.sortedSectionKeys.compactMap { key in
            guard let section = menu.getSection(key) else { return nil }
            return (key: key, section: section)
        }
    }
    
    // MARK: - 푸시 데이터
    
    func savePushData(_ response: [PushItem]) {
        pushDataSubject.onNext(response)
        UserDefaults.standard.savePushData(response)
    }
   
    func getPushData() -> [PushItem]? {
        return UserDefaults.standard.loadPushData()
    }
}
