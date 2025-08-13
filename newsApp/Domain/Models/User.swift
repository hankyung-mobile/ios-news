//
//  User.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import UIKit

struct User: Codable {
    let id: String
    let email: String
    let name: String
    let profileImageUrl: String?
    let createdAt: Date
    let lastLoginDate: Date?
    
    // 추가 정보
    let phoneNumber: String?
    let preferences: UserPreferences?
    let notificationSettings: NotificationSettings?
    
    // Codable 열거형
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case profileImageUrl
        case createdAt
        case lastLoginDate
        case phoneNumber
        case preferences
        case notificationSettings
    }
}

// 사용자 환경설정
struct UserPreferences: Codable {
    let theme: String?           // 테마 (라이트, 다크)
    let language: String?        // 언어 설정
    let currency: String?        // 통화 설정
    let stockTickerVisible: Bool // 주식 티커 표시 여부
    
    // 기본값 생성자
    init(theme: String? = "system", language: String? = "ko", currency: String? = "KRW", stockTickerVisible: Bool = true) {
        self.theme = theme
        self.language = language
        self.currency = currency
        self.stockTickerVisible = stockTickerVisible
    }
}

// 알림 설정
struct NotificationSettings: Codable {
    let enabled: Bool                  // 알림 활성화 여부
    let notificationTypes: [String]    // 알림 유형 (예: "reservation", "stock", "marketing")
    let emailEnabled: Bool             // 이메일 알림 활성화 여부
    let pushEnabled: Bool              // 푸시 알림 활성화 여부
    
    // 기본값 생성자
    init(enabled: Bool = true,
         notificationTypes: [String] = ["reservation", "stock"],
         emailEnabled: Bool = true,
         pushEnabled: Bool = true) {
        self.enabled = enabled
        self.notificationTypes = notificationTypes
        self.emailEnabled = emailEnabled
        self.pushEnabled = pushEnabled
    }
}

// MARK: - User 확장

extension User {
    // 기본 사용자 생성 (테스트용)
    static func defaultUser() -> User {
        return User(
            id: "default-user-id",
            email: "user@example.com",
            name: "기본 사용자",
            profileImageUrl: nil,
            createdAt: Date(),
            lastLoginDate: Date(),
            phoneNumber: nil,
            preferences: UserPreferences(),
            notificationSettings: NotificationSettings()
        )
    }
    
    // 프로필 이미지 URL
    var profileImageURL: URL? {
        guard let urlString = profileImageUrl else { return nil }
        return URL(string: urlString)
    }
    
    // 계정 생성일 문자열
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
    
    // 마지막 로그인 문자열
    var formattedLastLoginDate: String? {
        guard let lastLoginDate = lastLoginDate else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastLoginDate)
    }
    
    // 프로필 이미지 또는 이니셜 생성
    func getProfileImage(size: CGFloat = 40, completion: @escaping (UIImage) -> Void) {
        // 프로필 이미지가 있는 경우 비동기 로드
        if let urlString = profileImageUrl, let url = URL(string: urlString) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        completion(image)
                    }
                    return
                }
                
                // 이미지 로드 실패시 이니셜 이미지 생성
                DispatchQueue.main.async {
                    completion(self.createInitialsImage(size: size))
                }
            }
        } else {
            // 이미지 URL이 없는 경우 이니셜 이미지 생성
            completion(createInitialsImage(size: size))
        }
    }
    
    // 이니셜 이미지 생성
    private func createInitialsImage(size: CGFloat) -> UIImage {
        let initials = String(name.split(separator: " ").map { $0.prefix(1) }.joined())
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            // 배경 그리기
            UIColor.systemBlue.setFill()
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            context.cgContext.fillEllipse(in: rect)
            
            // 텍스트 설정
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: size * 0.4, weight: .medium)
            ]
            
            // 텍스트 크기 계산
            let text = initials as NSString
            let textSize = text.size(withAttributes: attributes)
            
            // 텍스트 그리기 (중앙 정렬)
            let textRect = CGRect(
                x: (size - textSize.width) / 2,
                y: (size - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
}
