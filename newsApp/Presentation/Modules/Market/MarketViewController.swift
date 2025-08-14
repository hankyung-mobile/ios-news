//
//  MarketViewController.swift
//  newsApp
//
//  Created by jay on 6/16/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import WebKit
import RxSwift
import RxCocoa

class MarketViewController: UIViewController {
    private let viewModel = MarketPageViewModel()
    
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
    
    @IBOutlet weak var titleImg: UIImageView!
    
    @IBOutlet weak var divider: UIView!
    
    @IBOutlet weak var heightOfImg: NSLayoutConstraint!
    
    @IBOutlet weak var header: UIView!
    @IBOutlet weak var btnMenu: UIButton!
    @IBOutlet weak var btnSearch: UIButton!
    @IBOutlet weak var lbTitle: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // URL 캐시 설정
        configureURLCache()
        
        // 캐시 설정
//        contentControllerCache.countLimit = viewModel.urls.value.count // 모든 페이지 캐싱
        
        setupPageViewController()
        setupLoadingIndicator() // 로딩 인디케이터 설정 추가
        bindViewModel()
        
        // 메모리 경고 관찰 (안전하게 관찰자 추가)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
              self,
              selector: #selector(moveToPageWithURL),
              name: .moveToMarketPage,
              object: nil
          )
    }
    
    deinit {
        // 메모리 누수 방지를 위해 관찰자 제거
        NotificationCenter.default.removeObserver(self)
    }
    
    // 로딩 인디케이터 설정
    private func setupLoadingIndicator() {
        // 로딩 인디케이터 추가
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // 초기 상태: 로딩 표시
        showLoadingIndicator()
    }
    
    // 로딩 인디케이터 표시
    private func showLoadingIndicator() {
        DispatchQueue.main.async { [weak self] in
            self?.loadingIndicator.startAnimating()
            self?.pageViewController.view.isHidden = true
//            self?.titleImg?.isHidden = true
            self?.lbTitle.isHidden = true
        }
    }
    
    // 로딩 인디케이터 숨김
    private func hideLoadingIndicator() {
        DispatchQueue.main.async { [weak self] in
            self?.loadingIndicator.stopAnimating()
            self?.pageViewController.view.isHidden = false
//            self?.titleImg?.isHidden = false
            self?.lbTitle.isHidden = false
        }
    }
    
    private func configureURLCache() {
        // 캐시 크기 증가 (메모리 및 디스크 캐시)
        let memoryCapacity = 20 * 1024 * 1024 // 20MB
        let diskCapacity = 100 * 1024 * 1024 // 100MB
        
        // 커스텀 캐시 디렉토리 사용 시 크래시 가능성이 있어 nil로 설정
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: nil)
        URLCache.shared = cache
    }
    
    private func setupPageViewController() {
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.frame = view.bounds
        pageViewController.didMove(toParent: self)
        
        // pageViewController 레이아웃
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageViewController.view.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            pageViewController.view.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            pageViewController.view.topAnchor.constraint(equalTo: header.bottomAnchor), // ← header 아래에 배치
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
//        divider.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.06)
//        divider.layer.shadowOpacity = 0.85
//        divider.layer.shadowOffset = CGSize(width: 0, height: -2)
//        divider.layer.shadowRadius = 4
    }
    
    @objc private func handleMemoryWarning() {
        // 메모리 경고 알림 전송 (모든 웹뷰가 자체 최적화 수행)
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
          guard index >= 0 && index < allWebControllers.count else { return }
          guard index != currentIndex else {       NotificationCenter.default.post(
            name: .scrollToTop,
            object: nil,
            userInfo: nil)
              return
          } // 같은 페이지면 무시
          
          let targetVC = allWebControllers[index]
          let direction: UIPageViewController.NavigationDirection = index > currentIndex ? .forward : .reverse
          
          pageViewController.setViewControllers([targetVC], direction: direction, animated: true) { [weak self] completed in
              if completed {
                  self?.currentIndex = index
              }
          }
          updateTitleImage(for: index)
      }
    
    private func bindViewModel() {
        // 로딩 상태 구독 추가
        viewModel.isLoading
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isLoading in
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
        
        let existingSlides = AppDataManager.shared.getMarketSlideData()
        if !existingSlides.isEmpty {
            print("기존 마스터 데이터 사용 - 슬라이드 개수: \(existingSlides.count)")
            setupInitialPage(with: existingSlides)
        }
        
        // ViewModel의 masterData를 UI에 바인딩
        viewModel.marketData
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
                let MarketMenu = MenuFactory.createMarketMenu(delegate: self)
                self?.present(MarketMenu, animated: true)
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
            .disposed(by: disposeBag)    }
    
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
        let slides = AppDataManager.shared.getMarketSlideData()
        return slides.firstIndex { $0.isMain ?? false } ?? 0
    }
    
    private func updateTitleImage(for index: Int) {
        print("🔄 updateTitleImage 호출됨 - 인덱스: \(index)")
        
//        guard let titleImg = titleImg else {
//            print("❌ titleImg IBOutlet이 연결되지 않았습니다!")
//            return
//        }
        
        let slides = AppDataManager.shared.getMarketSlideData()
        print("📱 슬라이드 데이터 개수: \(slides.count), 현재 인덱스: \(index)")
        
        // 인덱스 범위 체크
        guard index >= 0 && index < slides.count else {
            print("⚠️ 인덱스 범위 초과: \(index), 최대: \(slides.count-1)")
            return
        }
        
        let currentSlide = slides[index]
        UIView.animate(withDuration: 0.18, animations: {
            self.lbTitle.alpha = 0
        }) { _ in
            self.lbTitle.text = currentSlide.title
            UIView.animate(withDuration: 0.18) {
                self.lbTitle.alpha = 1
            }
        }
//        print("🎯 현재 슬라이드: id=\(currentSlide.id), title=\(currentSlide.title)")
//        print("🖼️ 이미지 URL: '\(String(describing: currentSlide.image))'")
//        
//        // Assets에 있는 디폴트 이미지
//        let defaultImage = UIImage(named: "hkLogo")
//        
//        // 이미지 URL이 비어있으면 디폴트 이미지만 표시
//        if ((currentSlide.image?.isEmpty) == nil) {
//            print("⚠️ 이미지 URL이 비어있음 - 디폴트 이미지 표시")
//            titleImg.image = defaultImage
//            return
//        }
//        
//        // 현재 페이지의 슬라이드 이미지로 업데이트
//        print("🚀 SVG 로드 시작: \(String(describing: currentSlide.image))")
//        titleImg.loadSVG(url: currentSlide.image ?? "", defaultImage: nil) {
//            self.view.layoutIfNeeded()
//        }
    }
    
    // 초기 페이지 설정을 별도 메서드로 분리
    private func setupInitialPage(with slides: [MarketSlideItem]) {
        // 먼저 모든 웹뷰를 미리 로드
        preloadAllWebViews()
        
        // isMain이 true인 슬라이드의 인덱스 찾기
        let initialIndex = slides.firstIndex { $0.isMain ?? true } ?? 0
//        let initialIndex = 0
        print("초기 페이지 인덱스: \(initialIndex)")
        
        updateTitleImage(for: initialIndex)
        
        // 웹뷰가 생성되었는지 확인 후 초기 페이지 설정
        if !allWebControllers.isEmpty && initialIndex < allWebControllers.count {
            let initialController = allWebControllers[initialIndex]

            pageViewController.setViewControllers([initialController], direction: .forward, animated: false)
            
            // 현재 인덱스 업데이트
            currentIndex = initialIndex
            
            // ViewModel에도 현재 인덱스 동기화
            viewModel.currentPageIndex.accept(initialIndex)
            
            print("초기 페이지 설정 완료 - 인덱스: \(initialIndex)")
        } else {
            print("초기 컨트롤러 생성 실패 - 웹뷰가 아직 생성되지 않음")
        }
    }
    
    // 메모리 경고 시 일부 최적화 (모든 페이지 유지)
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // 모든 웹뷰에 메모리 최적화 알림 전송
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
extension MarketViewController: WebNavigationDelegate {
    func openNewsDetail(url: URL, title: String?) {
        print("MarketViewController: Opening news detail for URL: \(url)")
        
        // 뉴스 상세 뷰컨트롤러 생성
        let newsDetailVC = NewsDetailViewController(url: url, title: title)
        
        // 연쇄적으로 뉴스 상세를 열 수 있도록 델리게이트 설정
        newsDetailVC.webNavigationDelegate = self
        
        newsDetailVC.hidesBottomBarWhenPushed = false
        
        // 네비게이션 컨트롤러에 푸시 (겹겹이 쌓이는 효과)
        navigationController?.pushViewController(newsDetailVC, animated: true)
    }
}

// MARK: - UIPageViewControllerDataSource
extension MarketViewController: UIPageViewControllerDataSource {
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
extension MarketViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        isTransitioning = true
        viewModel.isTransitioning.accept(true)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        isTransitioning = false
        viewModel.isTransitioning.accept(false)
        
        if completed,
           let controller = pageViewController.viewControllers?.first as? WebContentController,
           let index = allWebControllers.firstIndex(of: controller) {

            currentIndex = index
            
            // 현재 페이지 포그라운드 최적화
            controller.optimizeForForeground()
            
            // 이전 페이지들 백그라운드 최적화
            for prevController in previousViewControllers {
                if let webController = prevController as? WebContentController {
                    webController.optimizeForBackground()
                }
            }
        
            self.updateTitleImage(for: index)
        }
    }
}

