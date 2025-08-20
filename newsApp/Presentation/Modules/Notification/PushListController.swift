//
//  PushListController.swift
//  newsApp
//
//  Created by jay on 7/31/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PushListController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noDataView: UIView!
    @IBOutlet weak var btnClose: UIButton!
    
    private let viewModel = PushListViewModel()
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
        setupButtonEvents()
        setupLoadingIndicator()
        viewModel.loadFirstPage(with: parameters)
        // 셀 등록
        registerCells()
        
        if navigationController != nil {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            navigationController?.interactivePopGestureRecognizer?.delegate = self
        }
        
        view.sendSubviewToBack(noDataView)
        tableView.backgroundColor = .clear
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
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
                    AppDataManager.shared.savePushData(items)
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
    
    @objc private func refresh() {
        
        viewModel.loadFirstPage(with: parameters)
        
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func openInternalBrowser(url: URL) {
        let internalBrowserVC = InternalBrowserViewController(url: url)
        let navigationController = UINavigationController(rootViewController: internalBrowserVC)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)
    }
    
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
        return baseCount + 1 // 뉴스(n) + 푸터(1)
    }
    
    /// 주어진 인덱스가 푸터 셀인지 확인
    private func isFooterCell(at index: Int) -> Bool {
        return index == totalCellCount - 1 && newsItemCount > 0
    }
    
    /// 주어진 인덱스가 뉴스 셀인지 확인하고, 뉴스 데이터 인덱스 반환
    private func newsItemIndex(for cellIndex: Int) -> Int? {
        if newsItemCount == 0 { return nil }
        
        let newsIndex = cellIndex
        if newsIndex >= 0 && newsIndex < newsItemCount {
            return newsIndex
        }
        return nil
    }
    
}

// MARK: - UITableViewDataSource & Delegate
extension PushListController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return totalCellCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let isLastCell = indexPath.row == (newsItemCount - 1)
        
        // 푸터 셀
//        if isFooterCell(at: row) {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchLastTableViewCell", for: indexPath) as! SearchLastTableViewCell
//            cell.lbDescription.text = "마지막 페이지입니다."
//            cell.lbDescription.textAlignment = .center
//            cell.heightOfLabel.constant = 20
//            cell.constantTop.constant = 24
//            cell.constantBottom.constant = 24
//            return cell
//        }
        
        if let newsIndex = newsItemIndex(for: row),
           let item = viewModel.item(at: newsIndex) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SectionListViewCell", for: indexPath) as! SectionListViewCell
            cell.configure(with: item)
            cell.lyDivider.isHidden = isLastCell
            return cell
        }
        
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 뉴스 셀만 클릭 가능
        if let item = viewModel.item(at: indexPath.row) {
            moveToDetailPage(article: item)
        }
    }
    
    private func moveToDetailPage(article: PushItem) {
        var urlString: String?
        urlString = article.url
        
        guard let url = urlString, !url.isEmpty,
              let validURL = URL(string: url) else {
            print("유효하지 않은 URL: \(urlString ?? "nil")")
            return
        }
        
        if !validURL.absoluteString.contains("webview.hankyung") {
            openInternalBrowser(url: validURL)
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
