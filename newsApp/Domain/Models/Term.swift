//
//  Term.swift
//  newsApp
//
//  Created by jay on 7/29/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

// MARK: - Term Models
struct Term: Codable {
    let code: Int?
    let message: String?
    let data: TermList?
}

struct TermList: Codable {
    let list: [TermItem]?
    let total: Int?
    let lastPage: Int?
    
    enum CodingKeys: String, CodingKey {
        case list, total
        case lastPage = "last_page"
    }
}

struct TermItem: Codable {
    let seq: Int?
    let url: String?
    let word: String?
    let eword: String?
    let simple: String?
    let chinese: String?
    let content: String?
}

extension Term {
    var isSuccess: Bool {
        code == 200
    }
}
