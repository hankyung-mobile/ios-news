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
    let multiUrls: [String]
    let inappUrls: [String]
    let externalUrls: [String]
    
    static let `default`: BrowserConfiguration = {
        return BrowserConfiguration.fromUserDefaults()
    }()
    
    /// UserDefaults에서 마스터 데이터를 가져와서 BrowserConfiguration 생성
    static func fromUserDefaults() -> BrowserConfiguration {
        if let masterData = AppDataManager.shared.getMasterData() {
            return BrowserConfiguration(
                multiUrls: masterData.data?.multiUrls ?? [],
                inappUrls: masterData.data?.inappUrls ?? [],
                externalUrls: masterData.data?.externalUrls ?? []
            )
        } else {
            // 마스터 데이터가 없을 때 기본값
            return BrowserConfiguration(
                multiUrls: [],
                inappUrls: [],
                externalUrls: []
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
        let isWebviewHankyung = lowercasedUrl.contains("webview.hankyung") ||
        lowercasedUrl.contains("stg-webview.hankyung")
        
        print("🔍 Analyzing URL: \(url)")
        print("   Lowercased: \(lowercasedUrl)")
        
        // 1. multiUrls 처리 (첫 번째 우선순위)
        if configuration.multiUrls.contains(where: { lowercasedUrl.contains($0.lowercased()) }) {
            print("   ✅ Match: Multi URL -> New Window")
            return .newWindow
        }
        
        // 2. inappUrls 처리 (두 번째 우선순위)
        if configuration.inappUrls.contains(where: { lowercasedUrl.contains($0.lowercased()) }) {
            print("   ✅ Match: InApp URL -> Internal Browser")
            return .internalBrowser
        }
        
        // 3. externalUrls 처리 (세 번째 우선순위)
        if configuration.externalUrls.contains(where: { lowercasedUrl.contains($0.lowercased()) }) {
            print("   ✅ Match: External URL -> External Browser")
            return .externalBrowser
        }
        
        // 4. 한경 도메인 특별 처리
        // 4-1. webview.hankyung 포함 시 (stg- prefix 가능)
        if isWebviewHankyung {
            print("   ✅ Match: webview.hankyung domain -> New Window")
            return .newWindow
        }
        
        // 4-2. webview 없이 .hankyung만 포함 시
        if lowercasedUrl.contains(".hankyung") && !isWebviewHankyung {
            print("   ✅ Match: .hankyung domain (without webview) -> Internal Browser")
            return .internalBrowser
        }
        // 5. Default 처리 (5개 모두 매칭되지 않을 경우)
        print("   ⚠️ No match found -> Default: External Browser")
        return .externalBrowser  // 기본값은 외부 브라우저로 설정 (필요시 변경 가능)
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
