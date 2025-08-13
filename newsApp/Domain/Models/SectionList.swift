//
//  SectionList.swift
//  newsApp
//
//  Created by jay on 7/3/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

// MARK: - Main Response Model
struct SectionList: Codable {
    let code: Int?
    let message: String?
    let data: NewsData?
}

// MARK: - Data Container
struct NewsData: Codable {
    let list: [NewsArticle]?
    let total: Int?
    let lastPage: Int?
    
    enum CodingKeys: String, CodingKey {
        case list, total
        case lastPage = "last_page"
    }
}

// MARK: - Article Model
struct NewsArticle: Codable {
    let aid: String?
    let title: String?
    let url: String?
    let content: String?
    let pubDate: String?
    let thumbimg: String?
    let payment: String?
    
    enum CodingKeys: String, CodingKey {
        case aid, title, url, content, thumbimg, payment
        case pubDate = "pub_date"
    }
}
