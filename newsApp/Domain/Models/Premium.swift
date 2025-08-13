//
//  Premium.swift
//  newsApp
//
//  Created by jay on 6/13/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

// MARK: - Root Response Model
struct Premium: Codable {
    let code: Int?
    let message: String?
    let data: PremiumMenuData?
}

// MARK: - Menu Data Model
struct PremiumMenuData: Codable {
    let menu: PremiumMenuContainer?
    let slide: [PremiumSlideItem]?
}

// MARK: - Menu Container Model
struct PremiumMenuContainer: Codable {
    let A: PremiumMenuSection?
    let B: PremiumMenuSection?
    let C: PremiumMenuSection?
    let D: PremiumMenuSection?
}

// MARK: - Menu Section Model
struct PremiumMenuSection: Codable {
    let title: PremiumMenuTitle?
    let list: [PremiumMenuItem]?
}

// MARK: - Menu Title Model
struct PremiumMenuTitle: Codable {
    let name: String?
    let isBold: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name
        case isBold = "is_bold"
    }
}

// MARK: - Menu Item Model
struct PremiumMenuItem: Codable {
    let id: String?
    let title: String?
    let url: String?
    let image: String?
    let browser: String?
    let isSlide: Bool?
}

// MARK: - Slide Item Model
struct PremiumSlideItem: Codable {
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

