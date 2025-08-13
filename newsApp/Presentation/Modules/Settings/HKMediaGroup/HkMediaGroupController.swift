//
//  HkMediaGroupController.swift
//  newsApp
//
//  Created by jay on 7/31/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


class HkMediaGroupController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnClose: UIButton!
    private let viewModel = HkMediaGroupViewModel()
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
        
//        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .light)
//        let image = UIImage(systemName: "chevron.backward", withConfiguration: config)
//        btnClose.setImage(image, for: .normal)
//        btnClose.tintColor = UIColor(named: "#1A1A1A")
        
        if navigationController != nil {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            navigationController?.interactivePopGestureRecognizer?.delegate = self
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
//                    self?.noDataView.isHidden = !items.isEmpty
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
    
}

// MARK: - UITableViewDataSource & Delegate
extension HkMediaGroupController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.itemCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = viewModel.item(at: indexPath.row) else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "HkMediaGroupControllerTableViewCell", for: indexPath) as! HkMediaGroupControllerTableViewCell
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
    
    private func moveToDetailPage(article: HKMediaItem) {
        var urlString: String?
        urlString = article.url
        
        guard let url = urlString, !url.isEmpty,
              let validURL = URL(string: url) else {
            print("유효하지 않은 URL: \(urlString ?? "nil")")
            return
        }
        
        UIApplication.shared.open(validURL, options: [:])
//        webNavigationDelegate?.openNewsDetail(url: validURL, title: nil)
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
    
    // 헤더 높이 설정
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    // 헤더 뷰 생성
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear // 또는 원하는 색상
        return headerView
    }
    
}
