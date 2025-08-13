//
//  Search.swift
//  newsApp
//
//  Created by jay on 7/28/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

// MARK: - Main Response
struct Search: Codable {
    let code: Int?
    let message: String?
    let data: SearchData?
}

// MARK: - Search Data
struct SearchData: Codable {
    let list: [SearchResult]?
    let total: Int?
    let lastPage: Int?
    
    enum CodingKeys: String, CodingKey {
        case list, total
        case lastPage = "last_page"
    }
}

// MARK: - Search Result
struct SearchResult: Codable {
    let aid: String?
    let title: String?
    let url: String?
    let appUrl: String?
    let mediaid: String?
    let content: String?
    let cid: [String]?
    let sectionid: String?
    let thumbimg: String?
    let payment: String?
    let tagInfo: [TagInfo]?
    let pubDate: String?
    
    enum CodingKeys: String, CodingKey {
        case aid, title, url, mediaid, content, cid, sectionid, thumbimg, payment
        case appUrl = "app_url"
        case tagInfo = "tag_info"
        case pubDate = "pub_date"
    }
}

// MARK: - Tag Info
struct TagInfo: Codable {
    let tagid: String?
    let tag: String?
    let slug: String?
}

// MARK: - Convenience Extensions
extension SearchResult {
    
    var hasImage: Bool {
        !(thumbimg?.isEmpty ?? true)
    }
    
    var isPaidContent: Bool {
        payment == "Y"
    }
}

extension Search {
    var isSuccess: Bool {
        code == 200
    }
}
