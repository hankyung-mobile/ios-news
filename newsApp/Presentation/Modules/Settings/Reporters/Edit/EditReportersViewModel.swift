//
//  EditReportersViewModel.swift
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
    
    private var reporters: [Reporter] = [] // 원본 기자 데이터 저장
    
    // Section별로 그룹화된 데이터
    private var groupedItems: [String: [Reporter]] = [:]
    private var sectionTitles: [String] = []
    
    // Section Index 타이틀 배열
    var sectionIndexTitles: [String] {
        return sectionTitles
    }
    
    var numberOfSections: Int {
        return sectionTitles.count
    }
    
    func numberOfItems(in section: Int) -> Int {
        guard section < sectionTitles.count else { return 0 }
        let sectionTitle = sectionTitles[section]
        return groupedItems[sectionTitle]?.count ?? 0
    }
    
    func item(at indexPath: IndexPath) -> Reporter? {
        guard indexPath.section < sectionTitles.count else { return nil }
        let sectionTitle = sectionTitles[indexPath.section]
        return groupedItems[sectionTitle]?[indexPath.row]
    }
    
    func sectionForIndex(title: String) -> Int {
        return sectionTitles.firstIndex(of: title) ?? 0
    }
    
    // 기존 방식과의 호환성을 위한 메서드들
    var itemCount: Int {
        return reporters.count
    }
    
    func item(at index: Int) -> Reporter? {
        guard index >= 0 && index < reporters.count else { return nil }
        return reporters[index]
    }
    
    func shouldLoadMore(at indexPath: IndexPath) -> Bool {
        // 전체 아이템 수로 무한스크롤 체크
        let currentItemIndex = getCurrentItemIndex(for: indexPath)
        
        let shouldLoad = currentItemIndex >= itemCount - 5 &&
                         !isLoading &&
                         hasMoreData &&
                         reporters.count >= 10
        
        if shouldLoad {
            print("📱 다음 기자 목록 페이지 로드 조건 만족: itemIndex=\(currentItemIndex), itemCount=\(itemCount), isLoading=\(isLoading), hasMoreData=\(hasMoreData)")
        }
        
        return shouldLoad
    }
    
    private func getCurrentItemIndex(for indexPath: IndexPath) -> Int {
        var currentIndex = 0
        for i in 0..<indexPath.section {
            currentIndex += numberOfItems(in: i)
        }
        currentIndex += indexPath.row
        return currentIndex
    }
    
    // 데이터를 알파벳/한글 초성별로 그룹화
    private func groupItemsByFirstLetter() {
        groupedItems.removeAll()
        
        for item in reporters {
            let firstLetter = getFirstCharacter(from: item.reporterName ?? "")
            
            if groupedItems[firstLetter] == nil {
                groupedItems[firstLetter] = []
            }
            groupedItems[firstLetter]?.append(item)
        }
        
        // 섹션 타이틀 정렬
        sectionTitles = Array(groupedItems.keys).sorted { first, second in
            // 한글 초성을 앞에, 영문을 뒤에 정렬
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
        
        // 각 섹션 내 데이터 정렬
        for key in sectionTitles {
            groupedItems[key]?.sort { $0.reporterName ?? "" < $1.reporterName ?? "" }
        }
    }
    
    private func getFirstCharacter(from text: String) -> String {
        guard let firstChar = text.first else { return "#" }
        
        let unicode = firstChar.unicodeScalars.first?.value ?? 0
        
        // 한글인 경우 초성 추출
        if unicode >= 0xAC00 && unicode <= 0xD7A3 {
            let index = (unicode - 0xAC00) / 28 / 21
            let initials = ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
            return initials[Int(index)]
        }
        
        // 영문인 경우 대문자로 변환
        if firstChar.isLetter {
            return String(firstChar.uppercased())
        }
        
        return "#"
    }
    
    private func isKoreanInitial(_ char: String) -> Bool {
        let koreanInitials = ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
        return koreanInitials.contains(char)
    }
    
    // 삭제 기능을 위한 메서드
    func deleteItem(at indexPath: IndexPath) {
        guard indexPath.section < sectionTitles.count else { return }
        let sectionTitle = sectionTitles[indexPath.section]
        
        // 해당 섹션에서 아이템 제거
        guard var sectionItems = groupedItems[sectionTitle],
              indexPath.row < sectionItems.count else { return }
        
        let removedItem = sectionItems.remove(at: indexPath.row)
        groupedItems[sectionTitle] = sectionItems
        
        // 원본 배열에서도 제거
        if let originalIndex = reporters.firstIndex(where: { $0.no == removedItem.no }) {
            reporters.remove(at: originalIndex)
        }
        
        // 섹션이 비어있으면 섹션 자체 제거
        if sectionItems.isEmpty {
            groupedItems.removeValue(forKey: sectionTitle)
            if let sectionIndex = sectionTitles.firstIndex(of: sectionTitle) {
                sectionTitles.remove(at: sectionIndex)
            }
        }
        
        // UI 업데이트
        items.accept(reporters)
    }
    
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
                    
                    // 기자 데이터 저장
                    self.reporters = newReporters ?? []
                    
                    // 데이터 그룹화
                    self.groupItemsByFirstLetter()
                    
                    // UI 업데이트
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
                    
                    // 기존 목록에 추가
                    self.reporters.append(contentsOf: filteredNewReporters ?? [])
                    
                    // 데이터 재그룹화
                    self.groupItemsByFirstLetter()
                    
                    // UI 업데이트
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
    
    func deleteItemFromServer(_ item: Reporter, completion: @escaping (Bool) -> Void) {
        let deleteParameters = String(item.no ?? 0)
        let params = getUserTokensParams()
        
        UserService.shared.deleteReportersData(no: deleteParameters, parameters: params)
            .subscribe(
                onNext: { response in
                    completion(true)
                },
                onError: { error in
                    print("삭제 실패: \(error)")
                    completion(false)
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
    
    // 디버깅을 위한 현재 상태 출력
    func printCurrentState() {
        print("📱 기자 목록 현재 상태:")
        print("   - currentPage: \(currentPage)")
        print("   - isLoading: \(isLoading)")
        print("   - hasMoreData: \(hasMoreData)")
        print("   - reporters.count: \(reporters.count)")
        print("   - sections.count: \(numberOfSections)")
        print("   - sectionTitles: \(sectionTitles)")
    }
}
