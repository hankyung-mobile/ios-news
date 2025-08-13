//
//  SectionListViewController.swift
//  newsApp
//
//  Created by jay on 7/3/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SectionListViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private let viewModel = SectionListViewModel()
    private let disposeBag = DisposeBag()
    private let refreshControl = UIRefreshControl()
    
    // 이전 화면에서 전달받을 파라미터
    var parameters: [String: Any] = [:]
    
    // 이전 화면에서 전달받을 타이틀
    var viewTitle: String = ""
    
    // 뉴스 네비게이션 델리게이트 추가
    weak var webNavigationDelegate: WebNavigationDelegate?
    
    // 로딩 인디케이터 추가
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // 스크롤 위치 유지를 위한 플래그 추가
    private var hasLoadedData = false
    
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var lbTitle: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        setupLoadingIndicator()
        setupButtonEvents()
        
        let nib = UINib(nibName: "SectionListViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "SectionListViewCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !parameters.isEmpty && !hasLoadedData {
            loadData()
            hasLoadedData = true
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
    
    private func setupUI() {
//        let titleSize = UIFont.preferredFont(forTextStyle: .title2).pointSize
//           let boldFont = UIFont.boldSystemFont(ofSize: titleSize)
//        
//        lbTitle.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: boldFont)
//        lbTitle.adjustsFontForContentSizeCategory = true
        lbTitle.text = viewTitle
        
        // 테이블뷰 설정
        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = refreshControl
        
        // 리프레시 컨트롤
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        // 엣지 스와이프로 뒤로가기 (네비게이션 컨트롤러가 있는 경우)
        if navigationController != nil {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            navigationController?.interactivePopGestureRecognizer?.delegate = self
        }
    }
    
    private func bindViewModel() {
        // 아이템 리스트 바인딩 (articles → items로 변경)
        Observable.combineLatest(
              viewModel.items,
              viewModel.isLoadingRelay
          )
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] items, isLoading in
                self?.tableView.reloadData()
                self?.refreshControl.endRefreshing()
                
                if !isLoading {
                    self?.loadingIndicator.stopAnimating()
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
        // 메뉴 버튼 이벤트
        btnClose.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance) // 중복 탭 방지
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
    
    private func loadData() {
        viewModel.loadFirstPage(with: parameters)
    }
    
    @objc private func refresh() {
        viewModel.loadFirstPage(with: parameters)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TableView DataSource & Delegate
extension SectionListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.itemCount  // articleCount → itemCount로 변경
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = viewModel.item(at: indexPath.row) else {
            return UITableViewCell()
        }
        
        switch item {
        case .news(let article):
            // 뉴스 셀
            let cell = tableView.dequeueReusableCell(withIdentifier: "SectionListViewCell", for: indexPath) as! SectionListViewCell
            cell.configure(with: article)
            return cell
            
        case .banner:
            // 배너 셀
            let cell = tableView.dequeueReusableCell(withIdentifier: "BannerViewCell", for: indexPath) as! BannerViewCell
//            cell.configure()
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 뉴스 셀만 클릭 가능
        if let item = viewModel.item(at: indexPath.row),
           case .news(let article) = item {
            moveToDetailPage(article: article)
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
        
        switch item {
        case .news:
            return UITableView.automaticDimension
        case .banner:
            return 333  // 배너 높이
        }
    }
}
