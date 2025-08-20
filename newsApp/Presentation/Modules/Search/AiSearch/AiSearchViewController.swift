//
//  AiSearchViewController.swift
//  newsApp
//
//  Created by jay on 7/29/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AiSearchViewController: UIViewController, SearchContentViewController{
    var pageIndex: Int = 1
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noDataView: UIView!
    @IBOutlet weak var pleasePutView: UIView!
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Properties
    private let viewModel = AiSearchViewModel()
    private let disposeBag = DisposeBag()
    private var currentSearchQuery: String = ""
    
    // 뉴스 네비게이션 델리게이트
    weak var webNavigationDelegate: WebNavigationDelegate?
    
    // 로딩 인디케이터 추가
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // 최근 본 뉴스인지 구분하는 프로퍼티 추가
    private var isShowingRecentNews = false
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupLoadingIndicator()
        bindViewModel()
        showRecentNews()
        registerCells()
    }
    
    private func registerCells() {
        // XIB 파일로 Cell 등록 - 크래시 방지를 위해 별도 메서드로 분리
        let cellNibs = [
            ("SectionListViewCell", "SectionListViewCell"),
            ("SearchLastTableViewCell", "SearchLastTableViewCell"),
            ("HeaderLatestNewsTableViewCell", "HeaderLatestNewsTableViewCell")
        ]
        
        for (nibName, identifier) in cellNibs {
            if let _ = Bundle.main.path(forResource: nibName, ofType: "nib") {
                let nib = UINib(nibName: nibName, bundle: nil)
                tableView.register(nib, forCellReuseIdentifier: identifier)
            } else {
                print("⚠️ Warning: XIB file not found - \(nibName)")
            }
        }
    }
    
    private func setupLoadingIndicator() {
        // 인디케이터 설정
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .systemGray
        
        // 뷰에 추가
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // 중앙에 위치
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -73)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = refreshControl
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        
        // 리프레시 컨트롤
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    private func bindViewModel() {
        // 아이템 리스트 바인딩
        Observable.combineLatest(
              viewModel.items,
              viewModel.isLoadingRelay
          )
          .skip(1)
          .observe(on: MainScheduler.instance)
          .subscribe(onNext: { [weak self] items, isLoading in
              self?.tableView.reloadData()
              self?.refreshControl.endRefreshing()
              
              // 로딩 중이 아닐 때만 noDataView 표시/숨김 결정
              if !isLoading {
                  let shouldShowNoData = items.isEmpty && !(self?.currentSearchQuery.isEmpty ?? true)
                  self?.noDataView.isHidden = !shouldShowNoData
                  self?.loadingIndicator.stopAnimating()
                  self?.pleasePutView.isHidden = true
              } else {
                  // 로딩 중일 때는 noDataView 숨김
                  self?.noDataView.isHidden = true
                  self?.loadingIndicator.startAnimating()
              }
              
              print("📰 UI 업데이트: \(items.count)개 아이템, 로딩중: \(isLoading)")
          })
          .disposed(by: disposeBag)
        
        // 에러 바인딩
        viewModel.errorRelay
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in
                self?.loadingIndicator.stopAnimating()
                self?.showAlert(message: error)
                self?.refreshControl.endRefreshing()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
    @objc private func refresh() {
        if isShowingRecentNews {
            // 최근 본 뉴스 갱신
            showRecentNews()
            refreshControl.endRefreshing()
        } else {
            // 일반 검색 결과 새로고침
            viewModel.refresh()
        }
    }
    
    // MARK: - SearchContentViewController Protocol
    func performSearch(with query: String) {
        currentSearchQuery = query
        print("📰 AiSearchViewController 검색: '\(query)'")
        if !query.isEmpty {
            isShowingRecentNews = false // 검색 시 플래그 해제
            self.pleasePutView.isHidden = true
            viewModel.performSearch(query: query)
        } else if query.isEmpty {
            showRecentNews()
        }
    }
    
    private func showRecentNews() {
        
        isShowingRecentNews = true // 플래그 설정
        let recentNewsList = AiSearchManager.shared.getRecentNewsList()
        
        if recentNewsList.isEmpty {
            // 최근 본 뉴스가 없을 때
            viewModel.clearItems()
            
            // 직접 UI 업데이트 (bindViewModel 우회)
            DispatchQueue.main.async { [weak self] in
                guard let self  = self else { return }
                self.pleasePutView.isHidden = false
                self.noDataView.isHidden = true
                self.tableView.reloadData()
            }
        } else {
            // 최근 본 뉴스가 있으면 테이블뷰에 표시
            pleasePutView.isHidden = true
            noDataView.isHidden = true
            viewModel.setItems(recentNewsList) // ViewModel에 직접 설정
        }
    }
    
    // MARK: - Helper Methods
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        
        if presentedViewController == nil {
            present(alert, animated: true)
        }
    }
    
    private func openNewsDetail(searchResult: AiSearchArticle) {
        let urlString = searchResult.appUrl ?? ""
        guard !urlString.isEmpty,
              let url = URL(string: urlString),
              url.scheme != nil else {
            print("📰 유효하지 않은 URL: \(urlString)")
//            showAlert(message: "뉴스를 열 수 없습니다.")
            return
        }
        
        AiSearchManager.shared.saveRecentNews(searchResult)
        webNavigationDelegate?.openNewsDetail(url: url, title: nil)
    }
    
    // MARK: - Cell Management (간소화)
    
    private var itemCount: Int {
        return viewModel.itemCount
    }
    
    private var totalCellCount: Int {
        guard itemCount > 0 else { return 0 }
        
        // 헤더나 푸터가 있으면 +1
        if isShowingRecentNews || shouldShowFooter {
            return itemCount + 1
        }
        return itemCount
    }
    
    private var shouldShowFooter: Bool {
        guard !isShowingRecentNews && itemCount > 0 else { return false }
        return !viewModel.hasMoreData || itemCount >= 100
    }
    
    private func cellType(at index: Int) -> CellType {
        // 헤더 체크
        if isShowingRecentNews && index == 0 && itemCount > 0 {
            return .header
        }
        
        // 푸터 체크
        if shouldShowFooter && index == itemCount {
            return .footer
        }
        
        // 나머지는 뉴스
        return .news
    }
    
    private func newsItemIndex(for cellIndex: Int) -> Int? {
        let offset = isShowingRecentNews ? 1 : 0
        let newsIndex = cellIndex - offset
        
        guard newsIndex >= 0 && newsIndex < itemCount else { return nil }
        return newsIndex
    }
    
    // 셀 타입 enum
    private enum CellType {
        case header
        case footer
        case news
    }
}

// MARK: - TableView DataSource & Delegate
extension AiSearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return totalCellCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        
        switch cellType(at: row) {
        case .header:
            // 크래시 방지 - 셀 등록 확인
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderLatestNewsTableViewCell") as? HeaderLatestNewsTableViewCell else {
                print("⚠️ HeaderLatestNewsTableViewCell not found")
                return UITableViewCell()
            }
            return cell
            
        case .footer:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SearchLastTableViewCell") as? SearchLastTableViewCell else {
                print("⚠️ SearchLastTableViewCell not found")
                return UITableViewCell()
            }
            cell.lbDescription.text = "검색은 최상의 검색결과를 제공하기 위해, 검색결과를 100개까지 제공하고 있습니다. 원하는 검색결과를 찾지 못하신 경우, 더욱 구체적인 검색어를 입력해 검색해주세요."
            return cell
            
        case .news:
            guard let newsIndex = newsItemIndex(for: row),
                  let searchResult = viewModel.item(at: newsIndex),
                  let cell = tableView.dequeueReusableCell(withIdentifier: "SectionListViewCell") as? SectionListViewCell else {
                print("⚠️ News cell configuration failed at row: \(row)")
                return UITableViewCell()
            }
            cell.configure(with: searchResult)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 뉴스 셀만 클릭 처리
        guard cellType(at: indexPath.row) == .news,
              let newsIndex = newsItemIndex(for: indexPath.row),
              let searchResult = viewModel.item(at: newsIndex) else {
            return
        }
        
        openNewsDetail(searchResult: searchResult)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 최근 본 뉴스는 무한스크롤 비활성화
        guard !isShowingRecentNews else { return }
        
        // 뉴스 셀에서만 무한스크롤 체크
        if let newsIndex = newsItemIndex(for: indexPath.row) {
            if viewModel.shouldLoadMore(at: newsIndex) {
                viewModel.loadNextPage()
            }
        }
    }
}
