//
//  News.swift
//  newsApp
//
//  Created by jay on 6/25/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

// MARK: - Root Response Model
struct News: Codable {
    let code: Int?
    let message: String?
    let data: NewsMenuData?
}

// MARK: - Menu Data Model
struct NewsMenuData: Codable {
    let menu: NewsMenuContainer?
    let slide: [NewsSlideItem]?
}

// MARK: - Menu Container Model
struct NewsMenuContainer: Codable {
    // 🔥 기존 A, B, C, D 제거하고 Dictionary로 변경
    let sections: [String: NewsMenuSection]
    
    // 🔥 커스텀 디코딩
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        sections = try container.decode([String: NewsMenuSection].self)
    }
    
    // 🔥 커스텀 인코딩
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(sections)
    }
    
    // 섹션 키들을 알파벳 순으로 정렬해서 반환
    var sortedSectionKeys: [String] {
        print("🔍 정렬된 섹션 키들: \(sections.keys.sorted())")
        return sections.keys.sorted()
    }
    
    // 특정 섹션 가져오기
    func getSection(_ key: String) -> NewsMenuSection? {
        return sections[key]
    }
    
    // 모든 섹션 순회
    func forEachSection(_ closure: (String, NewsMenuSection) -> Void) {
        for key in sortedSectionKeys {
            if let section = sections[key] {
                closure(key, section)
            }
        }
    }
}

// MARK: - Menu Section Model
struct NewsMenuSection: Codable {
    let title: NewsMenuTitle?
    let list: [NewsMenuItem]?
}

// MARK: - Menu Title Model
struct NewsMenuTitle: Codable {
    let name: String?
    let isBold: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name
        case isBold = "is_bold"
    }
}

// MARK: - Menu Item Model
struct NewsMenuItem: Codable {
    let id: String?
    let title: String?
    let subtitle: String?
    let url: String?
    let image: String?
    let browser: String?
    let isSlide: Bool?
    let iconUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, url, image
        case browser
        case isSlide
        case iconUrl = "icon_url"
    }
}

// MARK: - Slide Item Model
struct NewsSlideItem: Codable {
    let id: String?
    let title: String?
    let url: String?
    let image: String?
    let slideOrder: Int?
    let isMain: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, title, url, image
        case slideOrder = "slide_order"
        case isMain
    }
}
