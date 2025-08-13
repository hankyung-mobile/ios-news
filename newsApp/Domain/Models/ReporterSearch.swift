//
//  ReporterSearch.swift
//  newsApp
//
//  Created by jay on 7/29/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

// MARK: - Reporter Models
struct ReporterSearch: Codable {
    let code: Int?
    let message: String?
    let data: ReporterList?
}

struct ReporterList: Codable {
    let list: [ReporterItem]?
}

struct ReporterItem: Codable {
    let usernumber: Int?
    let name: String?
    let email: String?
    let dept: String?
    let usertitle: String?
    let englishname: String?
    let introduce: String?
    let photo: String?
    let facebook: String?
    let twitter: String?
    let blog: String?
    let instagram: String?
    let usertag: String?
    let url: String?
    let appUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case usernumber, name, email, dept, usertitle, englishname
        case introduce, photo, facebook, twitter, blog, instagram
        case usertag, url
        case appUrl = "app_url"
    }
}

extension ReporterSearch {
    var isSuccess: Bool {
        code == 200
    }
}
