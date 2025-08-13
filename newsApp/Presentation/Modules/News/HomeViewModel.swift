//
//  HomeViewModel.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

class HomeViewModel {
    // 서비스 의존성
    private let userService: UserService
    private let webContentService: WebContentService
    
    // 홈 화면 URL
    let homeUrl = "https://example.com/home"
    
    // 초기화
    init(userService: UserService, webContentService: WebContentService) {
        self.userService = userService
        self.webContentService = webContentService
    }
    
    // 사용자 정보 가져오기
//    func getUserInfo(completion: @escaping (Result<[String: Any], Error>) -> Void) {
//        userService.getCurrentUserInfo { result in
//            switch result {
//            case .success(let user):
//                // 사용자 정보를 웹뷰에 전달할 형태로 변환
//                let userInfo: [String: Any] = [
//                    "id": user.id,
//                    "name": user.name,
//                    "email": user.email,
//                    "isLoggedIn": true,
//                    "lastLogin": user.lastLoginDate?.timeIntervalSince1970 ?? 0
//                ]
//                completion(.success(userInfo))
//                
//            case .failure(let error):
//                // 기본 값 또는 에러 처리
//                let userInfo: [String: Any] = [
//                    "isLoggedIn": false,
//                    "error": error.localizedDescription
//                ]
//                completion(.success(userInfo)) // 에러여도 웹에서 처리할 수 있도록 성공으로 전달
//            }
//        }
//    }
    
    // 데이터 새로고침
//    func refreshData(completion: @escaping (Result<[String: Any], Error>) -> Void) {
//        // 웹컨텐츠 서비스를 통해 최신 데이터 가져오기
//        webContentService.getHomeContent { result in
//            switch result {
//            case .success(let content):
//                let data: [String: Any] = [
//                    "banners": content.banners,
//                    "recommendations": content.recommendations,
//                    "notices": content.notices,
//                    "timestamp": Date().timeIntervalSince1970
//                ]
//                completion(.success(data))
//                
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
}
