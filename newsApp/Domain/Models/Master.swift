//
//  AppConfig.swift
//  newsApp
//
//  Created by jay on 5/29/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Root Response Model
struct Master: Codable {
    let code: Int?
    let message: String?
    let data: AppInfoData?
}

// MARK: - App Info Data
struct AppInfoData: Codable {
    let appVersion: AppVersion?
    let multiUrls: [String]?
    let inappUrls: [String]?
    let externalUrls: [String]?
    let notice: Notice?
    
    enum CodingKeys: String, CodingKey {
        case appVersion = "app-version"
        case multiUrls = "multi-urls"
        case inappUrls = "inapp-urls"
        case externalUrls = "external-urls"
        case notice
    }
}

// MARK: - App Version
struct AppVersion: Codable {
    let android: PlatformVersion?
    let iOS: PlatformVersion?
}

// MARK: - Platform Version
struct PlatformVersion: Codable {
    let latestVersion: String?
    let forceVersion: String?
    
    enum CodingKeys: String, CodingKey {
        case latestVersion = "latest-version"
        case forceVersion = "force-version"
    }
}

// MARK: - Notice
struct Notice: Codable {
    let title: String?
    let content: String?
    let url: String?
}
