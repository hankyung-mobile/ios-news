//
//  EditReportersController.swift (간단 버전)
//

import UIKit
import RxSwift
import RxCocoa

class EditReportersController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var noDataView: UIView!
    
    private let viewModel = EditReportersViewModel()
    private let disposeBag = DisposeBag()
    private let refreshControl = UIRefreshControl()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    var parameters: [String: Any] = [:]

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
            viewModel.loadFirstPage(with: parameters)
        }
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .systemGray
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupUI() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.sectionIndexColor = UIColor.systemBlue
        tableView.sectionIndexBackgroundColor = UIColor.clear
        
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .light)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        btnClose.setImage(image, for: .normal)
        btnClose.tintColor = UIColor(named: "#1A1A1A")
        
        self.view.bringSubviewToFront(noDataView)
    }
    
    private func bindViewModel() {
        Observable.combineLatest(viewModel.items, viewModel.isLoadingRelay)
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
                if let navigationController = self?.navigationController,
                   navigationController.viewControllers.count > 1 {
                    navigationController.popViewController(animated: true)
                } else {
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
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        
        viewModel.deleteItemFromServer(item) { [weak self] success in
            DispatchQueue.main.async {
                activityIndicator.removeFromSuperview()
                
                if success {
                    self?.viewModel.refresh()
                    NotificationCenter.default.post(name: .reporterDeleted, object: nil, userInfo: nil)
                } else {
                    self?.showAlert(message: "삭제에 실패했습니다. 다시 시도해주세요.")
                }
            }
        }
    }
}

// MARK: - TableView DataSource & Delegate
extension EditReportersController: UITableViewDataSource, UITableViewDelegate {
    
    // 🎯 Section Index - 올바른 드래그 처리
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return viewModel.sectionIndexTitles
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        // 해당 초성의 첫 번째 기자 위치로 스크롤
        let targetRow = viewModel.sectionForIndex(title: title)
        let indexPath = IndexPath(row: targetRow, section: EditReportersViewModel.SectionType.reporters.rawValue)
        
        // 즉시 스크롤
        DispatchQueue.main.async {
            if targetRow < self.viewModel.itemCount {
                tableView.scrollToRow(at: indexPath, at: .top, animated: false)
            }
        }
        
        // 기자 섹션 반환 (중요: 실제 스크롤은 위에서 처리)
        return EditReportersViewModel.SectionType.reporters.rawValue
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(in: section)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = EditReportersViewModel.SectionType(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        let isLastCell = indexPath.row == viewModel.itemCount - 1
        
        switch sectionType {
        case .header:
            return tableView.dequeueReusableCell(withIdentifier: "HeaderEditReportersTableViewCell", for: indexPath)
            
        case .reporters:
            guard let item = viewModel.item(at: indexPath) else { return UITableViewCell() }
            let cell = tableView.dequeueReusableCell(withIdentifier: "EditReportersControllerTableViewCell", for: indexPath) as! EditReportersControllerTableViewCell
            cell.configure(with: item)
            cell.lyDivider.isHidden = isLastCell
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let sectionType = EditReportersViewModel.SectionType(rawValue: indexPath.section),
              sectionType == .reporters,
              let item = viewModel.item(at: indexPath) else { return }
        
        // 클릭 이벤트 처리
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if viewModel.shouldLoadMore(at: indexPath) {
            viewModel.loadNextPage()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let sectionType = EditReportersViewModel.SectionType(rawValue: indexPath.section) else { return false }
        return sectionType == .reporters
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard let sectionType = EditReportersViewModel.SectionType(rawValue: indexPath.section) else { return .none }
        return sectionType == .reporters ? .delete : .none
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let sectionType = EditReportersViewModel.SectionType(rawValue: indexPath.section),
              sectionType == .reporters else { return nil }
        
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
