//
//  ScrapList.swift
//  newsApp
//
//  Created by jay on 7/8/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

struct ScrapList: Codable {
    let code: Int?
    let message: String?
    let data: ScrapData?
}

struct ScrapData: Codable {
    let list: [ScrapItem]?
}

struct ScrapItem: Codable {
    let no: String?
    let aid: String?
    let scrap_date: String?
    let date_month: String?
    let title: String?
    let pub_date: String?
    let url: String?
    let app_url: String?
}
