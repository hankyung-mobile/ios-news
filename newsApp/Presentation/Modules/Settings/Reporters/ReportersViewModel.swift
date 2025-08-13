//
//  ReportersViewModel.swift
//  newsApp
//
//  Created by jay on 7/15/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

class ReportersViewModel {
    
    private let disposeBag = DisposeBag()
    private var currentPage = 1
    private var isLoading = false
    private var hasMoreData = true
    private var baseParameters: [String: Any] = [:]
    
    // UI가 구독할 Observable들
    let items = BehaviorRelay<[Reporter]>(value: [])
    let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    let errorRelay = PublishRelay<String>()
    
    private var reporters: [Reporter] = [] // 원본 기자 데이터 저장
    
    // 파라미터와 함께 첫 페이지 로드
    func loadFirstPage(with parameters: [String: Any]) {
        guard !isLoading else { return }
        
        // 기본 파라미터 저장
        baseParameters = parameters
        
        currentPage = 1
        isLoading = true
        hasMoreData = true
        isLoadingRelay.accept(true)
        
        // 첫 페이지 로드 시 기존 데이터 초기화
        reporters = []
        items.accept([])
        
        // 전달받은 파라미터에 페이지 추가
        var params = parameters
//        params["page"] = currentPage
        
        // NOTE: 서비스 호출 메서드명은 기존 것을 그대로 사용한다고 가정합니다.
        UserService.shared.reportersData(parameters: params)
            .subscribe(
                onNext: { [weak self] response in
                    self?.isLoading = false
                    self?.isLoadingRelay.accept(false)
                    
                    guard let self = self else { return }
                    let newReporters = response.data?.list
                    
                    // 첫 페이지부터 빈 데이터가 오면 hasMoreData = false
                    if newReporters?.isEmpty ?? true {
                        self.hasMoreData = false
                        self.items.accept([]) // 빈 배열로 UI 업데이트
                        return
                    }
                    
                    // 기자 데이터 저장 및 UI 업데이트
                    self.reporters = newReporters ?? []
                    self.items.accept(self.reporters)
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
        guard !isLoading && hasMoreData else { return }
        
        currentPage += 1
        isLoading = true
        
        // 기본 파라미터에 새로운 페이지 번호 추가
        var params = baseParameters
        params["page"] = currentPage
        
        // NOTE: 서비스 호출 메서드명은 기존 것을 그대로 사용한다고 가정합니다.
        UserService.shared.reportersData(parameters: params)
            .subscribe(
                onNext: { [weak self] response in
                    self?.isLoading = false
                    
                    guard let self = self else { return }
                    let newReporters = response.data?.list
                    
                    // 서버에서 빈 배열이 오면 더 이상 데이터가 없음
                    if newReporters?.isEmpty ?? true {
                        self.hasMoreData = false
                        print("📱 더 이상 불러올 기자 데이터가 없습니다.")
                        return
                    }
                    
                    // 중복 제거 (Reporter 모델의 고유 ID 'no' 사용)
                    let existingIDs = Set(self.reporters.map { $0.no })
                    let filteredNewReporters = newReporters?.filter { !existingIDs.contains($0.no) }
                    
                    // 실제로 추가된 새 데이터가 없다면 더 이상 데이터가 없음
                    if filteredNewReporters?.isEmpty ?? true {
                        self.hasMoreData = false
                        print("📱 모든 기자 데이터가 중복되어 더 이상 불러올 데이터가 없습니다.")
                        return
                    }
                    
                    // 새로 받은 데이터가 페이지당 아이템 수보다 적으면 마지막 페이지일 가능성
                    if newReporters?.count ?? 0 < 20 { // 페이지당 20개씩 온다고 가정
                        self.hasMoreData = false
                        print("📱 마지막 기자 목록 페이지입니다.")
                    }
                    
                    // 기존 목록에 추가 및 UI 업데이트
                    self.reporters.append(contentsOf: filteredNewReporters ?? [])
                    self.items.accept(self.reporters)
                    
                    print("📱 기자 목록 페이지 \(self.currentPage) 로드 완료. 총 \(self.reporters.count)명")
                },
                onError: { [weak self] error in
                    self?.isLoading = false
                    self?.currentPage -= 1 // 실패 시 페이지 번호 되돌리기
                    self?.errorRelay.accept("네트워크 상태를 확인해주세요.")
                    print("📱 기자 목록 페이지 로드 실패: \(error)")
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
    
    // 특정 인덱스의 기자 아이템
    func item(at index: Int) -> Reporter? {
        let itemArray = items.value
        guard index >= 0 && index < itemArray.count else { return nil }
        return itemArray[index]
    }
    
    // 무한스크롤 체크
    func shouldLoadMore(at index: Int) -> Bool {
        let shouldLoad = index >= itemCount - 5 &&
                         !isLoading &&
                         hasMoreData &&
                         reporters.count >= 10
        
        if shouldLoad {
            print("📱 다음 기자 목록 페이지 로드 조건 만족: index=\(index), itemCount=\(itemCount), isLoading=\(isLoading), hasMoreData=\(hasMoreData)")
        }
        
        return shouldLoad
    }
    
    // 디버깅을 위한 현재 상태 출력
    func printCurrentState() {
        print("📱 기자 목록 현재 상태:")
        print("   - currentPage: \(currentPage)")
        print("   - isLoading: \(isLoading)")
        print("   - hasMoreData: \(hasMoreData)")
        print("   - reporters.count: \(reporters.count)")
        print("   - items.count: \(itemCount)")
    }
}
