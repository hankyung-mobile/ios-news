//
//  StockSearchViewModel.swift
//  newsApp
//
//  Created by jay on 7/29/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

class StockSearchViewModel {
    
    private let disposeBag = DisposeBag()
    private var currentPage = 1
    private var isLoading = false
    private var hasMoreData = true
    private var baseParameters: [String: Any] = [:]
    private var currentQuery: String = ""
    
    private let maxItemCount = 100
    
    // UI가 구독할 Observable들
    let items = BehaviorRelay<[StockItem]>(value: [])
    let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    let errorRelay = PublishRelay<String>()
    
    private var searchResults: [StockItem] = []
    
    // 검색 실행 (첫 페이지)
    func performSearch(query: String) {
        guard !isLoading else { return }
        
        // 검색 상태 저장
        currentQuery = query
        
        // 검색 파라미터 설정
        baseParameters = [
            "keyword": query,
        ]
        
        loadFirstPage()
    }
    
    // 첫 페이지 로드
    private func loadFirstPage() {
        guard !isLoading else { return }
        
        currentPage = 1
        isLoading = true
        hasMoreData = true
        isLoadingRelay.accept(true)
        
        // 첫 페이지 로드 시 기존 데이터 초기화
        searchResults = []
        items.accept([])
        
        // 파라미터에 페이지 추가
        var params = baseParameters
        params["page"] = currentPage
        
        // API 호출
        UserService.shared.getFinance(parameters: params)
            .subscribe(
                onNext: { [weak self] response in
                    self?.handleSearchResponse(response, isFirstPage: true)
                },
                onError: { [weak self] error in
                    self?.handleError(error)
                }
            )
            .disposed(by: disposeBag)
    }
    
    // 다음 페이지 로드
    func loadNextPage() {
        guard !isLoading && hasMoreData && !currentQuery.isEmpty && searchResults.count < maxItemCount else {
            return
        }
        
        print("📰 다음 페이지 로드: \(currentPage + 1)")
        
        currentPage += 1
        isLoading = true
        
        // 기본 파라미터에 새로운 페이지 번호 추가
        var params = baseParameters
        params["page"] = currentPage
        
        UserService.shared.getFinance(parameters: params)
            .subscribe(
                onNext: { [weak self] response in
                    self?.handleSearchResponse(response, isFirstPage: false)
                },
                onError: { [weak self] error in
                    self?.handleLoadMoreError(error)
                }
            )
            .disposed(by: disposeBag)
    }
    
    // 검색 응답 처리
    private func handleSearchResponse(_ response: Stock, isFirstPage: Bool) {
        isLoading = false
        isLoadingRelay.accept(false)
        
        guard response.isSuccess else {
            errorRelay.accept("검색 실패: \(String(describing: response.message))")
            return
        }
        
        let newResults = response.data?.list
        
        // 빈 결과 처리
        if ((newResults?.isEmpty) == true) {
            if isFirstPage {
                searchResults = []
                items.accept([])
                print("📰 검색 결과 없음")
            } else {
                hasMoreData = false
                print("📰 더 이상 불러올 데이터가 없습니다.")
            }
            return
        }
        
        if isFirstPage {
            // ✅ 간단하게: 100개까지만 저장
            searchResults = Array((newResults ?? []).prefix(maxItemCount))
            
            if searchResults.count >= maxItemCount {
                hasMoreData = false
            }
            
            print("📰 첫 페이지 로드 완료: \(searchResults.count)개")
        } else {
            // 추가 페이지: 중복 제거 후 추가
            let existingIDs = Set(searchResults.map { $0.code })
            let filteredResults = newResults?.filter { !existingIDs.contains($0.code) }
            
            if ((filteredResults?.isEmpty) == true) {
                hasMoreData = false
                print("📰 모든 데이터가 중복되어 더 이상 불러올 데이터가 없습니다.")
                return
            }
            
            // ✅ 간단하게: 100개까지만 추가
            let remainingSlots = maxItemCount - searchResults.count
            let resultsToAdd = Array((filteredResults ?? []).prefix(remainingSlots))
            
            searchResults.append(contentsOf: resultsToAdd)
            
            if searchResults.count >= maxItemCount {
                hasMoreData = false
            }
            
            print("📰 페이지 \(currentPage) 로드 완료: +\(resultsToAdd.count)개, 총 \(searchResults.count)개")
        }
        
//        // 마지막 페이지 체크
//        if currentPage >= response.data?.lastPage ?? 0 {
//            hasMoreData = false
//            print("📰 마지막 페이지 도달")
//        }
        
        // UI 업데이트
        items.accept(searchResults)
    }
    
    // 에러 처리
    private func handleError(_ error: Error) {
        isLoading = false
        isLoadingRelay.accept(false)
        errorRelay.accept("네트워크 상태를 확인해주세요.")
        print("📰 검색 실패: \(error)")
    }
    
    // 추가 로드 에러 처리
    private func handleLoadMoreError(_ error: Error) {
        isLoading = false
        currentPage -= 1  // 실패 시 페이지 번호 되돌리기
        errorRelay.accept("네트워크 상태를 확인해주세요.")
        print("📰 페이지 로드 실패: \(error)")
    }
    
    // 새로고침
    func refresh() {
        guard !currentQuery.isEmpty else { return }
        
        if isLoading {
            isLoading = false
            isLoadingRelay.accept(false)
        }
        
        print("📰 새로고침")
        loadFirstPage()
    }
    
    // 현재 아이템 개수
    var itemCount: Int {
        return items.value.count
    }
    
    // 특정 인덱스의 아이템
    func item(at index: Int) -> StockItem? {
        let itemArray = items.value
        guard index >= 0 && index < itemArray.count else { return nil }
        return itemArray[index]
    }
    
    // 무한스크롤 체크
    func shouldLoadMore(at index: Int) -> Bool {
        let shouldLoad = index >= itemCount - 5 &&
                        !isLoading &&
                        hasMoreData &&
                        !currentQuery.isEmpty &&
                        searchResults.count >= 10  // 최소 10개 이상일 때만 다음 페이지 로드
        
        if shouldLoad {
            print("📰 다음 페이지 로드 조건 만족: index=\(index), itemCount=\(itemCount), searchResults.count=\(searchResults.count)/\(maxItemCount)")
        }
        
        return shouldLoad
    }
    
    // 현재 상태 확인
    var hasSearchResults: Bool {
        return !currentQuery.isEmpty && !searchResults.isEmpty
    }
    
    var currentSearchQuery: String {
        return currentQuery
    }
    
    // 아이템 직접 설정 (최근 본 뉴스용)
    func setItems(_ items: [StockItem]) {
        // ✅ 수정: setItems에서도 10개 제한 적용
        let limitedItems = Array(items.prefix(10))
        searchResults = limitedItems
        self.items.accept(limitedItems)
        isLoadingRelay.accept(false)
        print("📰 최근 본 뉴스 설정: \(limitedItems.count)개")
    }
    
    // 아이템 클리어
    func clearItems() {
        searchResults = []
        items.accept([])
        isLoadingRelay.accept(false)
    }
    
    // 디버깅을 위한 현재 상태 출력
    func printCurrentState() {
        print("   - currentQuery: '\(currentQuery)'")
        print("   - currentPage: \(currentPage)")
        print("   - isLoading: \(isLoading)")
        print("   - hasMoreData: \(hasMoreData)")
        print("   - searchResults.count: \(searchResults.count)/\(maxItemCount)")
        print("   - items.count: \(itemCount)")
    }
}

