//
//  TermDetail.swift
//  newsApp
//
//  Created by jay on 7/29/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

// MARK: - Term Detail Models
struct TermDetail: Codable {
    let code: Int?
    let message: String?
    let data: TermDetailItem?
}

struct TermDetailItem: Codable {
    let seq: Int?
    let word: String?
    let eword: String?
    let chinese: String?
    let simple: String?
    let content: String?
}

extension TermDetail {
    var isSuccess: Bool {
        code == 200
    }
}
