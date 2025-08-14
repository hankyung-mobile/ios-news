//
//  NewsContentController.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import WebKit
import RxSwift
import RxCocoa

class NewsContentController: UIViewController, PagingTabViewDelegate {
    func pagingTabView(didSelectTabAt index: Int) {
        moveToPage(at: index)
    }
    
    private let viewModel = NewsPageViewModel()
    @IBOutlet weak var titleImg: UIImageView!
    
    // 로딩 인디케이터 추가
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.color = .gray
        return indicator
    }()
    
    private lazy var pageViewController: UIPageViewController = {
        let controller = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        controller.dataSource = self
        controller.delegate = self
        return controller
    }()
    
    // 모든 웹뷰 컨트롤러를 미리 생성하여 저장
    private var allWebControllers: [WebContentController] = []
    
    // 현재 인덱스
    private var currentIndex = 0
    
    // 전환 상태 관리
    private var isTransitioning = false
    
    // 모든 웹뷰 로드 완료 상태
    private var allWebViewsLoaded = false
    
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var heightOfImg: NSLayoutConstraint!
    
    @IBOutlet weak var divider: UIView!
    
    @IBOutlet weak var header: UIView!
    
    @IBOutlet weak var btnMenu: UIButton!
    
    @IBOutlet weak var btnSearch: UIButton!
    
    private var hasShownAd: Bool = false
    
    private var pagingTabView: PagingTabView!
    
    private var targetTabIndex: Int?
    
    private var isPageChanging = false
    
    // ✅ 2순위 최적화: 스크롤 감도 조정을 위한 프로퍼티 추가
    private var lastScrollOffset: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // URL 캐시 설정
        configureURLCache()
        
        setupPagingTabView()
        setupPageViewController()
        
        
        setupLoadingIndicator()
        bindViewModel()
        
        // 메모리 경고 관찰
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
              self,
              selector: #selector(moveToPageWithURL),
              name: .moveToNewsPage,
              object: nil
          )
    }
    
    override func viewDidAppear(_ animated: Bool) {
         super.viewDidAppear(animated)
         
         if !hasShownAd {
             hasShownAd = true
             
             // 약간의 딜레이로 더 자연스럽게
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                 AdMobManager.shared.showAd(from: self)
             }
         }
     }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        showLoadingIndicator()
    }
    
    private func showLoadingIndicator() {
        DispatchQueue.main.async { [weak self] in
            self?.loadingIndicator.startAnimating()
            self?.pageViewController.view.isHidden = true
//            self?.titleImg?.isHidden = true
        }
    }
    
    private func hideLoadingIndicator() {
        DispatchQueue.main.async { [weak self] in
            self?.loadingIndicator.stopAnimating()
            self?.pageViewController.view.isHidden = false
            self?.titleImg?.isHidden = false
        }
    }
    
    private func configureURLCache() {
        let memoryCapacity = 20 * 1024 * 1024 // 20MB
        let diskCapacity = 100 * 1024 * 1024 // 100MB
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: nil)
        URLCache.shared = cache
    }
    
    private func setupPagingTabView() {
        pagingTabView = PagingTabView()
        pagingTabView.delegate = self // 탭 뷰의 이벤트를 받기 위해 delegate 설정
        view.addSubview(pagingTabView)
        
        // Auto Layout 설정
        pagingTabView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pagingTabView.topAnchor.constraint(equalTo: header.bottomAnchor),
            pagingTabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pagingTabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pagingTabView.heightAnchor.constraint(equalToConstant: 28) // 탭 뷰의 높이
        ])
    }
    
    private func setupPageViewController() {
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageViewController.view.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            pageViewController.view.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            pageViewController.view.topAnchor.constraint(equalTo: pagingTabView.bottomAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        pageViewController.view.subviews.compactMap { $0 as? UIScrollView }.first?.delegate = self
    }
    
    @objc private func handleMemoryWarning() {
        NotificationCenter.default.post(name: NSNotification.Name("OptimizeWebViewMemory"), object: nil)
    }
    
    @objc private func moveToPageWithURL(_ notification: Notification) {
        guard let url = notification.userInfo?["url"] as? String else { return }
        
        // WebContentViewController들에서 URL 매칭해서 이동
        for (index, webVC) in allWebControllers.enumerated() {
            // URL을 String으로 변환해서 비교
            let currentURLString = webVC.currentURL.absoluteString
            
            if currentURLString == url {
                moveToPage(at: index)
                return
            }
        }
    }

      private func moveToPage(at index: Int) {
          guard !isPageChanging else { return }
          guard index >= 0 && index < allWebControllers.count else { return }
          guard index != currentIndex else { return } // 같은 페이지면 무시
          
          isPageChanging = true
          
          let targetVC = allWebControllers[index]
          let direction: UIPageViewController.NavigationDirection = index > currentIndex ? .forward : .reverse
          
          pageViewController.setViewControllers([targetVC], direction: direction, animated: true) { [weak self] completed in
              self?.isPageChanging = false
              if completed {
                  self?.currentIndex = index
                  self?.pagingTabView.selectTab(at: index)
              }
          }
      }
    
    private func bindViewModel() {
        // 로딩 상태 구독
        viewModel.isLoading
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isLoading in
//                if isLoading && !self!.allWebViewsLoaded {
//                    self?.showLoadingIndicator()
//                } else {
//                    self?.hideLoadingIndicator()
//                }
                if isLoading {
                    self?.showLoadingIndicator()
                } else {
                    self?.hideLoadingIndicator()
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.currentPageIndex
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] index in
                guard let self = self, !self.isTransitioning else { return }
                self.isTransitioning = true
                
                guard index >= 0 && index < self.allWebControllers.count else {
                    self.isTransitioning = false
                    return
                }
                
                let controller = self.allWebControllers[index]
                let direction: UIPageViewController.NavigationDirection =
                    index > self.currentIndex ? .forward : .reverse
                
                self.pageViewController.setViewControllers([controller], direction: direction, animated: true) { [weak self] completed in
                    guard let self = self else { return }
                    
                    if completed {
                        self.currentIndex = index
                        self.updateTitleImage(for: index)
                    }
                    
                    self.isTransitioning = false
                    self.viewModel.isTransitioning.accept(false)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.isTransitioning
            .subscribe(onNext: { [weak self] isTransitioning in
                self?.isTransitioning = isTransitioning
            })
            .disposed(by: disposeBag)
        
        let existingSlides = AppDataManager.shared.getNewsSlideData()
        if !existingSlides.isEmpty {
            print("기존 마스터 데이터 사용 - 슬라이드 개수: \(existingSlides.count)")
            setupInitialPage(with: existingSlides)
        }
        
        viewModel.newsData
            .skip(existingSlides.isEmpty ? 0 : 1)
            .drive(onNext: { [weak self] data in
                if !data.isEmpty {
                    print("새로운 마스터 데이터 도착 - 슬라이드 개수: \(data.count)")
                    self?.setupInitialPage(with: data)
                }
            })
            .disposed(by: disposeBag)
        
        setupButtonEvents()
    }
    
    private func setupButtonEvents() {
        btnMenu.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                let newsMenu = MenuFactory.createNewsMenu(delegate: self)
                self?.present(newsMenu, animated: true)
            })
            .disposed(by: disposeBag)
        
        btnSearch.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                NotificationCenter.default.post(name: .closeSearchView, object: nil)
                let storyboard = UIStoryboard(name: "Search", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "SearchViewController") as! SearchViewController
                
                
                // 받은 데이터로 파라미터 전달
//                vc.parameters = getUserTokensParams()
                vc.webNavigationDelegate = self
                
                self?.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    // 모든 웹뷰 컨트롤러를 미리 생성하고 로드
    private func preloadAllWebViews() {
        let urls = viewModel.urls.value
        
        // 이미 생성되어 있으면 스킵
        guard allWebControllers.isEmpty else { return }
        
        print("🚀 모든 웹뷰 미리 로드 시작 - 총 \(urls.count)개")
        
        // 모든 웹뷰 컨트롤러 생성
        for (index, url) in urls.enumerated() {
            let controller = WebContentController(url: url)
            controller.webNavigationDelegate = self
            controller.preloadWebView() // 미리 로드 시작
            allWebControllers.append(controller)
            
            print("✅ 웹뷰 \(index + 1)/\(urls.count) 생성 및 로드 시작")
        }
        
        // 모든 웹뷰가 로드 완료되었는지 확인
//        checkAllWebViewsLoaded()
    }
    
    // 모든 웹뷰 로드 완료 확인
    private func checkAllWebViewsLoaded() {
        let loadedCount = allWebControllers.filter { $0.isWebViewLoaded }.count
        
//        print("📊 웹뷰 로드 상태: \(loadedCount)/\(allWebControllers.count)")
        
        if loadedCount == allWebControllers.count {
            allWebViewsLoaded = true
            hideLoadingIndicator()
            print("🎉 모든 웹뷰 로드 완료!")
        } else {
            // 0.5초 후 다시 확인
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.checkAllWebViewsLoaded()
            }
        }
    }
    
    private func findMainSlideIndex() -> Int {
        let slides = AppDataManager.shared.getNewsSlideData()
        return slides.firstIndex { $0.isMain ?? true } ?? 0
    }
    
    private func updateTitleImage(for index: Int) {
//        print("🔄 updateTitleImage 호출됨 - 인덱스: \(index)")
//
//        guard let titleImg = titleImg else {
//            print("❌ titleImg IBOutlet이 연결되지 않았습니다!")
//            return
//        }
//
//        let slides = AppDataManager.shared.getNewsSlideData()
//        print("📱 슬라이드 데이터 개수: \(slides.count), 현재 인덱스: \(index)")
//
//        guard index >= 0 && index < slides.count else {
//            print("⚠️ 인덱스 범위 초과: \(index), 최대: \(slides.count-1)")
//            return
//        }
//
//        let currentSlide = slides[index]
//        print("🎯 현재 슬라이드: id=\(String(describing: currentSlide.id)), title=\(String(describing: currentSlide.title))")
//        print("🖼️ 이미지 URL: '\(String(describing: currentSlide.image))'")
//
//        let defaultImage = UIImage(named: "hkLogo")
//
//        if ((currentSlide.image?.isEmpty) == nil) {
//            print("⚠️ 이미지 URL이 비어있음 - 디폴트 이미지 표시")
//            titleImg.image = defaultImage
//            return
//        }
//
//        print("🚀 SVG 로드 시작: \(currentSlide.image)")
//        titleImg.loadSVG(url: currentSlide.image ?? "", defaultImage: nil) {
//            self.view.layoutIfNeeded()
//        }

        return
        
    }
    
    private func setupInitialPage(with slides: [NewsSlideItem]) {
        // preloadAllWebViews()는 그대로 둡니다.
        preloadAllWebViews()
        
        let initialIndex = slides.firstIndex { $0.isMain ?? true } ?? 0
        print("초기 페이지 인덱스: \(initialIndex)")
        
        updateTitleImage(for: initialIndex)
        
        let tabTitles = slides.map { $0.title ?? "No Title" }
        pagingTabView.configure(with: tabTitles, initialIndex: initialIndex)
        
        // 기존 pageViewController 설정 코드는 그대로 둡니다.
        if !allWebControllers.isEmpty && initialIndex < allWebControllers.count {
            let initialController = allWebControllers[initialIndex]
            pageViewController.setViewControllers([initialController], direction: .forward, animated: false)
            
            currentIndex = initialIndex
            viewModel.currentPageIndex.accept(initialIndex)
            
            print("초기 페이지 설정 완료 - 인덱스: \(initialIndex)")
        } else {
            print("초기 컨트롤러 설정 실패 - 웹뷰가 아직 생성되지 않음")
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        NotificationCenter.default.post(name: NSNotification.Name("OptimizeWebViewMemory"), object: nil)
        
        // 현재 페이지와 인접 페이지만 활성 상태로 유지
        for (index, controller) in allWebControllers.enumerated() {
            if index == currentIndex || abs(index - currentIndex) <= 1 {
                controller.optimizeForForeground()
            } else {
                controller.optimizeForBackground()
            }
        }
    }
}

// MARK: - WebNavigationDelegate
extension NewsContentController: WebNavigationDelegate {
    func openNewsDetail(url: URL, title: String?) {
        print("NewsContentController: Opening news detail for URL: \(url)")
        
        let newsDetailVC = NewsDetailViewController(url: url, title: title)
        newsDetailVC.webNavigationDelegate = self
        newsDetailVC.hidesBottomBarWhenPushed = false
        
        navigationController?.pushViewController(newsDetailVC, animated: true)
    }
}

// MARK: - UIPageViewControllerDataSource
extension NewsContentController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentController = viewController as? WebContentController,
              let currentIndex = allWebControllers.firstIndex(of: currentController) else {
            return nil
        }
        
        let previousIndex = currentIndex - 1
        guard previousIndex >= 0 else { return nil }
        
        return allWebControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentController = viewController as? WebContentController,
              let currentIndex = allWebControllers.firstIndex(of: currentController) else {
            return nil
        }
        
        let nextIndex = currentIndex + 1
        guard nextIndex < allWebControllers.count else { return nil }
        
        return allWebControllers[nextIndex]
    }
}

// MARK: - UIPageViewControllerDelegate

extension NewsContentController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        isTransitioning = true
        viewModel.isTransitioning.accept(true)
        
        guard let targetController = pendingViewControllers.first as? WebContentController,
              let index = allWebControllers.firstIndex(of: targetController) else {
            return
        }
        self.targetTabIndex = index
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        isTransitioning = false
        viewModel.isTransitioning.accept(false)
        
        if completed,
           let controller = pageViewController.viewControllers?.first as? WebContentController,
           let index = allWebControllers.firstIndex(of: controller) {
            currentIndex = index
            
            controller.optimizeForForeground()
            
            for prevController in previousViewControllers {
                if let webController = prevController as? WebContentController {
                    webController.optimizeForBackground()
                }
            }
            
            self.updateTitleImage(for: index)
            
            if !isTransitioning {
                self.pagingTabView.selectTab(at: index)
                
                DispatchQueue.main.async {
                    self.pagingTabView.updateIndicator(from: index, to: index, with: 0.5)
                }
            }
        }
        
        self.targetTabIndex = nil
    }
}

extension NewsContentController: UIScrollViewDelegate {
    // ✅ 2순위 최적화: 스크롤 감도 조정으로 성능 향상
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView !== pagingTabView.collectionView,
              let targetIndex = self.targetTabIndex else { return }
        
        // 최소 이동거리 체크로 불필요한 호출 방지
        let currentOffset = scrollView.contentOffset.x
        guard abs(currentOffset - lastScrollOffset) > 2.0 else { return }
        lastScrollOffset = currentOffset
        
        let scrollOffset = currentOffset - view.frame.width
        let progress = abs(scrollOffset / view.frame.width)
        
        // progress 값 검증
        guard progress >= 0 && progress <= 1 else { return }
        
        // 탭 뷰에 인디케이터 업데이트 신호 전달
        pagingTabView.updateIndicator(from: currentIndex, to: targetIndex, with: progress)
    }
}
