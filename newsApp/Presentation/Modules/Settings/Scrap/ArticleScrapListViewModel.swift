//
//  ArticleScrapListViewModel.swift
//  newsApp
//
//  Created by jay on 7/7/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

class ArticleScrapListViewModel {
    
    private let disposeBag = DisposeBag()
    private var currentPage = 1
    private var isLoading = false
    private var hasMoreData = true  // ✅ 추가: 더 불러올 데이터가 있는지 체크
    private var baseParameters: [String: Any] = [:]
    
    // UI가 구독할 Observable들
    let items = BehaviorRelay<[ScrapItem]>(value: [])  // ✅ 추가: 스크랩 아이템 직접 사용
    let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    let errorRelay = PublishRelay<String>()
    
    private var newsScraps: [ScrapItem] = []  // 원본 스크랩 데이터 저장
    
    // 파라미터와 함께 첫 페이지 로드
    func loadFirstPage(with parameters: [String: Any]) {
        guard !isLoading else { return }
        
//        ArticleScrapListViewCell.clearCache()
        
        // 기본 파라미터 저장
        baseParameters = parameters
        
        currentPage = 1
        isLoading = true
        hasMoreData = true  // ✅ 추가: 첫 페이지 로드 시 hasMoreData 초기화
        isLoadingRelay.accept(true)
        
        // 첫 페이지 로드 시 기존 데이터 초기화
        newsScraps = []
        items.accept([])  // ✅ 추가: UI 업데이트
        
        // 전달받은 파라미터에 페이지 추가
        var params = parameters
        params["page"] = currentPage
        
        UserService.shared.scrapListData(parameters: params)
            .subscribe(
                onNext: { [weak self] response in
                    self?.isLoading = false
                    self?.isLoadingRelay.accept(false)
                    
                    guard let self = self else { return }
                    let newScraps = response.data?.list
                    
                    // ✅ 추가: 첫 페이지부터 빈 데이터가 오면 hasMoreData = false
                    if ((newScraps?.isEmpty) == true) {
                        self.hasMoreData = false
                        self.items.accept([])  // 빈 배열로 UI 업데이트
                        return
                    }
                    
                    // 스크랩 데이터 저장
                    self.newsScraps = newScraps ?? []
                    
                    // ✅ 추가: UI 업데이트
                    self.items.accept(self.newsScraps)
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
        guard !isLoading && hasMoreData else { return }  // ✅ 수정: hasMoreData 조건 추가
        
        currentPage += 1
        isLoading = true
        
        // 기본 파라미터에 새로운 페이지 번호 추가
        var params = baseParameters
        params["page"] = currentPage
        
        UserService.shared.scrapListData(parameters: params)
            .subscribe(
                onNext: { [weak self] response in
                    self?.isLoading = false
                    
                    guard let self = self else { return }
                    let newScraps = response.data?.list
                    
                    // ✅ 추가: 서버에서 빈 배열이 오면 더 이상 데이터가 없음
                    if ((newScraps?.isEmpty) == true) {
                        self.hasMoreData = false
                        print("📱 더 이상 불러올 스크랩 데이터가 없습니다.")
                        return
                    }
                    
                    // 중복 제거
                    let existingIDs = Set(self.newsScraps.map { $0.aid })
                    let filteredNewScraps = newScraps?.filter { !existingIDs.contains($0.aid) }
                    
                    // ✅ 추가: 실제로 추가된 새 데이터가 없다면 hasMoreData = false
                    if ((filteredNewScraps?.isEmpty) == true) {
                        self.hasMoreData = false
                        print("📱 모든 스크랩 데이터가 중복되어 더 이상 불러올 데이터가 없습니다.")
                        return
                    }
                    
                    // ✅ 추가: 새로 받은 데이터가 기존 페이지보다 적으면 마지막 페이지일 가능성
                    if newScraps?.count ?? 0 < 20 {  // 페이지당 20개씩 온다고 가정
                        self.hasMoreData = false
                        print("📱 마지막 스크랩 페이지입니다.")
                    }
                    
                    // 기존 스크랩에 추가
                    self.newsScraps.append(contentsOf: filteredNewScraps ?? [])
                    
                    // ✅ 추가: UI 업데이트
                    self.items.accept(self.newsScraps)
                    
                    print("📱 스크랩 페이지 \(self.currentPage) 로드 완료. 총 \(self.newsScraps.count)개 스크랩")
                },
                onError: { [weak self] error in
                    self?.isLoading = false
                    self?.currentPage -= 1  // 실패 시 페이지 번호 되돌리기
                    self?.errorRelay.accept("네트워크 상태를 확인해주세요.")
                    print("📱 스크랩 페이지 로드 실패: \(error)")
                }
            )
            .disposed(by: disposeBag)
    }
    
    func deleteScrapItems(items: [ScrapItem]) {
        // 선택된 아이템의 no 추출
        let nos = items.compactMap { $0.no }
        
        guard !nos.isEmpty else { return }
        
        let tokenParams = getUserTokensParams()
        var parameters: [String: Any] = [:]
         
         // 토큰 파라미터 복사
         for (key, value) in tokenParams {
             parameters[key] = value
         }
        
        parameters["no"] = nos.map { String($0) }
        
        UserService.shared.deleteScrapListData(parameters: parameters)
            .subscribe(
                onNext: { [weak self] response in
                    guard let self = self else { return }
                    
                    if response.code == 200 {
                        // 삭제 성공 - no로 필터링
                        self.loadFirstPage(with: self.baseParameters)
                        print("🗑️ 삭제 완료: \(nos.count)개 항목")
//                        self.errorRelay.accept("선택한 스크랩이 삭제되었습니다.")
                    } else {
                        self.errorRelay.accept("스크랩 삭제에 실패했습니다.")
                    }
                },
                onError: { [weak self] error in
                    self?.errorRelay.accept("스크랩 삭제 중 오류가 발생했습니다.")
                    print("🗑️ 삭제 에러: \(error)")
                }
            )
            .disposed(by: disposeBag)
    }
    
    func deleteScrapAllItems() {
        
        let tokenParams = getUserTokensParams()
        var parameters: [String: Any] = [:]
         
         // 토큰 파라미터 복사
        for (key, value) in tokenParams {
            parameters[key] = value
        }
        
        UserService.shared.deleteScrapListAllData(parameters: parameters)
            .subscribe(
                onNext: { [weak self] response in
                    guard let self = self else { return }
                    
                    if response.code == 200 {
                        // 삭제 성공 - no로 필터링
                        self.loadFirstPage(with: self.baseParameters)
//                        self.errorRelay.accept("선택한 스크랩이 삭제되었습니다.")
                    } else {
                        self.errorRelay.accept("스크랩 삭제에 실패했습니다.")
                    }
                },
                onError: { [weak self] error in
                    self?.errorRelay.accept("스크랩 삭제 중 오류가 발생했습니다.")
                    print("🗑️ 삭제 에러: \(error)")
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
        return items.value.count  // ✅ 수정: items.value.count 사용
    }
    
    // ✅ 추가: 특정 인덱스의 스크랩 아이템
    func item(at index: Int) -> ScrapItem? {
        let itemArray = items.value
        guard index >= 0 && index < itemArray.count else { return nil }
        return itemArray[index]
    }
    
    // 무한스크롤 체크
    func shouldLoadMore(at index: Int) -> Bool {
        let shouldLoad = index >= itemCount - 5 &&
                        !isLoading &&
                        hasMoreData &&
                        newsScraps.count >= 10  // ✅ 수정: newsScraps 사용
        
        if shouldLoad {
            print("📱 다음 스크랩 페이지 로드 조건 만족: index=\(index), itemCount=\(itemCount), isLoading=\(isLoading), hasMoreData=\(hasMoreData)")
        }
        
        return shouldLoad
    }
    
    // ✅ 추가: 디버깅을 위한 현재 상태 출력
    func printCurrentState() {
        print("📱 스크랩 현재 상태:")
        print("   - currentPage: \(currentPage)")
        print("   - isLoading: \(isLoading)")
        print("   - hasMoreData: \(hasMoreData)")
        print("   - newsScraps.count: \(newsScraps.count)")
        print("   - items.count: \(itemCount)")
    }
}
