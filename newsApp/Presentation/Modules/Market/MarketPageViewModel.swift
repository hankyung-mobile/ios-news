//
//  MarketPageViewModel.swift
//  newsApp
//
//  Created by jay on 6/16/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Alamofire
import RxAlamofire

class MarketPageViewModel {
    // URLs 목록을 관리하는 BehaviorRelay
    let urls = BehaviorRelay<[URL]>(value: [])
    let currentPageIndex = BehaviorRelay<Int>(value: 0)
    
    // 페이지 전환 중 상태 추적
    let isTransitioning = BehaviorRelay<Bool>(value: false)
    
    // 로딩 상태 추가
    let isLoading = BehaviorRelay<Bool>(value: true)
    
    private let disposeBag = DisposeBag()
    
    // 프리미엄 데이터 상태를 UI에 노출
    let marketData: Driver<[MarketSlideItem]>
    
    init() {
        // 초기 로딩 상태 설정
        isLoading.accept(true)
        
        // AppDataManager의 변경사항을 옵저빙하여 마스터 데이터 업데이트
        marketData = AppDataManager.shared.marketData
            .map { $0?.data?.slide ?? [] } // 슬라이드 데이터만 추출
            .asDriver(onErrorJustReturn: [])
        
        // 마스터 데이터 변경 시 URL 목록 업데이트
        setupMasterDataObserver()
        
        // 전환 상태 모니터링
        setupTransitionMonitoring()
        
        // 로딩 상태 모니터링
        setupLoadingStateMonitoring()
    }
    
    private func setupMasterDataObserver() {
        AppDataManager.shared.marketData
            .compactMap { $0?.data?.slide ?? [] }
            .distinctUntilChanged { old, new in
                // 단순 비교로 변경
                old.map { $0.url } == new.map { $0.url }
            }
            .subscribe(onNext: { [weak self] slideData in
                self?.updateUrls(from: slideData)
                
                // 데이터를 받았으므로 로딩 완료
                if !slideData.isEmpty {
                    self?.isLoading.accept(false)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setupLoadingStateMonitoring() {
        // AppDataManager의 appData를 모니터링하여 로딩 상태 결정
        AppDataManager.shared.marketData
            .subscribe(onNext: { [weak self] masterData in
                if let data = masterData {
                    // 데이터가 있고 슬라이드가 비어있지 않으면 로딩 완료
                    self?.isLoading.accept(data.data?.slide?.isEmpty ?? true)
                } else {
                    // 데이터가 nil이면 아직 로딩 중
                    self?.isLoading.accept(true)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func updateUrls(from slideData: [MarketSlideItem]) {
        let urlStrings = slideData.compactMap { $0.url }
        let validUrls = urlStrings.compactMap { URL(string: $0) }
        urls.accept(validUrls)
        
        // URL이 변경되면 첫 번째 페이지로 리셋
//        if !validUrls.isEmpty && currentPageIndex.value >= validUrls.count {
//            currentPageIndex.accept(0)
//        }
    }
    
    private func setupTransitionMonitoring() {
        isTransitioning
            .skip(1)  // 초기값 스킵
            .filter { $0 == false }  // 전환 완료 시에만
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                // 전환 완료 후 상태 정리
                self.isTransitioning.accept(false)
            })
            .disposed(by: disposeBag)
    }
    
    // 페이지 이동 메서드 - 중복 호출 방지 추가
    func moveTo(index: Int) {
        // 이미 전환 중이거나 같은 페이지로 이동하려는 경우 무시
        guard !isTransitioning.value, index != currentPageIndex.value else { return }
        
        isTransitioning.accept(true)
        currentPageIndex.accept(index)
    }
    
    // 전환 완료 메서드
    func transitionCompleted() {
        isTransitioning.accept(false)
    }
}


