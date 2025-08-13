//
//  ReportersTableViewController.swift
//  newsApp
//
//  Created by jay on 7/18/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ReportersTableViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noDataView: UIView!
    
    private let viewModel = ReportersTableViewModel()
    private let disposeBag = DisposeBag()
    private let refreshControl = UIRefreshControl()
    var pageIndex: Int = 0
    
    var reporterData: Reporter?
    private var parameters: [String: Any] = [:]
    
    // 뉴스 네비게이션 델리게이트 추가
    weak var webNavigationDelegate: WebNavigationDelegate?
    
    // 로딩 인디케이터 추가
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // 스크롤 위치 유지를 위한 플래그 추가 - 더 구체적으로 관리
    private var hasInitializedData = false
    private var currentReporterEmail: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        bindViewModel()
        setupLoadingIndicator()
        
        let nib = UINib(nibName: "SectionListViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "SectionListViewCell")
        
        // 초기 데이터 로드
        if let reporterData = reporterData {
            loadInitialData(with: reporterData)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 이미 초기화된 경우 또는 다른 뷰에서 돌아온 경우에는 데이터 재로드 하지 않음
        // 단, reporterData가 변경된 경우에만 새로 로드
        if let reporterData = reporterData {
            let newEmail = reporterData.reporterEmail
            
            // 처음 로드이거나 다른 리포터로 변경된 경우에만 로드
            if !hasInitializedData || currentReporterEmail != newEmail {
                loadInitialData(with: reporterData)
            } else {
                print("⏩ [SKIP] Skipping data load - already initialized")
            }
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.refreshControl = refreshControl
        
        // 리프레시 컨트롤
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    private func bindViewModel() {
        // 아이템 리스트 바인딩 (articles → items로 변경)
        Observable.combineLatest(
              viewModel.items,
              viewModel.isLoadingRelay
          )
            .skip(1)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] items, isLoading in
                self?.tableView.reloadData()
                self?.refreshControl.endRefreshing()
                
                if !isLoading {
                    self?.loadingIndicator.stopAnimating()
                    self?.noDataView.isHidden = !items.isEmpty
                } else {
                    self?.loadingIndicator.startAnimating()
                }
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
    
    // 초기 데이터 로드 메서드
    private func loadInitialData(with reporter: Reporter) {
        currentReporterEmail = reporter.reporterEmail
        hasInitializedData = true
        
        parameters = [
            "email": reporter.reporterEmail ?? ""
        ]
        viewModel.loadFirstPage(with: parameters)
    }
    
    // 외부에서 데이터 업데이트할 때 호출하는 메서드
    func updateData(with reporter: Reporter) {
        let newEmail = reporter.reporterEmail
        
        // 다른 리포터로 변경된 경우에만 새로 로드
        if currentReporterEmail != newEmail {
            reporterData = reporter
            loadInitialData(with: reporter)
        } else {
            // 같은 리포터인 경우 데이터만 업데이트
            reporterData = reporter
        }
    }
    
    @objc private func refresh() {
        // 명시적 새로고침 시에는 강제로 데이터 다시 로드
        if let reporterData = reporterData {
            parameters = [
                "email": reporterData.reporterEmail ?? ""
            ]
            viewModel.loadFirstPage(with: parameters)
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
}

// MARK: - UITableViewDataSource & Delegate
extension ReportersTableViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.itemCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = viewModel.item(at: indexPath.row) else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SectionListViewCell", for: indexPath) as! SectionListViewCell
        cell.configure(with: item)
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 뉴스 셀만 클릭 가능
        if let item = viewModel.item(at: indexPath.row) {
            moveToDetailPage(article: item)
        }
    }
    
    private func moveToDetailPage(article: NewsArticle) {
        var urlString: String?
        urlString = article.url
        
        guard let url = urlString, !url.isEmpty,
              let validURL = URL(string: url) else {
            print("유효하지 않은 URL: \(urlString ?? "nil")")
            return
        }
        
        webNavigationDelegate?.openNewsDetail(url: validURL, title: nil)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if viewModel.shouldLoadMore(at: indexPath.row) {
            viewModel.loadNextPage()
        }
    }
    
    // 셀 높이 설정 (선택사항)
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let item = viewModel.item(at: indexPath.row) else {
            return UITableView.automaticDimension
        }
        return UITableView.automaticDimension
    }
    
}
