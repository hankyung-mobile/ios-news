//
//  AiSearch.swift
//  newsApp
//
//  Created by jay on 7/28/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

// MARK: - Main Response
struct AiSearch: Codable {
   let code: Int?
   let message: String?
   let data: AiSearchData?
}

// MARK: - Search Data
struct AiSearchData: Codable {
   let totalSize: Int?
   let attributionToken: String?
   let sessionInfo: AiSearchSessionInfo?
   let list: [AiSearchArticle]?
}

// MARK: - Session Info
struct AiSearchSessionInfo: Codable {
   let name: String?
   let queryId: String?
}

// MARK: - Article
struct AiSearchArticle: Codable {
   let aid: String?
   let pubdate: String?
   let description: String?
   let thumbnail: String?
   let url: String?
   let appUrl: String?
   let title: String?
   let reporterUri: String?
   let reporterName: String?
   let images: [AiSearchArticleImage]?
   let categories: String?
   
   enum CodingKeys: String, CodingKey {
       case aid, pubdate, description, thumbnail, url, title, images, categories
       case appUrl = "app_url"
       case reporterUri = "reporter_uri"
       case reporterName = "reporter_name"
   }
}

// MARK: - Article Image
struct AiSearchArticleImage: Codable {
   let uri: String?
}

// MARK: - Convenience Extensions
extension AiSearchArticle {
    
    var hasImage: Bool {
        !(thumbnail?.isEmpty ?? true)
    }
    
}

extension AiSearch {
    var isSuccess: Bool {
        code == 200
    }
}
