//
//  SectionListViewModel.swift
//  newsApp
//
//  Created by jay on 7/3/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

// 셀 타입 정의 (간단하게)
enum CellType {
    case news(NewsArticle)
    case banner   // 광고용 배너 하나만
}

class SectionListViewModel {
    
    private let disposeBag = DisposeBag()
    private var currentPage = 1
    private var isLoading = false
    private var hasMoreData = true
    private var baseParameters: [String: Any] = [:]
    
    // ✅ 간단하게: 최대 개수만 정의
    private let maxItemCount = 100
    
    // UI가 구독할 Observable들
    let items = BehaviorRelay<[CellType]>(value: [])
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
                        self.createMixedItems()
                        return
                    }
                    
                    // ✅ 간단하게: 100개까지만 저장
                    self.newsArticles = Array(newArticles.prefix(self.maxItemCount))
                    
                    // ✅ 간단하게: 100개 도달하면 hasMoreData = false
                    if self.newsArticles.count >= self.maxItemCount {
                        self.hasMoreData = false
                    }
                    
                    // 혼합 아이템 생성
                    self.createMixedItems()
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
        // ✅ 간단하게: 하나의 guard문으로 모든 조건 체크
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
                    
                    if newArticles.isEmpty {
                        self.hasMoreData = false
                        return
                    }
                    
                    // 중복 제거
                    let existingIDs = Set(self.newsArticles.map { $0.aid })
                    let filteredNewArticles = newArticles.filter { !existingIDs.contains($0.aid) }
                    
                    if filteredNewArticles.isEmpty {
                        self.hasMoreData = false
                        return
                    }
                    
                    // ✅ 간단하게: 100개까지만 추가
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
                    
                    // 혼합 아이템 재생성
                    self.createMixedItems()
                    print("📱 페이지 \(self.currentPage) 로드 완료. 총 \(self.newsArticles.count)개 뉴스")

                },
                onError: { [weak self] error in
                    self?.isLoading = false
                    self?.currentPage -= 1  // 실패 시 페이지 번호 되돌리기
                    self?.errorRelay.accept("네트워크 상태를 확인해주세요.")
                }
            )
            .disposed(by: disposeBag)
    }
    
    // 혼합 아이템 생성 (5번째 + 마지막에 배너 추가)
    private func createMixedItems() {
        var mixedItems: [CellType] = []
        
        if newsArticles.isEmpty {
//            mixedItems.append(.banner)
            items.accept(mixedItems)
            return
        }
        
        for (index, article) in newsArticles.enumerated() {
            // 5번째 위치에 배너 먼저 추가
            if index == 5 {  // 5번째 위치 (index 4)
//                mixedItems.append(.banner)
            }
            
            // 뉴스 아이템 추가
            mixedItems.append(.news(article))
        }
        
        // 마지막에도 배너 추가
        if !newsArticles.isEmpty {
//            mixedItems.append(.banner)
        }
        
        items.accept(mixedItems)
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
    func item(at index: Int) -> CellType? {
        let itemArray = items.value
        guard index >= 0 && index < itemArray.count else { return nil }
        return itemArray[index]
    }
    
    func shouldLoadMore(at index: Int) -> Bool {
        return index >= itemCount - 5 &&
        !isLoading &&
        hasMoreData &&
        newsArticles.count >= 10
    }
}
