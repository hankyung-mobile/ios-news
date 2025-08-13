//
//  SearchReportersController.swift
//  newsApp
//
//  Created by jay on 7/25/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SearchReportersController: UIViewController, SearchContentViewController {
    var pageIndex: Int = 3
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noDataView: UIView!
    @IBOutlet weak var pleasePutView: UIView!
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Properties
    private let viewModel = SearchReportersViewModel()
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
        pleasePutView.isHidden = !currentSearchQuery.isEmpty
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
        viewModel.refresh()
    }
    
    // MARK: - SearchContentViewController Protocol
    func performSearch(with query: String) {
        currentSearchQuery = query
        print("📰 SearchLatestNewsViewController 검색: '\(query)'")
        if !query.isEmpty {
            self.pleasePutView.isHidden = true
        } else if query.isEmpty {
            self.pleasePutView.isHidden = false
            return
        }
        viewModel.performSearch(query: query)
    }
    
    // MARK: - Helper Methods
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func openNewsDetail(searchResult: ReporterItem) {
        guard let url = URL(string: searchResult.appUrl ?? "") else {
            print("📰 유효하지 않은 URL: \(String(describing: searchResult.url))")
            return
        }
        webNavigationDelegate?.openNewsDetail(url: url, title: nil)
    }
}

// MARK: - TableView DataSource & Delegate
extension SearchReportersController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.itemCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let searchResult = viewModel.item(at: indexPath.row) else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchReportersControllerTableViewCell", for: indexPath) as! SearchReportersControllerTableViewCell
        cell.configure(with: searchResult)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let searchResult = viewModel.item(at: indexPath.row) else { return }
        openNewsDetail(searchResult: searchResult)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 무한스크롤 체크
        if viewModel.shouldLoadMore(at: indexPath.row) {
            viewModel.loadNextPage()
        }
    }
}
