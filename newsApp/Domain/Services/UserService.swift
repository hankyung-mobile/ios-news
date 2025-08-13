//
//  UserService.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import RxSwift

/// 사용자 관련 서비스 프로토콜
protocol UserServiceProtocol {
    //    func login(username: String, password: String) -> Observable<User>
    //    func logout() -> Observable<Void>
    //    func isLoggedIn() -> Bool
}

/// 사용자 관련 서비스 구현
class UserService: UserServiceProtocol {
    // 싱글톤 인스턴스
    static let shared = UserService()
    
    // 네트워크 매니저
    private let networkManager = NetworkManager.shared
    
    // 현재 사용자 캐시
    private var currentUserCache: User?
    private var ad: AppInfoData?
    
    init() {}
    
    // MARK: - 캐시 관리
    
    /// 사용자 정보 캐시 초기화
    func clearUserCache() {
        currentUserCache = nil
    }
    
    // MARK: - 마스터 데이터 가져오기
    func masterData() -> Observable<Master> {
        return networkManager.request(APIRouter.getMaster, responseType: Master.self, retries: 2)
    }
    
    // MARK: - 뉴스 데이터 가져오기
    func newsData() -> Observable<News> {
        return networkManager.request(APIRouter.getNews, responseType: News.self, retries: 2)
    }
    
    // MARK: - 프리미엄 데이터 가져오기
    func premiumData() -> Observable<Premium> {
        return networkManager.request(APIRouter.getPremium, responseType: Premium.self, retries: 2)
    }
    
    // MARK: - 마켓 데이터 가져오기
    func marketData() -> Observable<Market> {
        return networkManager.request(APIRouter.getMarket, responseType: Market.self, retries: 2)
    }
    
    // MARK: - 뉴스 섹션 리스트 가져오기
    func sectionListData(parameters: [String: Any]? = nil) -> Observable<SectionList> {
        return networkManager.request(APIRouter.getSectionList, parameters: parameters, responseType: SectionList.self, retries: 2)
    }
    
    // MARK: - 기사 스크랩 리스트 가져오기
    func scrapListData(parameters: [String: Any]? = nil) -> Observable<ScrapList> {
        return networkManager.request(APIRouter.getScrapList, parameters: parameters, responseType: ScrapList.self, retries: 2)
    }
    
    // MARK: - 기사 스크랩 리스트 삭제
    func deleteScrapListData(parameters: [String: Any]? = nil) -> Observable<ScrapList> {
        return networkManager.request(APIRouter.deleteScrapList, parameters: parameters, responseType: ScrapList.self, retries: 2)
    }
    
    func deleteScrapListAllData(parameters: [String: Any]? = nil) -> Observable<ScrapList> {
        return networkManager.request(APIRouter.deleteScrapListAll, parameters: parameters, responseType: ScrapList.self, retries: 2)
    }
    
    // MARK: - 구독한 기자 리스트
    func reportersData(parameters: [String: Any]? = nil) -> Observable<Reporters> {
        return networkManager.request(APIRouter.getReporters, parameters: parameters, responseType: Reporters.self, retries: 2)
    }
    
    // MARK: - 구독한 기자 리스트 삭제
    func deleteReportersData(no: String? = nil, parameters: [String: Any]? = nil) -> Observable<Reporters> {
        return networkManager.request(APIRouter.deleteReporter(no: no ?? ""), parameters: parameters, responseType: Reporters.self, retries: 2)
    }
    
    // MARK: - 뉴스최신 검색
    func getSearchLatestNews(parameters: [String: Any]? = nil) -> Observable<Search> {
        return networkManager.request(APIRouter.getSearchLatestNews, parameters: parameters, responseType: Search.self, retries: 2)
    }
    
    // MARK: - 뉴스정확도 검색
    func getSearchAi(parameters: [String: Any]? = nil) -> Observable<AiSearch> {
        return networkManager.request(APIRouter.getSearchAi, parameters: parameters, responseType: AiSearch.self, retries: 2)
    }
    
    // MARK: - 종목 검색
    func getFinance(parameters: [String: Any]? = nil) -> Observable<Stock> {
        return networkManager.request(APIRouter.getSearchFinance, parameters: parameters, responseType: Stock.self, retries: 2)
    }
    
    // MARK: - 기자 검색
    func getSearchReporter(parameters: [String: Any]? = nil) -> Observable<ReporterSearch> {
        return networkManager.request(APIRouter.getSearchReporter, parameters: parameters, responseType: ReporterSearch.self, retries: 2)
    }
    
    // MARK: - 경제용어 검색
    func getSearchDictionary(parameters: [String: Any]? = nil) -> Observable<Term> {
        return networkManager.request(APIRouter.getSearchDictionary, parameters: parameters, responseType: Term.self, retries: 2)
    }
    
    // MARK: - 경제용어 상세
    func getSearchDictionaryDetail(seq: Int? = nil, parameters: [String: Any]? = nil) -> Observable<TermDetail> {
        return networkManager.request(APIRouter.getSearchDictionaryDetail(seq: seq ?? 0), parameters: parameters, responseType: TermDetail.self, retries: 2)
    }
    
    // MARK: - 푸시알림 내역
    func getPushList(parameters: [String: Any]? = nil) -> Observable<PushList> {
        return networkManager.request(APIRouter.getPushList, parameters: parameters, responseType: PushList.self, retries: 2)
    }
    
    // MARK: - 한경미디어그룹 리스트
    func getHKMediaList(parameters: [String: Any]? = nil) -> Observable<HKMedia> {
        return networkManager.request(APIRouter.getHKMediaList, parameters: parameters, responseType: HKMedia.self, retries: 2)
    }
}
