//
//  TermDetailViewModel.swift
//  newsApp
//
//  Created by jay on 7/29/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

class TermDetailViewModel {
    
    private let disposeBag = DisposeBag()
    
    // UI가 구독할 Observable들
    let items = BehaviorRelay<[TermDetailItem]>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)
    let error = PublishRelay<String>()
    
    // 검색 실행
    func search(seq: Int) {
        guard !String(seq).isEmpty else {
            items.accept([])
            return
        }
        
        isLoading.accept(true)
        
        UserService.shared.getSearchDictionaryDetail(seq: seq)
            .subscribe(
                onNext: { [weak self] response in
                    self?.isLoading.accept(false)
                    
                    if response.isSuccess {
                        // API가 단일 아이템을 반환하는 경우
                        if let item = response.data {
                            self?.items.accept([item])
                        } else {
                            self?.items.accept([])
                        }
                    } else {
                        self?.error.accept(response.message ?? "검색 실패")
                        self?.items.accept([])
                    }
                },
                onError: { [weak self] error in
                    self?.isLoading.accept(false)
                    self?.error.accept("네트워크 오류가 발생했습니다.")
                    self?.items.accept([])
                }
            )
            .disposed(by: disposeBag)
    }
    
    // 새로고침
    func refresh(seq: Int) {
        search(seq: seq)
    }
}
