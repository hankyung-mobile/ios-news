//
//  StockSearch.swift
//  newsApp
//
//  Created by jay on 7/29/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

// MARK: - Stock Models
struct Stock: Codable {
    let code: Int?
    let message: String?
    let data: StockList?
}

struct StockList: Codable {
    let list: [StockItem]?
}

struct StockItem: Codable {
    let code: String?
    let name: String?
    let market: String?
    let ename: String?
    let url: String?
    let appUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case code, name, market, ename, url
        case appUrl = "app_url"
    }
}

extension Stock {
    var isSuccess: Bool {
        code == 200
    }
}

