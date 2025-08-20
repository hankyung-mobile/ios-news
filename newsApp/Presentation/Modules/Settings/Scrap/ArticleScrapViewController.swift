//
//  ArticleScrapViewController.swift
//  newsApp
//
//  Created by jay on 7/7/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ArticleScrapViewController: UIViewController, UIGestureRecognizerDelegate {
    
    private let viewModel = ArticleScrapListViewModel()
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnEdit: UIButton!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var noDataView: UIView!
    
    // ✅ 헤더 표시 여부를 결정하는 플래그
    private var shouldShowHeader: Bool = false  // true: 헤더 표시, false: 헤더 숨김
    
    // ✅ 코드로 생성할 스티키 바텀뷰 UI들
    private var stickyBottomView: UIView!
    private var lbSelectedCount: UILabel!
    private var btnDelete: UIButton!
    private var bottomViewBottomConstraint: NSLayoutConstraint!
    
    // 편집 관련
    private var isEditMode = false
    private var selectedIndexes: Set<Int> = []
    
    // 이전 화면에서 전달받을 파라미터
    var parameters: [String: Any] = [:]
    private let disposeBag = DisposeBag()
    private let refreshControl = UIRefreshControl()
    
    // 뉴스 네비게이션 델리게이트 추가
    weak var webNavigationDelegate: WebNavigationDelegate?
    
    // 로딩 인디케이터 추가
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        createStickyBottomView() // ✅ 코드로 UI 생성
        setupStickyBottomView()
        bindViewModel()
        setupButtonEvents()
        setupLoadingIndicator()
        
        // 셀 등록
        registerCells()
    }
    
    private func registerCells() {
        // 뉴스 셀 등록
        let cellNibs = [
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
    
    // MARK: - 헤더 관리 메서드들
    
    // ✅ 실제 데이터 인덱스를 계산하는 헬퍼 메서드
    private func dataIndex(for indexPath: IndexPath) -> Int {
        return shouldShowHeader ? indexPath.row - 1 : indexPath.row
    }
    
    // ✅ 테이블뷰 인덱스가 헤더인지 확인하는 헬퍼 메서드
    private func isHeaderIndex(_ indexPath: IndexPath) -> Bool {
        return shouldShowHeader && indexPath.row == 0
    }
    
    // MARK: - 스티키 바텀뷰 관련 메서드들
    
    private func createStickyBottomView() {
        // 1. 메인 컨테이너 뷰 생성
        stickyBottomView = UIView()
        stickyBottomView.backgroundColor = UIColor.systemBackground
        stickyBottomView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stickyBottomView)
        
        // 2. 선택된 개수 라벨 생성
        lbSelectedCount = UILabel()
        lbSelectedCount.text = ""
        lbSelectedCount.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        lbSelectedCount.textColor = UIColor(named: "neutral35*")
        lbSelectedCount.textAlignment = .center
        lbSelectedCount.translatesAutoresizingMaskIntoConstraints = false
        stickyBottomView.addSubview(lbSelectedCount)
        
        // 3. 삭제 버튼 생성
        btnDelete = UIButton(type: .system)
        btnDelete.setTitle("전체삭제", for: .normal)
        btnDelete.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        btnDelete.setTitleColor(UIColor.systemRed, for: .normal)
        btnDelete.setTitleColor(UIColor.systemRed.withAlphaComponent(0.5), for: .disabled)
        btnDelete.backgroundColor = UIColor.clear
        btnDelete.translatesAutoresizingMaskIntoConstraints = false
        stickyBottomView.addSubview(btnDelete)
        
        // 4. 제약조건 설정
        setupStickyBottomViewConstraints()
    }

    // ✅ 스티키 바텀뷰 제약조건 설정
    private func setupStickyBottomViewConstraints() {
        // 스티키 바텀뷰 제약조건
        bottomViewBottomConstraint = stickyBottomView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor) // 초기에는 숨김
        
        NSLayoutConstraint.activate([
            // stickyBottomView
            stickyBottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stickyBottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stickyBottomView.heightAnchor.constraint(equalToConstant: 52),
            bottomViewBottomConstraint,
            
            // lbSelectedCount
            lbSelectedCount.topAnchor.constraint(equalTo: stickyBottomView.topAnchor, constant: 16),
            lbSelectedCount.centerXAnchor.constraint(equalTo: stickyBottomView.centerXAnchor),
            lbSelectedCount.heightAnchor.constraint(equalToConstant: 20),
            
            // btnDelete
            btnDelete.trailingAnchor.constraint(equalTo: stickyBottomView.trailingAnchor, constant: -16),
            btnDelete.topAnchor.constraint(equalTo: stickyBottomView.topAnchor, constant: 13),
            btnDelete.widthAnchor.constraint(equalToConstant: 60),
            btnDelete.heightAnchor.constraint(equalToConstant: 26),
        ])
        
        btnDelete.contentHorizontalAlignment = .right
    }
    
    // ✅ 스티키 바텀뷰 초기 설정
    private func setupStickyBottomView() {
        // 상단 경계선 추가
        let topBorderView = UIView()
        topBorderView.backgroundColor = UIColor.separator
        topBorderView.translatesAutoresizingMaskIntoConstraints = false
        stickyBottomView.addSubview(topBorderView)
        
        NSLayoutConstraint.activate([
            topBorderView.topAnchor.constraint(equalTo: stickyBottomView.topAnchor),
            topBorderView.leadingAnchor.constraint(equalTo: stickyBottomView.leadingAnchor),
            topBorderView.trailingAnchor.constraint(equalTo: stickyBottomView.trailingAnchor),
            topBorderView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        // 삭제 버튼 초기 상태
        btnDelete.isHidden = true
        
        // 초기에는 숨김 상태
        hideStickyBottomView(animated: false)
    }
    
    // ✅ 스티키 바텀뷰 표시
    private func showStickyBottomView(animated: Bool = true) {
//        if animated {
//            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
//                self.bottomViewBottomConstraint.constant = 0
//                self.view.layoutIfNeeded()
//            }
//        } else {
//            bottomViewBottomConstraint.constant = 0
//            view.layoutIfNeeded()
//        }
    }
    
    // ✅ 스티키 바텀뷰 숨김
    private func hideStickyBottomView(animated: Bool = true) {
//         if animated {
//             UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
//                 self.bottomViewBottomConstraint.constant = 160 // 뷰 높이만큼 아래로
//                 self.view.layoutIfNeeded()
//             }
//         } else {
//             bottomViewBottomConstraint.constant = 160
//             view.layoutIfNeeded()
//         }
     }
    
    // ✅ 스티키 바텀뷰 업데이트
    private func updateStickyBottomView() {
        let selectedCount = selectedIndexes.count
        
        if selectedCount == 0 {
            btnDelete.setTitle("전체삭제", for: .normal)
        } else {
            btnDelete.setTitle("삭제", for: .normal)
        }
        
        if isEditMode {
            showStickyBottomView()
            lbSelectedCount.text = "\(selectedCount)개 선택"
            
            // 삭제 버튼 활성화/비활성화
            btnDelete.isEnabled = !viewModel.items.value.isEmpty
        } else {
            hideStickyBottomView()
            lbSelectedCount.text = "\(String(viewModel.itemCount))개 스크랩"
        }
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
                
                if !isLoading {
                    self?.loadingIndicator.stopAnimating()
                    self?.noDataView.isHidden = !items.isEmpty
                    self?.lbSelectedCount.text = "\(String(self?.viewModel.itemCount ?? 0))개 스크랩"
                    self?.btnEdit.isHidden = items.isEmpty
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
    
    private func setupUI() {
        // 테이블뷰 설정
        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = refreshControl
        
        // 리프레시 컨트롤
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        // 엣지 스와이프로 뒤로가기
        if navigationController != nil {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            navigationController?.interactivePopGestureRecognizer?.delegate = self
        }
        
        self.view.bringSubviewToFront(self.noDataView)
    }
    
    // 버튼 이벤트 설정
    private func setupButtonEvents() {
        // 편집 버튼
        btnEdit.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.toggleEditMode()
            })
            .disposed(by: disposeBag)
        
        // ✅ 삭제 버튼
        btnDelete.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.deleteSelectedItems()
            })
            .disposed(by: disposeBag)
        
        btnBack.rx.tap
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
    
    // ✅ 편집 모드 토글
    private func toggleEditMode() {
        isEditMode.toggle()
        
        if !isEditMode {
            selectedIndexes.removeAll()
        }
        
        // 버튼 텍스트 변경
        btnEdit.setTitle(isEditMode ? "완료" : "편집", for: .normal)
        
        // 스티키 바텀뷰 업데이트
        updateStickyBottomView()
       
        btnDelete.isHidden = !isEditMode
        
        // 테이블뷰 리로드
        UIView.transition(with: tableView,
                         duration: 0.3,
                         options: .transitionCrossDissolve) {
            self.tableView.reloadData()
        }
    }
    
    // ✅ 선택된 아이템들 삭제
    private func deleteSelectedItems() {
        
        if selectedIndexes.isEmpty {
            let alert = UIAlertController(
                title: "기사 삭제",
                //            message: "\(selectedIndexes.count)개의 스크랩을 삭제하시겠습니까?",
                message: "기사가 모든 기기에서 삭제됩니다.",
                preferredStyle: .actionSheet
            )
            
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            alert.addAction(UIAlertAction(title: "전체삭제", style: .destructive) { [weak self] _ in
                self?.performDeleteAll()
            })
            
            present(alert, animated: true)
            return
        }
        
        let alert = UIAlertController(
            title: "기사 삭제",
            //            message: "\(selectedIndexes.count)개의 스크랩을 삭제하시겠습니까?",
            message: "기사가 모든 기기에서 삭제됩니다.",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.performDelete()
        })
        
        present(alert, animated: true)
    }
    
    // ✅ 실제 삭제 수행
    private func performDelete() {
        // 선택된 스크랩 아이템들 수집
        var selectedItems: [ScrapItem] = []
        for index in selectedIndexes {
            if let item = viewModel.item(at: index) {
                selectedItems.append(item)
            }
        }
        
        guard !selectedItems.isEmpty else { return }
        
        print("🗑️ 삭제할 스크랩 아이템들:")
        for item in selectedItems {
            print("   - \(item.title ?? "제목 없음") (no: \(String(describing: item.no)))")
        }
        
        // ViewModel의 삭제 메서드 호출 - ScrapItem 배열 전달
        viewModel.deleteScrapItems(items: selectedItems)
        
        
        if viewModel.itemCount == selectedItems.count {
            isEditMode = false
            btnEdit.setTitle("편집", for: .normal)
            btnDelete.isHidden = true
        }
        // 삭제 후 상태 초기화
        selectedIndexes.removeAll()
//        btnEdit.setTitle("편집", for: .normal)
//        btnDelete.isHidden = true
        updateStickyBottomView()
    
    }
    
    private func performDeleteAll() {
     
        // ViewModel의 삭제 메서드 호출 - ScrapItem 배열 전달
        viewModel.deleteScrapAllItems()
        
        // 삭제 후 상태 초기화
        selectedIndexes.removeAll()
        isEditMode = false
        btnEdit.setTitle("편집", for: .normal)
        btnDelete.isHidden = true
        updateStickyBottomView()
    
    }

    
    private func loadData() {
        viewModel.loadFirstPage(with: parameters)
    }
    
    @objc private func refresh() {
        // 새로고침 시 편집 상태 초기화
        selectedIndexes.removeAll()
        isEditMode = false
        btnEdit.setTitle("편집", for: .normal)
        updateStickyBottomView()
        
        viewModel.loadFirstPage(with: parameters)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func moveToDetailPage(scrapItem: ScrapItem) {
        
        guard let url = scrapItem.app_url, !url.isEmpty,
              let validURL = URL(string: url) else {
            print("유효하지 않은 URL: \(scrapItem.url ?? "nil")")
            return
        }
        
        // 상세 페이지로 이동하는 로직
         webNavigationDelegate?.openNewsDetail(url: validURL, title: nil)
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

// MARK: - TableView DataSource & Delegate
extension ArticleScrapViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return totalCellCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let isLastCell = indexPath.row == (newsItemCount - 1)
        // 헤더 셀 처리
//        if isHeaderIndex(indexPath) {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderArticleScrapListViewCell", for: indexPath) as! HeaderArticleScrapListViewCell
//            return cell
//        }
        
        // 푸터 셀
        if isFooterCell(at: row) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchLastTableViewCell", for: indexPath) as! SearchLastTableViewCell
            cell.lbDescription.text = "마지막 페이지입니다."
            cell.lbDescription.textAlignment = .center
            cell.heightOfLabel.constant = 20
            cell.constantTop.constant = 24
            cell.constantBottom.constant = 76
            return cell
        }
        
        // 스크랩 데이터 셀
        let dataIdx = dataIndex(for: indexPath)
        guard let item = viewModel.item(at: dataIdx) else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleScrapListViewCell", for: indexPath) as! ArticleScrapListViewCell
        
        // 델리게이트 설정
        cell.delegate = self
        
        // 선택 상태 확인
        let isScrapSelected = selectedIndexes.contains(dataIdx)
        
        // 셀 구성
        cell.configure(with: item, isEditMode: isEditMode, isScrapSelected: isScrapSelected)
//        cell.lyDivider.isHidden = isLastCell
        print("셀 \(isLastCell)")
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 헤더 셀은 무시
        guard !isHeaderIndex(indexPath) else { return }
        
        let dataIdx = dataIndex(for: indexPath)
        
        if isEditMode {
            if let cell = tableView.cellForRow(at: indexPath) as? ArticleScrapListViewCell {
                cell.toggleSelection()
                cellDidToggleSelection(cell)
            }
        } else {
            // 일반 모드: 상세 페이지로 이동
            if let item = viewModel.item(at: dataIdx) {
                moveToDetailPage(scrapItem: item)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 헤더 셀은 무한스크롤에서 제외
        guard !isHeaderIndex(indexPath) else { return }
        
        let dataIdx = dataIndex(for: indexPath)
        if viewModel.shouldLoadMore(at: dataIdx) {
            viewModel.loadNextPage()
        }
    }
}

// MARK: - ArticleScrapCellDelegate
extension ArticleScrapViewController: ArticleScrapCellDelegate {
    
    func cellDidToggleSelection(_ cell: ArticleScrapListViewCell) {
        guard let indexPath = tableView.indexPath(for: cell),
              !isHeaderIndex(indexPath) else { return }
        
        let dataIdx = dataIndex(for: indexPath)
        let (_, isScrapSelected) = cell.getCurrentItem()
        
        if isScrapSelected {
            selectedIndexes.insert(dataIdx)
        } else {
            selectedIndexes.remove(dataIdx)
        }
        
        // 스티키 바텀뷰 업데이트
        updateStickyBottomView()
        
        print("📝 선택된 인덱스들: \(selectedIndexes)")
    }
}

// MARK: - 헤더 제어 사용 예시
extension ArticleScrapViewController {
    
    // 특정 조건에 따라 헤더 표시/숨김
    private func updateHeaderVisibility() {
        // 예시 1: 데이터가 없으면 헤더 숨김
        // shouldShowHeader = viewModel.itemCount > 0
        
        // 예시 2: 편집 모드에서만 헤더 숨김
        // shouldShowHeader = !isEditMode
        
        // 예시 3: 사용자 설정에 따라
        // shouldShowHeader = UserDefaults.standard.bool(forKey: "showHeader")
        
        // 예시 4: 파라미터에 따라
        // shouldShowHeader = !parameters.isEmpty
        
        // 플래그 변경 후 테이블뷰 리로드
        // tableView.reloadData()
    }
    
    // 사용자 설정 저장
    private func saveHeaderPreference() {
        UserDefaults.standard.set(shouldShowHeader, forKey: "showScrapHeader")
    }
    
    // 사용자 설정 불러오기
    private func loadHeaderPreference() {
        shouldShowHeader = UserDefaults.standard.bool(forKey: "showScrapHeader")
    }
}
