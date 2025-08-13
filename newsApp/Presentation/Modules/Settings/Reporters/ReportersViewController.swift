//
//  ReportersViewController.swift
//  newsApp
//
//  Created by jay on 7/15/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ReportersViewController: UIViewController, UIGestureRecognizerDelegate {
    
    private let viewModel = ReportersViewModel()
    
    // 이전 화면에서 전달받을 파라미터
    var parameters: [String: Any] = [:]
    private let disposeBag = DisposeBag()
    private let refreshControl = UIRefreshControl()
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var header: UIView!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnEdit: UIButton!
    @IBOutlet weak var noDataView: UIView!
    @IBOutlet weak var footer: UIView!
    
    // PageViewController 추가
    private var pageViewController: UIPageViewController!
    private var pageContainerView: UIView!
    
    // 캐시된 뷰 컨트롤러들을 저장할 배열 추가
    private var cachedTableViewControllers: [Int: ReportersTableViewController] = [:]
    
    // 뉴스 네비게이션 델리게이트 추가
    weak var webNavigationDelegate: WebNavigationDelegate?
    
    // 로딩 인디케이터 추가
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        setupButtonEvents()
        setupCollectionView()
        setupPageViewController()
        setupNotificationObserver()
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
    
    // 안전한 CollectionView 아이템 선택
    private func safeSelectCollectionViewItem(at index: Int, animated: Bool = true) {
        guard index >= 0,
              index < viewModel.itemCount,
              index < collectionView.numberOfItems(inSection: 0) else {
            print("⚠️ Invalid index (\(index)) for CollectionView selection")
            return
        }
        
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: .centeredHorizontally)
        print("✅ SafeSelect: Selected item at index \(index)")
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
                self?.collectionView.reloadData()
                self?.refreshControl.endRefreshing()
                
                // CollectionView 업데이트 완료 후 PageViewController 업데이트
                DispatchQueue.main.async {
                    self?.updatePageViewController()
                }
                
                if !isLoading {
                    self?.loadingIndicator.stopAnimating()
                    self?.noDataView.isHidden = !items.isEmpty
                    self?.footer.isHidden = items.isEmpty
                } else {
                    self?.loadingIndicator.startAnimating()
                    self?.footer.isHidden = true
                }
                
                // 데이터가 있고, 처음 로드일 때만 첫 번째 아이템 선택 - 안전하게
                if !items.isEmpty && self?.collectionView.indexPathsForSelectedItems?.isEmpty == true {
                    DispatchQueue.main.async {
                        self?.safeSelectCollectionViewItem(at: 0)
                    }
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
        // 엣지 스와이프로 뒤로가기
        if navigationController != nil {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            navigationController?.interactivePopGestureRecognizer?.delegate = self
        }
    }
    
    // 버튼 이벤트 설정
    private func setupButtonEvents() {
        // 편집 버튼
        btnEdit.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                let storyboard = UIStoryboard(name: "EditReporters", bundle: nil)
                let reportersVC = storyboard.instantiateViewController(withIdentifier: "EditReportersController") as! EditReportersController
                reportersVC.parameters = getUserTokensParams()
                
                self?.navigationController?.pushViewController(reportersVC, animated: true)
                
//                let navController = UINavigationController(rootViewController: reportersVC)
//                navController.modalPresentationStyle = .pageSheet
//                
//                navController.setNavigationBarHidden(true, animated: false)
//                
//                self?.present(navController, animated: true)
            })
            .disposed(by: disposeBag)
        
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
    
    private func setupCollectionView() {
        // 컬렉션뷰 설정
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    private func setupPageViewController() {
        // PageViewController 컨테이너 뷰 생성
        pageContainerView = UIView()
        pageContainerView.backgroundColor = UIColor.systemBackground
        view.addSubview(pageContainerView)
        
        // PageViewController 생성
        pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        // PageViewController를 자식으로 추가
        addChild(pageViewController)
        pageContainerView.addSubview(pageViewController.view)
        
        // Auto Layout 설정
        pageContainerView.translatesAutoresizingMaskIntoConstraints = false
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // PageContainer를 CollectionView 밑에 위치
            pageContainerView.topAnchor.constraint(equalTo: footer.bottomAnchor, constant: 0),
            pageContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // PageViewController를 컨테이너에 꽉 채우기
            pageViewController.view.topAnchor.constraint(equalTo: pageContainerView.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: pageContainerView.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: pageContainerView.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: pageContainerView.bottomAnchor)
        ])
        
        pageViewController.didMove(toParent: self)
        self.view.bringSubviewToFront(noDataView)
    }
    
    private func updatePageViewController() {
        guard viewModel.itemCount > 0 else {
            print("⚠️ No items to display in PageViewController")
            return
        }
        
        // 현재 페이지 인덱스 가져오기
        let currentIndex = getCurrentPageIndex()
        
        // 현재 인덱스가 유효하면 그대로 유지, 아니면 0
        let targetIndex = currentIndex < viewModel.itemCount ? currentIndex : 0
        
        // 기존에 캐시된 뷰컨트롤러들의 데이터만 업데이트
        let items = viewModel.items.value
        for (index, cachedVC) in cachedTableViewControllers {
            if index < items.count {
                cachedVC.updateData(with: items[index])
            }
        }
        
        let targetPage = createTableViewController(for: targetIndex)
        pageViewController.setViewControllers([targetPage], direction: .forward, animated: false)
        
        // 해당 인덱스 셀 선택 - 안전하게 처리
        DispatchQueue.main.async { [weak self] in
            self?.safeSelectCollectionViewItem(at: targetIndex,animated: false)
        }
    }
    
    // 안전한 테이블뷰 컨트롤러 생성
    private func createTableViewController(for index: Int) -> UIViewController {
        guard index >= 0,
              index < viewModel.itemCount else {
            print("⚠️ Invalid index for TableViewController: \(index)")
            return ReportersTableViewController()
        }
        
        // 캐시에서 먼저 찾기
        if let cachedVC = cachedTableViewControllers[index] {
            // 캐시된 뷰 컨트롤러의 데이터가 최신인지 확인하고 업데이트
            let items = viewModel.items.value
            if index < items.count {
                cachedVC.updateData(with: items[index])
            }
            print("📋 Using cached TableViewController for index \(index)")
            return cachedVC
        }
        
        // 캐시에 없으면 새로 생성
        guard let tableVC = UIStoryboard(name: "ReportersTableView", bundle: nil).instantiateViewController(withIdentifier: "ReportersTableViewController") as? ReportersTableViewController else {
            print("❌ Failed to create ReportersTableViewController")
            return ReportersTableViewController()
        }
        
        tableVC.webNavigationDelegate = self.webNavigationDelegate

        let items = viewModel.items.value
        if index < items.count {
            tableVC.pageIndex = index
            tableVC.reporterData = items[index] // 해당 인덱스의 데이터 전달
        }
        
        // 캐시에 저장
        cachedTableViewControllers[index] = tableVC
        print("🆕 Created new TableViewController for index \(index)")
        
        return tableVC
    }
    
    // 안전한 페이지 이동
    private func goToPage(_ index: Int) {
        guard index >= 0,
              index < viewModel.itemCount else {
            print("⚠️ Invalid page index: \(index), itemCount: \(viewModel.itemCount)")
            return
        }
        
        let currentIndex = getCurrentPageIndex()
        guard index != currentIndex else {
            print("📍 Already at page \(index)")
            return
        }
        
        // 가려는 인덱스가 현재 인덱스보다 크면 forward, 작으면 reverse
        let direction: UIPageViewController.NavigationDirection = index > currentIndex ? .forward : .reverse
        let targetVC = createTableViewController(for: index)
        
        // 거리와 상관없이 항상 올바른 방향으로 애니메이션
        pageViewController.setViewControllers([targetVC], direction: direction, animated: true)
        print("🔄 Moved to page \(index)")
    }
    
    private func getCurrentPageIndex() -> Int {
        if let currentVC = pageViewController.viewControllers?.first as? ReportersTableViewController {
            return currentVC.pageIndex
        }
        return 0
    }
    
    private func loadData() {
        viewModel.loadFirstPage(with: parameters)
    }
    
    @objc private func refresh() {
        // 명시적 새로고침 시에만 캐시 클리어
        cachedTableViewControllers.removeAll()
        viewModel.loadFirstPage(with: parameters)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func setupNotificationObserver() {
        // 기자 삭제 알림 수신
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleReporterDeleted(_:)),
            name: .reporterDeleted,
            object: nil
        )
    }
    
    @objc private func handleReporterDeleted(_ notification: Notification) {
        print("🗑️ [DELETE] Reporter deleted - clearing cache and refreshing")
        cachedTableViewControllers.removeAll()
        refresh()
    }
}

// MARK: - UICollectionViewDataSource
extension ReportersViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.itemCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ReportersCollectionViewCell", for: indexPath) as! ReportersCollectionViewCell
        
        let items = viewModel.items.value
        guard indexPath.item < items.count else {
            print("⚠️ Index out of bounds in cellForItemAt: \(indexPath.item)")
            return cell
        }
        
        let item = items[indexPath.item]
        
        // 셀 데이터 설정
        cell.configure(with: item)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate (안전한 버전)
extension ReportersViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item >= 0,
              indexPath.item < viewModel.itemCount else {
            print("⚠️ Invalid selection index: \(indexPath.item)")
            return
        }
        
        // 아이템 선택 시 동작
        let items = viewModel.items.value
        guard indexPath.item < items.count else {
            print("⚠️ Index out of bounds in items array: \(indexPath.item)")
            return
        }
        
        let selectedItem = items[indexPath.item]
        
        // 안전한 스크롤
        if indexPath.item < collectionView.numberOfItems(inSection: 0) {
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
        
        goToPage(indexPath.item)
        
        // 선택된 아이템에 대한 처리
        print("✅ Selected item at \(indexPath.item): \(selectedItem)")
    }
}

// MARK: - UIPageViewControllerDataSource (안전한 버전)
extension ReportersViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let tableVC = viewController as? ReportersTableViewController else {
            print("⚠️ Invalid viewController type in viewControllerBefore")
            return nil
        }
        
        let index = tableVC.pageIndex
        
        guard index > 0,
              index - 1 < viewModel.itemCount else {
            print("📍 No previous page available from index \(index)")
            return nil
        }
        
        return createTableViewController(for: index - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let tableVC = viewController as? ReportersTableViewController else {
            print("⚠️ Invalid viewController type in viewControllerAfter")
            return nil
        }
        
        let index = tableVC.pageIndex
        
        guard index < viewModel.itemCount - 1,
              index + 1 < viewModel.itemCount else {
            print("📍 No next page available from index \(index)")
            return nil
        }
        
        return createTableViewController(for: index + 1)
    }
}

// MARK: - UIPageViewControllerDelegate (안전한 버전)
extension ReportersViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
              let currentVC = pageViewController.viewControllers?.first as? ReportersTableViewController else {
            return
        }
        
        let currentIndex = currentVC.pageIndex
        
        // 인덱스 유효성 검사
        guard currentIndex >= 0,
              currentIndex < viewModel.itemCount else {
            print("⚠️ Invalid current index in pageViewController: \(currentIndex)")
            return
        }
        
        // 스와이프로 페이지 변경될 때마다 해당 데이터 반환
        let items = viewModel.items.value
        guard currentIndex < items.count else {
            print("⚠️ Current index out of bounds in items: \(currentIndex)")
            return
        }
        
        let selectedItem = items[currentIndex]
        
        // 스와이프 시 데이터 반환 로그
        print("🔄 [SWIPE] Page changed to: \(currentIndex)")
        print("🔄 [SWIPE] Selected item: \(selectedItem)")
        
        // CollectionView의 해당 인덱스도 선택상태로 변경 - 안전하게
        safeSelectCollectionViewItem(at: currentIndex)
    }
}
