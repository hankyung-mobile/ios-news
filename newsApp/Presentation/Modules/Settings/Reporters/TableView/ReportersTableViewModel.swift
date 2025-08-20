//
//  ReportersTableViewModel.swift
//  newsApp
//
//  Created by jay on 7/18/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

class ReportersTableViewModel {
    
    private let disposeBag = DisposeBag()
    private var currentPage = 1
    private var isLoading = false
    private(set) var hasMoreData = true
    private var baseParameters: [String: Any] = [:]
    private let maxItemCount = 100
    
    // UI가 구독할 Observable들 - NewsArticle 직접 사용
    let items = BehaviorRelay<[NewsArticle]>(value: [])
    let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    let errorRelay = PublishRelay<String>()
    
    private var newsArticles: [NewsArticle] = []
    
    // 파라미터와 함께 첫 페이지 로드
    func loadFirstPage(with parameters: [String: Any]) {
        guard !isLoading else { return }
        
        SectionListViewCell.clearCache()
        
        // 기본 파라미터 저장
        baseParameters = parameters
        
        currentPage = 1
        isLoading = true
        hasMoreData = true
        isLoadingRelay.accept(true)
        
        // 첫 페이지 로드 시 기존 데이터 초기화
        newsArticles = []
        items.accept([])
        
        // 전달받은 파라미터에 페이지 추가
        var params = parameters
        params["page"] = currentPage
        
        UserService.shared.sectionListData(parameters: params)
            .subscribe(
                onNext: { [weak self] response in
                    self?.isLoading = false
                    self?.isLoadingRelay.accept(false)
                    
                    guard let self = self else { return }
                    let newArticles = response.data?.list ?? []
                    
                    if newArticles.isEmpty {
                        self.hasMoreData = false
                        self.items.accept([])
                        return
                    }
                    
                    // ✅ 간단하게: 100개까지만 저장
                    self.newsArticles = Array(newArticles.prefix(self.maxItemCount))
                    
                    // ✅ 간단하게: 100개 도달하면 hasMoreData = false
                    if self.newsArticles.count >= self.maxItemCount {
                        self.hasMoreData = false
                    }
                    
                    // 뉴스 데이터 저장 및 UI 업데이트
                    self.newsArticles = newArticles
                    self.items.accept(self.newsArticles)
                },
                onError: { [weak self] error in
                    self?.isLoading = false
                    self?.isLoadingRelay.accept(false)
                    self?.errorRelay.accept("네트워크 상태를 확인해주세요.")
                }
            )
            .disposed(by: disposeBag)
    }
    
    // 다음 페이지 로드
    func loadNextPage() {
        guard !isLoading && hasMoreData && newsArticles.count < maxItemCount else {
            return
        }
        
        currentPage += 1
        isLoading = true
        
        // 기본 파라미터에 새로운 페이지 번호 추가
        var params = baseParameters
        params["page"] = currentPage
        
        UserService.shared.sectionListData(parameters: params)
            .subscribe(
                onNext: { [weak self] response in
                    self?.isLoading = false
                    
                    guard let self = self else { return }
                    let newArticles = response.data?.list ?? []
                    
                    // 서버에서 빈 배열이 오면 더 이상 데이터가 없음
                    if newArticles.isEmpty {
                        self.hasMoreData = false
                        print("📱 더 이상 불러올 데이터가 없습니다.")
                        return
                    }
                    
                    // 중복 제거
                    let existingIDs = Set(self.newsArticles.map { $0.aid })
                    let filteredNewArticles = newArticles.filter { !existingIDs.contains($0.aid) }
                    
                    // 실제로 추가된 새 데이터가 없다면 hasMoreData = false
                    if filteredNewArticles.isEmpty {
                        self.hasMoreData = false
                        return
                    }
                    
                    let remainingSlots = self.maxItemCount - self.newsArticles.count
                    let articlesToAdd = Array(filteredNewArticles.prefix(remainingSlots))
                    
                    // 기존 뉴스에 추가
                    self.newsArticles.append(contentsOf: articlesToAdd)
                    
                    // ✅ 간단하게: 100개 도달하면 hasMoreData = false
                    if self.newsArticles.count >= self.maxItemCount {
                        self.hasMoreData = false
                    }
                    
                    // 새로 받은 데이터가 기존 페이지보다 적으면 마지막 페이지일 가능성
                    if newArticles.count < 20 {  // 페이지당 20개씩 온다고 가정
                        self.hasMoreData = false
                    }
                    
                    // UI 업데이트
                    self.items.accept(self.newsArticles)
                    
                    print("📱 페이지 \(self.currentPage) 로드 완료. 총 \(self.newsArticles.count)개 뉴스")
                },
                onError: { [weak self] error in
                    self?.isLoading = false
                    self?.currentPage -= 1  // 실패 시 페이지 번호 되돌리기
                    self?.errorRelay.accept("네트워크 상태를 확인해주세요.")
                    print("📱 페이지 로드 실패: \(error)")
                }
            )
            .disposed(by: disposeBag)
    }
    
    // 새로고침
    func refresh() {
        if isLoading {
            isLoading = false
            isLoadingRelay.accept(false)
        }
        
        loadFirstPage(with: baseParameters)
    }
    
    // 현재 아이템 개수
    var itemCount: Int {
        return items.value.count
    }
    
    // 특정 인덱스의 아이템
    func item(at index: Int) -> NewsArticle? {
        let itemArray = items.value
        guard index >= 0 && index < itemArray.count else { return nil }
        return itemArray[index]
    }
    
    // 무한스크롤 체크
    func shouldLoadMore(at index: Int) -> Bool {
        let shouldLoad = index >= itemCount - 5 &&
                        !isLoading &&
                        hasMoreData &&
                        newsArticles.count >= 10  // 최소 10개 이상일 때만 다음 페이지 로드
        
        if shouldLoad {
            print("📱 다음 페이지 로드 조건 만족: index=\(index), itemCount=\(itemCount), isLoading=\(isLoading), hasMoreData=\(hasMoreData)")
        }
        
        return shouldLoad
    }
    
    // 디버깅을 위한 현재 상태 출력
    func printCurrentState() {
        print("📱 현재 상태:")
        print("   - currentPage: \(currentPage)")
        print("   - isLoading: \(isLoading)")
        print("   - hasMoreData: \(hasMoreData)")
        print("   - newsArticles.count: \(newsArticles.count)")
        print("   - items.count: \(itemCount)")
    }
}
