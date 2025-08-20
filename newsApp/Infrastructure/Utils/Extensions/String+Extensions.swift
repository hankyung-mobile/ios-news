//
//  String+Extensions.swift
//  newsApp
//
//  Created by jay on 7/7/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

extension String {
    var urlDecoded: String {
        return self.removingPercentEncoding ?? self
    }
}

extension Date {
    
    /// 2025.05.12 13:00 형식으로 변환
    var displayFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter.string(from: self)
    }
    
    /// 날짜만 있을 때 00:00으로 설정
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
}

// MARK: - String Extension (서버에서 받은 문자열 처리)
extension String {
    
    /// 서버에서 받은 날짜 문자열을 표시용으로 변환
    var toDisplayFormat: String? {
        // 타임존 있는 ISO 형식 먼저 체크
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: self) {
            return date.displayFormat
        }
        
        // 다른 형식들
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss",      // 2025-05-12T13:00:00
            "yyyy-MM-dd HH:mm:ss",        // 2025-05-12 13:00:00
            "yyyy-MM-dd",                 // 2025-05-12
            "yyyy.MM.dd HH:mm",           // 이미 우리 형식
            "yyyy/MM/dd HH:mm"            // 2025/05/12 13:00
        ]
        
        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            
            if let date = formatter.date(from: self) {
                return date.displayFormat
            }
        }
        
        return nil
    }
}


