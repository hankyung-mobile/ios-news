////
////  MarketIndexPageViewController.swift
////  newsApp
////
////  Created by hkcom on 2020/08/26.
////  Copyright © 2020 hkcom. All rights reserved.
////
//
//import UIKit
//import WebKit
//import RxSwift
//import RxCocoa
//
//class MarketIndexPageViewController: UIViewController {
//    private let viewModel = WebViewPageViewModel()
//    
//    private lazy var pageViewController: UIPageViewController = {
//        let controller = UIPageViewController(
//            transitionStyle: .scroll,
//            navigationOrientation: .horizontal,
//            options: nil
//        )
//        controller.dataSource = self
//        controller.delegate = self
//        return controller
//    }()
//    
//    // 컨텐츠 컨트롤러 캐시 (WebContentController 사용)
//    private var contentControllerCache = NSCache<NSNumber, WebContentController>()
//    
//    // 현재 인덱스
//    private var currentIndex = 0
//    
//    // 전환 상태 관리
//    private var isTransitioning = false
//    
//    // 프리로드된 페이지 추적
//    private var preloadedPages = Set<Int>()
//    
//    // 페이지 로드 타임스탬프 추적
//    private var pageLoadTimestamps = [Int: Date]()
//    
//    private let disposeBag = DisposeBag()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        // URL 캐시 설정
//        configureURLCache()
//        
//        // 캐시 설정
//        contentControllerCache.countLimit = viewModel.urls.value.count // 모든 페이지 캐싱
//        
//        setupPageViewController()
//        bindViewModel()
//        
//        // 초기 페이지 설정
//        if let initialController = getContentController(at: 0) {
//            pageViewController.setViewControllers([initialController], direction: .forward, animated: false)
//            currentIndex = 0
//            
//            // 인접 페이지 미리 로드
//            preloadAdjacentPages(around: 0)
//        }
//        
//        // 메모리 경고 관찰 (안전하게 관찰자 추가)
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(handleMemoryWarning),
//            name: UIApplication.didReceiveMemoryWarningNotification,
//            object: nil
//        )
//    }
//    
//    deinit {
//        // 메모리 누수 방지를 위해 관찰자 제거
//        NotificationCenter.default.removeObserver(self)
//    }
//    
//    private func configureURLCache() {
//        // 캐시 크기 증가 (메모리 및 디스크 캐시)
//        let memoryCapacity = 20 * 1024 * 1024 // 20MB
//        let diskCapacity = 100 * 1024 * 1024 // 100MB
//        
//        // 커스텀 캐시 디렉토리 사용 시 크래시 가능성이 있어 nil로 설정
//        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: nil)
//        URLCache.shared = cache
//    }
//    
//    private func setupPageViewController() {
//        addChild(pageViewController)
//        view.addSubview(pageViewController.view)
//        pageViewController.view.frame = view.bounds
//        pageViewController.didMove(toParent: self)
//    }
//    
//    @objc private func handleMemoryWarning() {
//        // 메모리 경고 알림 전송 (모든 웹뷰가 자체 최적화 수행)
//        NotificationCenter.default.post(name: NSNotification.Name("OptimizeWebViewMemory"), object: nil)
//    }
//    
//    private func bindViewModel() {
//        viewModel.currentPageIndex
//            .distinctUntilChanged()
//            .subscribe(onNext: { [weak self] index in
//                guard let self = self, !self.isTransitioning else { return }
//                self.isTransitioning = true
//                
//                guard let controller = self.getContentController(at: index) else {
//                    self.isTransitioning = false
//                    return
//                }
//                
//                let direction: UIPageViewController.NavigationDirection =
//                    index > self.currentIndex ? .forward : .reverse
//                
//                self.pageViewController.setViewControllers([controller], direction: direction, animated: true) { [weak self] completed in
//                    guard let self = self else { return }
//                    
//                    if completed {
//                        self.currentIndex = index
//                        
//                        // 페이지 로드 타임스탬프 업데이트
//                        self.pageLoadTimestamps[index] = Date()
//                        
//                        // 인접 페이지 미리 로드
//                        self.preloadAdjacentPages(around: index)
//                    }
//                    
//                    self.isTransitioning = false
//                    self.viewModel.isTransitioning.accept(false)
//                }
//            })
//            .disposed(by: disposeBag)
//        
//        viewModel.isTransitioning
//            .subscribe(onNext: { [weak self] isTransitioning in
//                self?.isTransitioning = isTransitioning
//            })
//            .disposed(by: disposeBag)
//    }
//    
//    // 인접 페이지 미리 로드 (안전한 버전)
//    private func preloadAdjacentPages(around index: Int) {
//        // 프리로드할 페이지 범위 (현재 기준 양쪽 2페이지)
//        let minIndex = max(0, index - 2)
//        let maxIndex = min(viewModel.urls.value.count - 1, index + 2)
//        let range = minIndex...maxIndex
//        
//        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//            guard let self = self else { return }
//            
//            for i in range {
//                // 현재 페이지나 이미 프리로드된 페이지는 스킵
//                if i == index || self.preloadedPages.contains(i) {
//                    continue
//                }
//                
//                // 최근에 로드된 페이지는 다시 로드하지 않음
//                if let lastLoadTime = self.pageLoadTimestamps[i],
//                   Date().timeIntervalSince(lastLoadTime) < 30 {
//                    continue
//                }
//                
//                // 메인 스레드에서 컨트롤러 생성
//                DispatchQueue.main.async { [weak self] in
//                    guard let self = self, !self.isTransitioning else { return }
//                    
//                    if let _ = self.getContentController(at: i) {
//                        self.preloadedPages.insert(i)
//                        self.pageLoadTimestamps[i] = Date()
//                    }
//                }
//            }
//        }
//    }
//    
//    // 컨텐츠 컨트롤러 생성 또는 캐시에서 가져오기 (WebContentController 사용)
//    private func getContentController(at index: Int) -> WebContentController? {
//        guard index >= 0, index < viewModel.urls.value.count else { return nil }
//        
//        // 캐시에서 확인
//        if let cachedController = contentControllerCache.object(forKey: NSNumber(value: index)) {
//            return cachedController
//        }
//        
//        // 새로 생성
//        let url = viewModel.urls.value[index]
//        let controller = WebContentController(url: url)
//        
//        // 웹 네비게이션 델리게이트 설정
//        controller.webNavigationDelegate = self
//        
//        // 캐시에 저장
//        contentControllerCache.setObject(controller, forKey: NSNumber(value: index))
//        pageLoadTimestamps[index] = Date()
//        
//        return controller
//    }
//    
//    // 메모리 경고 시 일부 최적화 (모든 페이지 유지)
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        
//        // 모든 웹뷰에 메모리 최적화 알림 전송
//        NotificationCenter.default.post(name: NSNotification.Name("OptimizeWebViewMemory"), object: nil)
//        
//        // 현재 페이지와 인접 페이지만 활성 상태로 유지
//        for i in 0..<viewModel.urls.value.count {
//            if let controller = contentControllerCache.object(forKey: NSNumber(value: i)) {
//                if i == currentIndex || abs(i - currentIndex) <= 1 {
//                    // 현재 페이지와 인접 페이지는 포그라운드 최적화
//                    controller.optimizeForForeground()
//                } else {
//                    // 나머지 페이지는 백그라운드 최적화 (완전 제거는 안함)
//                    controller.optimizeForBackground()
//                }
//            }
//        }
//    }
//}
//
//// MARK: - WebNavigationDelegate
//extension MarketIndexPageViewController: WebNavigationDelegate {
//    func openNewsDetail(url: URL, title: String?) {
//        print("MarketIndexPageViewController: Opening news detail for URL: \(url)")
//        
//        // 뉴스 상세 뷰컨트롤러 생성
//        let newsDetailVC = NewsDetailViewController(url: url, title: title)
//        
//        // 연쇄적으로 뉴스 상세를 열 수 있도록 델리게이트 설정
//        newsDetailVC.webNavigationDelegate = self
//        
//        // 네비게이션 컨트롤러에 푸시 (겹겹이 쌓이는 효과)
//        navigationController?.pushViewController(newsDetailVC, animated: true)
//    }
//}
//
//// MARK: - UIPageViewControllerDataSource
//extension MarketIndexPageViewController: UIPageViewControllerDataSource {
//    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
//        guard let controller = viewController as? WebContentController,
//              let currentIndex = viewModel.urls.value.firstIndex(of: controller.currentURL) else {
//            return nil
//        }
//        
//        let previousIndex = currentIndex - 1
//        guard previousIndex >= 0 else { return nil }
//        
//        return getContentController(at: previousIndex)
//    }
//    
//    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
//        guard let controller = viewController as? WebContentController,
//              let currentIndex = viewModel.urls.value.firstIndex(of: controller.currentURL) else {
//            return nil
//        }
//        
//        let nextIndex = currentIndex + 1
//        guard nextIndex < viewModel.urls.value.count else { return nil }
//        
//        return getContentController(at: nextIndex)
//    }
//}
//
//// MARK: - UIPageViewControllerDelegate
//extension MarketIndexPageViewController: UIPageViewControllerDelegate {
//    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
//        isTransitioning = true
//        viewModel.isTransitioning.accept(true)
//    }
//    
//    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
//        isTransitioning = false
//        viewModel.isTransitioning.accept(false)
//        
//        if completed,
//           let controller = pageViewController.viewControllers?.first as? WebContentController,
//           let index = viewModel.urls.value.firstIndex(of: controller.currentURL) {
//            currentIndex = index
//            
//            // 현재 페이지 포그라운드 최적화
//            controller.optimizeForForeground()
//            
//            // 이전 페이지들 백그라운드 최적화
//            for prevController in previousViewControllers {
//                if let webController = prevController as? WebContentController {
//                    webController.optimizeForBackground()
//                }
//            }
//            
//            // 인접 페이지 미리 로드
//            preloadAdjacentPages(around: index)
//        }
//    }
//}
