//
//  WebContentService.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import RxSwift

/// 웹 콘텐츠 서비스 프로토콜
protocol WebContentServiceProtocol {
//    func getHomeContent() -> Observable<WebContentResponse>
//    func getReservations(page: Int, limit: Int) -> Observable<[WebContent]>
//    func getReservationDetail(id: String) -> Observable<WebContent>
//    func getStockItems(page: Int, limit: Int) -> Observable<[WebContent]>
//    func getStockDetail(id: String) -> Observable<WebContent>
//    func getNotifications(page: Int, limit: Int) -> Observable<[WebContent]>
//    func markNotificationAsRead(id: String) -> Observable<Void>
//    func cacheWebContent(content: WebContent, htmlContent: String) -> Observable<WebContentCache>
//    func getCachedWebContent(contentId: String) -> Observable<WebContentCache?>
}

/// 웹 콘텐츠 서비스 구현
class WebContentService: WebContentServiceProtocol {
    // 싱글톤 인스턴스
    static let shared = WebContentService()
    
    // 네트워크 매니저
    private let networkManager = NetworkManager.shared
    
    // 웹 콘텐츠 캐시
    private var contentCache = [String: WebContentCache]()
    
    // 파일 관리자
    private let fileManager = FileManager.default
    
    // 캐시 디렉토리 URL
    private var cacheDirectoryURL: URL? {
        return try? fileManager.url(for: .cachesDirectory,
                                      in: .userDomainMask,
                                      appropriateFor: nil,
                                      create: true)
            .appendingPathComponent("WebContent", isDirectory: true)
    }
    
    private init() {
        createCacheDirectoryIfNeeded()
    }
    
    // MARK: - 홈 콘텐츠
    
    /// 홈 화면 콘텐츠 가져오기
//    func getHomeContent() -> Observable<WebContentResponse> {
//        return networkManager.request(APIRouter.getHomeContent)
//    }
//    
//    // MARK: - 예약 관련
//    
//    /// 예약 목록 가져오기
//    func getReservations(page: Int = 1, limit: Int = 20) -> Observable<[WebContent]> {
//        return networkManager.request(APIRouter.getReservations(page: page, limit: limit))
//    }
//    
//    /// 예약 상세 정보 가져오기
//    func getReservationDetail(id: String) -> Observable<WebContent> {
//        return networkManager.request(APIRouter.getReservationDetail(id: id))
//    }
//    
//    // MARK: - 재고 관련
//    
//    /// 재고 아이템 목록 가져오기
//    func getStockItems(page: Int = 1, limit: Int = 20) -> Observable<[WebContent]> {
//        return networkManager.request(APIRouter.getStockItems(page: page, limit: limit))
//    }
//    
//    /// 재고 아이템 상세 정보 가져오기
//    func getStockDetail(id: String) -> Observable<WebContent> {
//        return networkManager.request(APIRouter.getStockDetail(id: id))
//    }
//    
//    // MARK: - 알림 관련
//    
//    /// 알림 목록 가져오기
//    func getNotifications(page: Int = 1, limit: Int = 20) -> Observable<[WebContent]> {
//        return networkManager.request(APIRouter.getNotifications(page: page, limit: limit))
//    }
//    
//    /// 알림을 읽음 상태로 표시
//    func markNotificationAsRead(id: String) -> Observable<Void> {
//        return networkManager.requestEmpty(APIRouter.markNotificationAsRead(id: id))
//    }
    
    // MARK: - 캐시 관리
    
    /// 웹 콘텐츠 캐싱
    func cacheWebContent(content: WebContent, htmlContent: String) -> Observable<WebContentCache> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "WebContentService", code: -1, userInfo: nil))
                return Disposables.create()
            }
            
            let validUntil: Date?
            if let expiresAt = content.expiresAt {
                validUntil = expiresAt
            } else {
                // 기본 캐시 만료 시간 (1시간)
                validUntil = Date().addingTimeInterval(3600)
            }
            
            // 웹 콘텐츠 캐시 생성
            let cache = WebContentCache(
                contentId: content.id,
                htmlContent: htmlContent,
                timestamp: Date(),
                validUntil: validUntil
            )
            
            // 메모리 캐시에 저장
            self.contentCache[content.id] = cache
            
            // 디스크에 저장
            do {
                try self.saveContentCacheToDisk(cache)
                observer.onNext(cache)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    /// 캐시된 웹 콘텐츠 가져오기
    func getCachedWebContent(contentId: String) -> Observable<WebContentCache?> {
        // 메모리 캐시 확인
        if let cachedContent = contentCache[contentId], cachedContent.isValid {
            return Observable.just(cachedContent)
        }
        
        // 디스크 캐시 확인
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }
            
            do {
                if let cache = try self.loadContentCacheFromDisk(contentId: contentId), cache.isValid {
                    // 메모리 캐시 업데이트
                    self.contentCache[contentId] = cache
                    observer.onNext(cache)
                } else {
                    observer.onNext(nil)
                }
                observer.onCompleted()
            } catch {
                print("⚠️ 캐시 로딩 오류: \(error.localizedDescription)")
                observer.onNext(nil)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    /// 캐시 디렉토리 생성
    private func createCacheDirectoryIfNeeded() {
        guard let cacheDirectoryURL = cacheDirectoryURL else { return }
        
        if !fileManager.fileExists(atPath: cacheDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectoryURL,
                                              withIntermediateDirectories: true,
                                              attributes: nil)
            } catch {
                print("⚠️ 캐시 디렉토리 생성 오류: \(error.localizedDescription)")
            }
        }
    }
    
    /// 디스크에 콘텐츠 캐시 저장
    private func saveContentCacheToDisk(_ cache: WebContentCache) throws {
        guard let cacheDirectoryURL = cacheDirectoryURL else {
            throw NSError(domain: "WebContentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "캐시 디렉토리를 찾을 수 없습니다."])
        }
        
        let cacheFileURL = cacheDirectoryURL.appendingPathComponent("\(cache.contentId).json")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(cache)
        try data.write(to: cacheFileURL, options: .atomic)
    }
    
    /// 디스크에서 콘텐츠 캐시 로드
    private func loadContentCacheFromDisk(contentId: String) throws -> WebContentCache? {
        guard let cacheDirectoryURL = cacheDirectoryURL else {
            throw NSError(domain: "WebContentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "캐시 디렉토리를 찾을 수 없습니다."])
        }
        
        let cacheFileURL = cacheDirectoryURL.appendingPathComponent("\(contentId).json")
        
        // 파일이 존재하는지 확인
        if !fileManager.fileExists(atPath: cacheFileURL.path) {
            return nil
        }
        
        let data = try Data(contentsOf: cacheFileURL)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(WebContentCache.self, from: data)
    }
    
    /// 만료된 캐시 정리
    func clearExpiredCaches() {
        // 메모리 캐시 정리
        let now = Date()
        for (id, cache) in contentCache {
            if let validUntil = cache.validUntil, validUntil < now {
                contentCache.removeValue(forKey: id)
            }
        }
        
        // 디스크 캐시 정리
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self,
                  let cacheDirectoryURL = self.cacheDirectoryURL else { return }
            
            do {
                let fileURLs = try self.fileManager.contentsOfDirectory(at: cacheDirectoryURL,
                                                                     includingPropertiesForKeys: [.creationDateKey],
                                                                     options: .skipsHiddenFiles)
                
                for fileURL in fileURLs {
                    // JSON 파일만 처리
                    guard fileURL.pathExtension == "json" else { continue }
                    
                    do {
                        let data = try Data(contentsOf: fileURL)
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        
                        if let cache = try? decoder.decode(WebContentCache.self, from: data),
                           let validUntil = cache.validUntil,
                           validUntil < now {
                            // 만료된 캐시 삭제
                            try self.fileManager.removeItem(at: fileURL)
                        }
                    } catch {
                        print("⚠️ 캐시 파일 처리 오류: \(error.localizedDescription)")
                    }
                }
            } catch {
                print("⚠️ 캐시 디렉토리 읽기 오류: \(error.localizedDescription)")
            }
        }
    }
    
    /// 모든 캐시 정리
    func clearAllCaches() {
        // 메모리 캐시 정리
        contentCache.removeAll()
        
        // 디스크 캐시 정리
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self,
                  let cacheDirectoryURL = self.cacheDirectoryURL else { return }
            
            do {
                let fileURLs = try self.fileManager.contentsOfDirectory(at: cacheDirectoryURL,
                                                                     includingPropertiesForKeys: nil,
                                                                     options: .skipsHiddenFiles)
                
                for fileURL in fileURLs {
                    try self.fileManager.removeItem(at: fileURL)
                }
            } catch {
                print("⚠️ 캐시 삭제 오류: \(error.localizedDescription)")
            }
        }
    }
}
