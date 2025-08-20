//
//  SearchViewController.swift
//  newsApp
//
//  Created by jay on 7/24/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import WebKit
import RxSwift
import RxCocoa

// MARK: - 베이스 프로토콜
protocol SearchContentViewController: UIViewController {
    var pageIndex: Int { get set }
    var webNavigationDelegate: WebNavigationDelegate? { get set }
    
    func performSearch(with query: String)
}


class SearchViewController: UIViewController, UIGestureRecognizerDelegate {
    
    private let disposeBag = DisposeBag()
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var lyFooter: UIView!
    // @IBOutlet weak var noDataView: UIView!
    
    // PageViewController 추가
    private var pageViewController: UIPageViewController!
    private var pageContainerView: UIView!
    
    // 캐시된 뷰 컨트롤러들을 저장할 배열 - 프로토콜 타입으로 변경
    private var cachedContentViewControllers: [Int: SearchContentViewController] = [:]
    
    private var lastSearchQueries: [Int: String] = [:]
    
    // 뉴스 네비게이션 델리게이트 추가
    weak var webNavigationDelegate: WebNavigationDelegate?
    
    // 검색 데이터 (5개 고정)
    private let searchItems: [SearchItem] = [
        SearchItem(id: 1, title: "뉴스최신", category: "all"),
        SearchItem(id: 2, title: "뉴스 정확도", category: "news"),
        SearchItem(id: 3, title: "종목", category: "company"),
        SearchItem(id: 4, title: "기자", category: "person"),
        SearchItem(id: 5, title: "경제용어", category: "stock")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupButtonEvents()
        setupSearchBar()
        setupCollectionView()
        setupPageViewController()
        
        self.collectionView.reloadData()
        self.updatePageViewController()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(closeViewController),
            name: .closeSearchView,
            object: nil
        )
        
        // 화면 터치 시 키보드 내리기
         let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
         tapGesture.cancelsTouchesInView = false
         view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func closeViewController() {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupUI() {
        // 엣지 스와이프로 뒤로가기 (네비게이션 컨트롤러가 있는 경우)
        if navigationController != nil {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            navigationController?.interactivePopGestureRecognizer?.delegate = self
        }
        
        // noDataView 숨김 (데이터가 있으므로)
        // noDataView.isHidden = true
    }
    
    private func setupButtonEvents() {
        btnClose.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                // 네비게이션 컨트롤러가 있고 루트가 아닌 경우 pop
                if let navigationController = self?.navigationController,
                   navigationController.viewControllers.count > 1 {
                    navigationController.popViewController(animated: true)
                } else {
                    // 모달로 표시된 경우 dismiss
                    self?.dismiss(animated: true, completion: nil)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "검색어를 입력하세요"
        searchBar.tintColor = UIColor(named: "#1A1A1A")
        searchBar.returnKeyType = .search
        searchBar.enablesReturnKeyAutomatically = true
//        searchBar.autocorrectionType = .no
        searchBar.spellCheckingType = .no
        searchBar.searchTextField.layer.cornerRadius = 18
        searchBar.searchTextField.layer.masksToBounds = true
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    private func setupPageViewController() {
        // PageViewController 컨테이너 뷰 생성
        pageContainerView = UIView()
        pageContainerView.backgroundColor = UIColor.systemBackground
        view.addSubview(pageContainerView)
        
        // PageViewController 생성
        pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        // PageViewController를 자식으로 추가
        addChild(pageViewController)
        pageContainerView.addSubview(pageViewController.view)
        
        // Auto Layout 설정
        pageContainerView.translatesAutoresizingMaskIntoConstraints = false
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // PageContainer를 CollectionView 밑에 위치
            pageContainerView.topAnchor.constraint(equalTo: lyFooter.bottomAnchor, constant: 0),
            pageContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // PageViewController를 컨테이너에 꽉 채우기
            pageViewController.view.topAnchor.constraint(equalTo: pageContainerView.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: pageContainerView.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: pageContainerView.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: pageContainerView.bottomAnchor)
        ])
        
        pageViewController.didMove(toParent: self)
        // self.view.bringSubviewToFront(noDataView)
    }
    
    private func updatePageViewController() {
        if !searchItems.isEmpty {
            // 첫 번째 페이지로 설정
            let targetPage = createTableViewController(for: 0)
            pageViewController.setViewControllers([targetPage], direction: .forward, animated: false)
            
            // 첫 번째 셀 선택
            DispatchQueue.main.async {
                let indexPath = IndexPath(item: 0, section: 0)
                self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
            }
        }
    }
    
    // 🔥 핵심: 카테고리별로 다른 ViewController 생성 및 캐싱
    private func createTableViewController(for index: Int) -> UIViewController {
        // 캐시에서 먼저 찾기
        if let cachedVC = cachedContentViewControllers[index] {
            return cachedVC
        }
        
        // 카테고리별로 다른 ViewController 생성
        guard index < searchItems.count else { return UIViewController() }
        
        let item = searchItems[index]
        let contentVC: SearchContentViewController
        guard let newsVC = UIStoryboard(name: "SearchLatestNews", bundle: nil).instantiateViewController(withIdentifier: "SearchLatestNewsViewController") as? SearchLatestNewsViewController else {
            return SearchLatestNewsViewController()
        }
        guard let aiVC = UIStoryboard(name: "AiSearchView", bundle: nil).instantiateViewController(withIdentifier: "AiSearchViewController") as? AiSearchViewController else {
            return AiSearchViewController()
        }
        guard let stockVC = UIStoryboard(name: "Stock", bundle: nil).instantiateViewController(withIdentifier: "StockSearchViewController") as? StockSearchViewController else {
            return StockSearchViewController()
        }
        guard let reporterVC = UIStoryboard(name: "SearchReporters", bundle: nil).instantiateViewController(withIdentifier: "SearchReportersController") as? SearchReportersController else {
            return SearchReportersController()
        }
        guard let termVC = UIStoryboard(name: "Term", bundle: nil).instantiateViewController(withIdentifier: "TermSearchViewController") as? TermSearchViewController else {
            return TermSearchViewController()
        }
        
        switch item.category {
        case "all":      contentVC = newsVC
        case "news":     contentVC = aiVC
        case "company":  contentVC = stockVC
        case "person":   contentVC = reporterVC
        case "stock":    contentVC = termVC
        default:         contentVC = newsVC
        }
        newsVC.webNavigationDelegate = self.webNavigationDelegate
        aiVC.webNavigationDelegate = self.webNavigationDelegate
        stockVC.webNavigationDelegate = self.webNavigationDelegate
        reporterVC.webNavigationDelegate = self.webNavigationDelegate
        termVC.webNavigationDelegate = self.webNavigationDelegate
        
        // 필수 프로퍼티만 설정
        contentVC.pageIndex = index
        
        // 캐시에 저장
        cachedContentViewControllers[index] = contentVC
        
        return contentVC
    }
    
    private func goToPage(_ index: Int) {
        guard index < searchItems.count else { return }
        
        let currentIndex = getCurrentPageIndex()
        guard index != currentIndex else { return }
        
        let direction: UIPageViewController.NavigationDirection = index > currentIndex ? .forward : .reverse
        let targetVC = createTableViewController(for: index)
        
        pageViewController.setViewControllers([targetVC], direction: direction, animated: true)
        
        // 탭 변경 시 자동 검색 실행
        performAutoSearchOnTabChange(for: index)
    }
    
    // 탭 변경 시 자동 검색 기능
    private func performAutoSearchOnTabChange(for index: Int) {
        guard let searchText = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            print("탭 변경 검색어 없음")
            return
        }
        
        // 해당 탭에서 이미 이 검색어로 검색했는지 확인
        if let lastQuery = lastSearchQueries[index], lastQuery == searchText {
            print("탭 변경 중복 검색 방지: '\(searchText)' (탭 \(index) - \(searchItems[index].title))")
            return
        }
        
        // 해당 탭에서 처음 검색하는 경우 → 검색 실행
        print("탭 변경 새로운 검색 실행: '\(searchText)' (탭 \(index) - \(searchItems[index].title))")
        
        if let targetVC = cachedContentViewControllers[index] {
            targetVC.performSearch(with: searchText)
            lastSearchQueries[index] = searchText
            print("탭 \(index)에 검색어 저장: '\(searchText)'")
        }
    }
    
    private func getCurrentPageIndex() -> Int {
        if let currentVC = pageViewController.viewControllers?.first as? SearchContentViewController {
            return currentVC.pageIndex
        }
        return 0
    }
    
    private func performSearch(with query: String) {
        let currentIndex = getCurrentPageIndex()
        
//        // 현재 탭에서 중복 검색 방지
//        if let lastQuery = lastSearchQueries[currentIndex], lastQuery == query {
//            print("🔍 현재 탭 중복 검색 방지 - 이미 검색한 쿼리: '\(query)' (탭 \(currentIndex) - \(searchItems[currentIndex].title))")
//            return
//        }
        
        print("🔍 검색 실행: '\(query)' (탭 \(currentIndex) - \(searchItems[currentIndex].title))")
        
        // 현재 탭에서 검색 실행
        if let currentVC = pageViewController.viewControllers?.first as? SearchContentViewController {
            currentVC.performSearch(with: query)
            lastSearchQueries[currentIndex] = query
            print("💾 현재 탭(\(currentIndex))에 검색어 저장: '\(query)'")
        }
    }
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !searchText.isEmpty else {
            return
        }
        
        print("🔍 검색 버튼 클릭: '\(searchText)'")
        print("📱 현재 모든 탭 검색 상태:")
        for (index, query) in lastSearchQueries {
            print("   탭 \(index)(\(searchItems[index].title)): '\(query)'")
        }
        
        performSearch(with: searchText)
        searchBar.resignFirstResponder()
    }
    
    // 검색 시작
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }
    
    // 취소 버튼 클릭
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 글자 수 체크
        if checkTextLimit(searchText) {
            // 제한 초과 시 이전 텍스트로 복원
            searchBar.text = String(searchText.dropLast())
            return
        }

        
        // 텍스트가 완전히 비어있을 때만 실행
        if trimmedText.isEmpty {
            performSearch(with: searchText)
        }
        // 타자 칠 때는 실행하지 않음
    }
    
    // 글자 수 제한 체크 함수
    private func checkTextLimit(_ text: String) -> Bool {
        let koreanCount = text.filter { $0.isKorean }.count
        let englishCount = text.filter { $0.isEnglish }.count
        let otherCount = text.count - koreanCount - englishCount
        
        // 한글 80자 또는 영어 100자 제한
        if koreanCount > 80 {
            showTextLimitAlert(message: "단어를 줄여서 검색해보세요")
            return true
        }
        
        if englishCount > 100 {
            showTextLimitAlert(message: "단어를 줄여서 검색해보세요")
            return true
        }
        
        // 전체 글자 수도 체크 (한글+영어+기타 문자)
        let totalLimit = 100 // 전체 제한
        if text.count > totalLimit {
            showTextLimitAlert(message: "단어를 줄여서 검색해보세요")
            return true
        }
        
        return false
    }

    // 알림 표시 함수
    private func showTextLimitAlert(message: String) {
        let alert = UIAlertController(title: "입력 제한", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension SearchViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchCollectionViewCell", for: indexPath) as! SearchCollectionViewCell
        
        let item = searchItems[indexPath.item]
        cell.configure(with: item)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension SearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedItem = searchItems[indexPath.item]
        print("🎯 탭 클릭: \(selectedItem.title) (index: \(indexPath.item))")
        
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        goToPage(indexPath.item)
    }
}

// MARK: - UIPageViewControllerDataSource
extension SearchViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let contentVC = viewController as? SearchContentViewController else { return nil }
        let index = contentVC.pageIndex
        
        if index > 0 {
            return createTableViewController(for: index - 1)
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let contentVC = viewController as? SearchContentViewController else { return nil }
        let index = contentVC.pageIndex
        
        if index < searchItems.count - 1 {
            return createTableViewController(for: index + 1)
        }
        return nil
    }
}

// MARK: - UIPageViewControllerDelegate
extension SearchViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed,
           let currentVC = pageViewController.viewControllers?.first as? SearchContentViewController {
            let currentIndex = currentVC.pageIndex
            let selectedItem = searchItems[currentIndex]
            
            print("👆 스와이프 완료: \(selectedItem.title) (index: \(currentIndex))")
            
            // CollectionView 선택 상태 동기화
            let indexPath = IndexPath(item: currentIndex, section: 0)
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            
            // 스와이프로 탭 변경 시 자동 검색
            performAutoSearchOnTabChange(for: currentIndex)
        }
    }
}

// MARK: - SearchItem 데이터 모델
struct SearchItem {
    let id: Int
    let title: String
    let category: String
}

extension Character {
    var isKorean: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return (0xAC00...0xD7A3).contains(scalar.value) || // 완성된 한글
               (0x1100...0x11FF).contains(scalar.value) || // 한글 자음
               (0x3130...0x318F).contains(scalar.value) || // 한글 호환 자모
               (0xA960...0xA97F).contains(scalar.value) || // 한글 자모 확장-A
               (0xD7B0...0xD7FF).contains(scalar.value)    // 한글 자모 확장-B
    }
    
    var isEnglish: Bool {
        return isASCII && isLetter
    }
}
