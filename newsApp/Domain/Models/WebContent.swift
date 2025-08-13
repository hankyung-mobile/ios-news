//
//  WebContent.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

/// 웹 콘텐츠 모델
struct WebContent: Codable {
    let id: String
    let title: String
    let url: String
    let type: WebContentType
    let thumbnailUrl: String?
    let description: String?
    let lastUpdated: Date
    let cacheKey: String?
    let expiresAt: Date?
    let metadata: [String: String]?
    
    // MARK: - 생성자
    
    init(id: String,
         title: String,
         url: String,
         type: WebContentType,
         thumbnailUrl: String? = nil,
         description: String? = nil,
         lastUpdated: Date = Date(),
         cacheKey: String? = nil,
         expiresAt: Date? = nil,
         metadata: [String: String]? = nil) {
        
        self.id = id
        self.title = title
        self.url = url
        self.type = type
        self.thumbnailUrl = thumbnailUrl
        self.description = description
        self.lastUpdated = lastUpdated
        self.cacheKey = cacheKey
        self.expiresAt = expiresAt
        self.metadata = metadata
    }
    
    // MARK: - 코딩 키
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case type
        case thumbnailUrl = "thumbnail_url"
        case description
        case lastUpdated = "last_updated"
        case cacheKey = "cache_key"
        case expiresAt = "expires_at"
        case metadata
    }
}

/// 웹 콘텐츠 타입 열거형
enum WebContentType: String, Codable {
    case home = "HOME"
    case reservation = "RESERVATION"
    case stock = "STOCK"
    case notification = "NOTIFICATION"
    case settings = "SETTINGS"
    case custom = "CUSTOM"
}

/// 웹 콘텐츠 캐싱 관련 모델
struct WebContentCache: Codable {
    let contentId: String
    let htmlContent: String
    let assets: [WebContentAsset]?
    let timestamp: Date
    let validUntil: Date?
    
    // MARK: - 생성자
    
    init(contentId: String,
         htmlContent: String,
         assets: [WebContentAsset]? = nil,
         timestamp: Date = Date(),
         validUntil: Date? = nil) {
        
        self.contentId = contentId
        self.htmlContent = htmlContent
        self.assets = assets
        self.timestamp = timestamp
        self.validUntil = validUntil
    }
    
    // MARK: - 유틸리티 메서드
    
    /// 캐시가 유효한지 확인
    var isValid: Bool {
        guard let validUntil = validUntil else {
            return true  // 만료 시간이 없으면 항상 유효
        }
        
        return Date() < validUntil
    }
}

/// 웹 콘텐츠 애셋 모델
struct WebContentAsset: Codable {
    let url: String
    let type: AssetType
    let localPath: String?
    let size: Int64?
    
    // MARK: - 생성자
    
    init(url: String,
         type: AssetType,
         localPath: String? = nil,
         size: Int64? = nil) {
        
        self.url = url
        self.type = type
        self.localPath = localPath
        self.size = size
    }
}

/// 애셋 타입 열거형
enum AssetType: String, Codable {
    case image = "IMAGE"
    case javascript = "JAVASCRIPT"
    case stylesheet = "STYLESHEET"
    case font = "FONT"
    case other = "OTHER"
}

/// 웹 콘텐츠 응답 모델
struct WebContentResponse: Codable {
    let content: WebContent
    let relatedContents: [WebContent]?
    let cacheSettings: CacheSettings?
    
    // MARK: - 코딩 키
    
    enum CodingKeys: String, CodingKey {
        case content
        case relatedContents = "related_contents"
        case cacheSettings = "cache_settings"
    }
}

/// 캐시 설정 모델
struct CacheSettings: Codable {
    let enabled: Bool
    let maxAgeSeconds: Int
    let staleWhileRevalidate: Bool
    
    // MARK: - 코딩 키
    
    enum CodingKeys: String, CodingKey {
        case enabled
        case maxAgeSeconds = "max_age_seconds"
        case staleWhileRevalidate = "stale_while_revalidate"
    }
}
