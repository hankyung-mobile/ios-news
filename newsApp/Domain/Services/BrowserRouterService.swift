//
//  BrowserRouterService.swift
//  newsApp
//
//  Created by jay on 6/11/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

// MARK: - Browser Type Enum
enum BrowserType {
    case newWindow
    case internalBrowser
    case externalBrowser
}

// MARK: - Browser Configuration Model
struct BrowserConfiguration {
    let inappBrowserForceUrls: [String]
    let inappBrowserAllowedUrls: [String]
    let externalBrowserForceUrls: [String]
    
    static let `default`: BrowserConfiguration = {
        return BrowserConfiguration.fromUserDefaults()
    }()
    
    /// UserDefaults에서 마스터 데이터를 가져와서 BrowserConfiguration 생성
    static func fromUserDefaults() -> BrowserConfiguration {
        if let masterData = AppDataManager.shared.getMasterData() {
            return BrowserConfiguration(
                inappBrowserForceUrls: masterData.data?.inappBrowserForceUrls ?? [],
                inappBrowserAllowedUrls: masterData.data?.inappBrowserAllowedUrls ?? [],
                externalBrowserForceUrls: masterData.data?.externalBrowserForceUrls ?? []
            )
        } else {
            // 마스터 데이터가 없을 때 기본값
            return BrowserConfiguration(
                inappBrowserForceUrls: [],
                inappBrowserAllowedUrls: [],
                externalBrowserForceUrls: []
            )
        }
    }
    
    /// 마스터 데이터가 업데이트될 때 호출하여 설정 새로고침
    static func refreshFromUserDefaults() -> BrowserConfiguration {
        return fromUserDefaults()
    }
}

// MARK: - Browser Router Service Protocol
protocol BrowserRouterServiceProtocol {
    func determineBrowserType(for url: String) -> BrowserType
}

// MARK: - Browser Router Service Implementation
class BrowserRouterService: BrowserRouterServiceProtocol {
    static let shared = BrowserRouterService()
    
    private var configuration: BrowserConfiguration
    
    init(configuration: BrowserConfiguration? = nil) {
        self.configuration = configuration ?? BrowserConfiguration.default
    }
    
    /// 마스터 데이터 업데이트 시 설정 새로고침
    func refreshConfiguration() {
        self.configuration = BrowserConfiguration.refreshFromUserDefaults()
        print("🔄 Browser configuration refreshed from UserDefaults")
    }
    
    func determineBrowserType(for url: String) -> BrowserType {
        let lowercasedUrl = url.lowercased()
        
        print("🔍 Analyzing URL: \(url)")
        print("   Lowercased: \(lowercasedUrl)")
        
        // 1. 강제 외부 브라우저 예외 처리 (우선순위 최고)
        if configuration.externalBrowserForceUrls.contains(where: { lowercasedUrl.contains($0.lowercased()) }) {
            print("   ✅ Match: External browser force URL")
            return .externalBrowser
        }
        
        // 2. 한경 도메인 처리 (.hankyung 포함)
        if isHankyungDomain(url: lowercasedUrl) {
            print("   🏢 Hankyung domain detected")
            
            // 2-1. 강제 내부 브라우저 예외 처리 (한경 도메인 내에서)
            if configuration.inappBrowserForceUrls.contains(where: { lowercasedUrl.contains($0.lowercased()) }) {
                print("   ✅ Match: Internal browser force URL (Hankyung)")
                return .internalBrowser
            }
            
            // 2-2. 기본값: 한경 도메인은 새창으로 처리
            print("   ✅ Match: Hankyung domain -> New Window")
            return .newWindow
        }
        
        // 4. 허용된 내부 브라우저 URL 처리 (한경 외 도메인)
        if configuration.inappBrowserAllowedUrls.contains(where: { lowercasedUrl.contains($0.lowercased()) }) {
            print("   ✅ Match: Internal browser allowed URL")
            return .internalBrowser
        }
        
        // 5. 기타 도메인: 외부 브라우저로 처리
        print("   ✅ Default: External Browser")
        return .externalBrowser
    }

    // MARK: - Helper Methods

    /// 한경 도메인인지 확인하는 헬퍼 메서드
    private func isHankyungDomain(url: String) -> Bool {
        // 정규식을 사용한 정확한 매칭 (Kotlin과 동일)
        let hankyungPattern = #"\.hankyung\.com"#
        let regex = try? NSRegularExpression(pattern: hankyungPattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: url.utf16.count)
        let match = regex?.firstMatch(in: url, options: [], range: range)
        
        let isMatch = match != nil
        print("   🔍 Hankyung domain check: \(isMatch)")
        return isMatch
    }

}
