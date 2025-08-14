//  EditReportersViewModel.swift (간단 버전)
//  newsApp
//
//  Created by jay on 7/18/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

class EditReportersViewModel {
    
    private let disposeBag = DisposeBag()
    private var currentPage = 1
    private var isLoading = false
    private var hasMoreData = true
    private var baseParameters: [String: Any] = [:]
    
    // UI가 구독할 Observable들
    let items = BehaviorRelay<[Reporter]>(value: [])
    let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    let errorRelay = PublishRelay<String>()
    
    private var reporters: [Reporter] = [] // 단일 데이터 소스
    
    // 🎯 섹션 타입 - 간단하게
    enum SectionType: Int, CaseIterable {
        case header = 0
        case reporters = 1
    }
    
    var numberOfSections: Int {
        return SectionType.allCases.count
    }
    
    func numberOfItems(in section: Int) -> Int {
        guard let sectionType = SectionType(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .header:
            return reporters.isEmpty ? 0 : 1
        case .reporters:
            return reporters.count
        }
    }
    
    func item(at indexPath: IndexPath) -> Reporter? {
        guard let sectionType = SectionType(rawValue: indexPath.section) else { return nil }
        
        switch sectionType {
        case .header:
            return nil
        case .reporters:
            guard indexPath.row >= 0 && indexPath.row < reporters.count else { return nil }
            return reporters[indexPath.row]
        }
    }
    
    var itemCount: Int {
        return reporters.count
    }
    
    func shouldLoadMore(at indexPath: IndexPath) -> Bool {
        guard let sectionType = SectionType(rawValue: indexPath.section) else { return false }
        guard sectionType == .reporters else { return false }
        
        return indexPath.row >= itemCount - 5 &&
               !isLoading &&
               hasMoreData &&
               reporters.count >= 10
    }
    
    // 🎯 Section Index - fastSearch를 위한 정렬된 버전
    var sectionIndexTitles: [String] {
        let uniqueInitials = Set(reporters.compactMap { reporter in
            getFirstCharacter(from: reporter.reporterName ?? "")
        })
        
        // 한글 초성과 영문 분리하여 정렬
        let sortedInitials = uniqueInitials.sorted { first, second in
            let firstIsKorean = isKoreanInitial(first)
            let secondIsKorean = isKoreanInitial(second)
            
            if firstIsKorean && !secondIsKorean {
                return true
            } else if !firstIsKorean && secondIsKorean {
                return false
            } else {
                return first < second
            }
        }
        
        return sortedInitials
    }
    
    func sectionForIndex(title: String) -> Int {
        // 해당 초성의 첫 번째 기자 찾기 (현재 정렬된 상태에서)
        for (index, reporter) in reporters.enumerated() {
            if getFirstCharacter(from: reporter.reporterName ?? "") == title {
                return index
            }
        }
        return 0
    }
    
    private func isKoreanInitial(_ char: String) -> Bool {
        let koreanInitials = ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
        return koreanInitials.contains(char)
    }
    
    private func getFirstCharacter(from text: String) -> String {
        guard let firstChar = text.first else { return "#" }
        let unicode = firstChar.unicodeScalars.first?.value ?? 0
        
        // 한글 초성
        if unicode >= 0xAC00 && unicode <= 0xD7A3 {
            let index = (unicode - 0xAC00) / 28 / 21
            let initials = ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
            return initials[Int(index)]
        }
        
        // 영문
        if firstChar.isLetter {
            return String(firstChar.uppercased())
        }
        
        return "#"
    }
    
    // 삭제 - 간단하게
    func deleteItem(at indexPath: IndexPath) {
        guard let sectionType = SectionType(rawValue: indexPath.section),
              sectionType == .reporters,
              indexPath.row >= 0 && indexPath.row < reporters.count else { return }
        
        reporters.remove(at: indexPath.row)
        items.accept(reporters)
    }
    
    // 파라미터와 함께 첫 페이지 로드
    func loadFirstPage(with parameters: [String: Any]) {
        guard !isLoading else { return }
        
        baseParameters = parameters
        currentPage = 1
        isLoading = true
        hasMoreData = true
        isLoadingRelay.accept(true)
        
        reporters = []
        items.accept([])
        
        var params = parameters
        
        UserService.shared.reportersData(parameters: params)
            .subscribe(
                onNext: { [weak self] response in
                    self?.isLoading = false
                    self?.isLoadingRelay.accept(false)
                    
                    guard let self = self else { return }
                    let newReporters = response.data?.list
                    
                    if newReporters?.isEmpty ?? true {
                        self.hasMoreData = false
                        self.items.accept([])
                        return
                    }
                    
                    self.reporters = newReporters ?? []
                    // 🎯 fastSearch를 위해 이름순 정렬
                    self.reporters.sort { $0.reporterName ?? "" < $1.reporterName ?? "" }
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
        
        var params = baseParameters
        params["page"] = currentPage
        
        UserService.shared.reportersData(parameters: params)
            .subscribe(
                onNext: { [weak self] response in
                    self?.isLoading = false
                    
                    guard let self = self else { return }
                    let newReporters = response.data?.list
                    
                    if newReporters?.isEmpty ?? true {
                        self.hasMoreData = false
                        return
                    }
                    
                    // 중복 제거
                    let existingIDs = Set(self.reporters.map { $0.no })
                    let filteredNewReporters = newReporters?.filter { !existingIDs.contains($0.no) }
                    
                    if filteredNewReporters?.isEmpty ?? true {
                        self.hasMoreData = false
                        return
                    }
                    
                    if newReporters?.count ?? 0 < 20 {
                        self.hasMoreData = false
                    }
                    
                    self.reporters.append(contentsOf: filteredNewReporters ?? [])
                    // 🎯 fastSearch를 위해 이름순 정렬
                    self.reporters.sort { $0.reporterName ?? "" < $1.reporterName ?? "" }
                    self.items.accept(self.reporters)
                },
                onError: { [weak self] error in
                    self?.isLoading = false
                    self?.currentPage -= 1
                    self?.errorRelay.accept("네트워크 상태를 확인해주세요.")
                }
            )
            .disposed(by: disposeBag)
    }
    
    func deleteItemFromServer(_ item: Reporter, completion: @escaping (Bool) -> Void) {
        let deleteParameters = String(item.no ?? 0)
        let params = getUserTokensParams()
        
        UserService.shared.deleteReportersData(no: deleteParameters, parameters: params)
            .subscribe(
                onNext: { response in
                    completion(true)
                },
                onError: { error in
                    completion(false)
                }
            )
            .disposed(by: disposeBag)
    }
    
    func refresh() {
        if isLoading {
            isLoading = false
            isLoadingRelay.accept(false)
        }
        loadFirstPage(with: baseParameters)
    }
}
