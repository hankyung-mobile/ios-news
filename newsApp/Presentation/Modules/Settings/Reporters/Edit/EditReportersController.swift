//
//  EditReportersController.swift
//  newsApp
//
//  Created by jay on 7/18/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class EditReportersController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    private let viewModel = EditReportersViewModel()
    private let disposeBag = DisposeBag()
    private let refreshControl = UIRefreshControl()
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var noDataView: UIView!
    
    // 이전 화면에서 전달받을 파라미터
    var parameters: [String: Any] = [:]
    
    // 로딩 인디케이터 추가
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bindViewModel()
        setupButtonEvents()
        setupLoadingIndicator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !parameters.isEmpty {
            loadData()
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
        // 테이블뷰 설정
        tableView.delegate = self
        tableView.dataSource = self
//        tableView.refreshControl = refreshControl
        
        // Section Index 색상 설정
        tableView.sectionIndexColor = UIColor.systemBlue
        tableView.sectionIndexBackgroundColor = UIColor.clear
        
        // 리프레시 컨트롤
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .light)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        btnClose.setImage(image, for: .normal)
        btnClose.tintColor = UIColor(named: "#1A1A1A")
        
        self.view.bringSubviewToFront(noDataView)
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
    
    private func setupButtonEvents() {
        // 버튼 이벤트
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
    
    // 삭제 확인 알림
    private func showDeleteConfirmation(for item: Reporter, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "기자 삭제",
            message: "기자가 모든 기기에서 삭제됩니다.",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.deleteItem(item, at: indexPath)
        })
        
        present(alert, animated: true)
    }
    
    private func deleteItem(_ item: Reporter, at indexPath: IndexPath) {
           // 로딩 인디케이터 표시
           let activityIndicator = UIActivityIndicatorView(style: .medium)
           view.addSubview(activityIndicator)
           activityIndicator.center = view.center
           activityIndicator.startAnimating()
           
           // API 삭제 호출
           viewModel.deleteItemFromServer(item) { [weak self] success in
               DispatchQueue.main.async {
                   activityIndicator.removeFromSuperview()
                   
                   if success {
                       // 삭제 성공 시 데이터 다시 로드
                       self?.viewModel.refresh()
                       NotificationCenter.default.post(
                        name: .reporterDeleted,
                        object: nil,
                        userInfo: nil
                       )
                   } else {
                       // 실패 시 에러 메시지
                       self?.showAlert(message: "삭제에 실패했습니다. 다시 시도해주세요.")
                   }
               }
           }
       }
}

// MARK: - TableView DataSource & Delegate
extension EditReportersController: UITableViewDataSource, UITableViewDelegate {
    
    // Section Index 타이틀 배열 반환
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return viewModel.sectionIndexTitles
    }
    
    // Section Index 선택 시 해당 섹션으로 스크롤
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return viewModel.sectionForIndex(title: title)
    }
    
    // Section 개수
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }
    
    // Section별 행 개수
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(in: section)
    }
    
    // 섹션 헤더/푸터 완전 제거
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = viewModel.item(at: indexPath) else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "EditReportersControllerTableViewCell", for: indexPath) as! EditReportersControllerTableViewCell
        cell.configure(with: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 뉴스 셀만 클릭 가능
        if let item = viewModel.item(at: indexPath) {
            
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if viewModel.shouldLoadMore(at: indexPath) {
            viewModel.loadNextPage()
        }
    }
    
    // 셀 높이 설정 (선택사항)
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let item = viewModel.item(at: indexPath) else {
            return UITableView.automaticDimension
        }
        return UITableView.automaticDimension
    }
    
    // 스와이프 삭제 활성화
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // 스와이프 삭제 스타일 설정
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] (action, view, completionHandler) in
            guard let item = self?.viewModel.item(at: indexPath) else {
                completionHandler(false)
                return
            }
            
            self?.showDeleteConfirmation(for: item, at: indexPath)
            completionHandler(true)
        }
        
        deleteAction.image = UIImage(systemName: "trash.fill")
        deleteAction.backgroundColor = UIColor.systemRed
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true
        
        return configuration
    }
}
