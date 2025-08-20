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
    
    // 커스텀 셀 식별자
    private let headerCellIdentifier = "HeaderReportersTableViewCell"
    private let newsCellIdentifier = "SectionListViewCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        bindViewModel()
        setupLoadingIndicator()
        // 셀 등록
        registerCells()
        
        // 초기 데이터 로드
        if let reporterData = reporterData {
            loadInitialData(with: reporterData)
        }
    }
    
    private func registerCells() {
        // 뉴스 셀 등록
        let cellNibs = [
            ("SectionListViewCell", "SectionListViewCell"),
            ("SearchLastTableViewCell", "SearchLastTableViewCell")
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
    
    // MARK: - Helper Methods for Custom Cells
    
    /// 실제 뉴스 데이터의 개수 (커스텀 셀 제외)
    private var newsItemCount: Int {
        return viewModel.itemCount
    }
    
    /// 전체 셀 개수 (헤더 + 뉴스 + 푸터)
    private var totalCellCount: Int {
        let baseCount = newsItemCount
        if baseCount == 0 {
            return 0 // 데이터가 없으면 커스텀 셀도 보여주지 않음
        }
        return baseCount + 2 // 헤더(1) + 뉴스(n) + 푸터(1)
    }
    
    /// 주어진 인덱스가 헤더 셀인지 확인
    private func isHeaderCell(at index: Int) -> Bool {
        return index == 0 && newsItemCount > 0
    }
    
    /// 주어진 인덱스가 푸터 셀인지 확인
    private func isFooterCell(at index: Int) -> Bool {
        return index == totalCellCount - 1 && newsItemCount > 0
    }
    
    /// 주어진 인덱스가 뉴스 셀인지 확인하고, 뉴스 데이터 인덱스 반환
    private func newsItemIndex(for cellIndex: Int) -> Int? {
        if newsItemCount == 0 { return nil }
        
        let newsIndex = cellIndex - 1 // 헤더 셀(1개) 제외
        if newsIndex >= 0 && newsIndex < newsItemCount {
            return newsIndex
        }
        return nil
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ReportersTableViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return totalCellCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let isLastCell = indexPath.row == newsItemCount
        
        // 헤더 셀
        if isHeaderCell(at: row) {
            let cell = tableView.dequeueReusableCell(withIdentifier: headerCellIdentifier, for: indexPath)as! HeaderReportersTableViewCell
            configureHeaderCell(cell)
            return cell
        }
        
        // 푸터 셀
        if isFooterCell(at: row) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchLastTableViewCell", for: indexPath) as! SearchLastTableViewCell
            cell.lbDescription.text = "마지막 페이지입니다."
            cell.lbDescription.textAlignment = .center
            cell.heightOfLabel.constant = 20
            cell.constantTop.constant = 24
            cell.constantBottom.constant = 24
            return cell
        }
        
        // 뉴스 셀
        if let newsIndex = newsItemIndex(for: row),
           let item = viewModel.item(at: newsIndex) {
            let cell = tableView.dequeueReusableCell(withIdentifier: newsCellIdentifier, for: indexPath) as! SectionListViewCell
            cell.configure(with: item)
//            cell.lyDivider.isHidden = isLastCell
            return cell
        }
        
        // 기본 셀 (에러 방지용)
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let row = indexPath.row
        
        // 헤더, 푸터 셀은 터치 이벤트 무시
        if isHeaderCell(at: row) || isFooterCell(at: row) {
            return
        }
        
        // 뉴스 셀 클릭만 처리
        if let newsIndex = newsItemIndex(for: row),
           let item = viewModel.item(at: newsIndex) {
            moveToDetailPage(article: item)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let row = indexPath.row
        
        // 뉴스 셀에서만 무한스크롤 체크
        if let newsIndex = newsItemIndex(for: row) {
            if viewModel.shouldLoadMore(at: newsIndex) {
                viewModel.loadNextPage()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // 뉴스 셀 높이
        return UITableView.automaticDimension
    }
    
    // MARK: - Custom Cell Configuration
    
    private func configureHeaderCell(_ cell: HeaderReportersTableViewCell) {
        // 헤더 셀 설정
        cell.lbHeader.text = "\(reporterData?.reporterName ?? "기자") 최신기사"
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
}
