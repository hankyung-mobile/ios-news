//
//  HKMedia.swift
//  newsApp
//
//  Created by jay on 7/31/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

// MARK: - HK Media Response Model
struct HKMedia: Codable {
    let code: Int?
    let message: String?
    let data: HKMediaData?
}

// MARK: - HK Media Data Model
struct HKMediaData: Codable {
    let list: [HKMediaItem]?
}

// MARK: - HK Media Item Model
struct HKMediaItem: Codable {
    let title: String?
    let url: String?
}
