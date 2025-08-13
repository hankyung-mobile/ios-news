//
//  PushList.swift
//  newsApp
//
//  Created by jay on 7/31/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

// MARK: - Push Response Model
struct PushList: Codable {
    let code: Int?
    let message: String?
    let data: PushData?
}

// MARK: - Push Data Model
struct PushData: Codable {
    let list: [PushItem]?
}

// MARK: - Push Item Model
struct PushItem: Codable {
    let indate: String?
    let reservedtime: String?
    let message: String?
    let viewMedia: String?
    let type: String?
    let url: String?
    let viewMediaTitle: String?
    let thumbimg: String?
}
