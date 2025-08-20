//
//  Reporters.swift
//  newsApp
//
//  Created by jay on 7/15/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

// 최상위 응답 구조
struct Reporters: Codable {
    let code: Int?
    let message: String?
    let data: ReporterData?
}

// "data" 객체 구조
struct ReporterData: Codable {
    let list: [Reporter]?
}

// 개별 기자 정보 구조
struct Reporter: Codable, Identifiable {
    let no: Int?
    let reporterName: String?
    let reporterEmail: String?
    let deptname: String?
    let photo: String?
    let regDate: String
    let readDate: String?
    let isNew: Bool?

    // Identifiable 프로토콜을 위한 id 프로퍼티
    var id: Int? { no }

    // JSON 키(snake_case)와 Swift 프로퍼티(camelCase)를 매핑
    enum CodingKeys: String, CodingKey {
        case no
        case reporterName = "reporter_name"
        case reporterEmail = "reporter_email"
        case deptname
        case photo
        case regDate = "reg_date"
        case readDate = "read_date"
        case isNew = "is_new"
    }
}
