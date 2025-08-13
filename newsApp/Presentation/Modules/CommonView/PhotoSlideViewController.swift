//
//  PhotoSlideViewController.swift
//  newsApp
//
//  Created by jay on 7/23/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PhotoSlideViewController: UIViewController {
    
    private var pageViewController: UIPageViewController!
    private var imageUrls: [String] = []  // 빈 배열로 초기화
    private var currentIndex: Int = 0
    @IBOutlet weak var header: UIView!
    @IBOutlet weak var btnClose: UIButton!
    private let disposeBag = DisposeBag()
    
    // 이미지 캐시
    private let imageCache = NSCache<NSString, UIImage>()
    
    // 스토리보드에서 생성할 때 사용
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupImageViews()
        setupButtonEvents()
    }
    
    // 이미지 URL을 설정하는 메서드
    func configure(with imageUrls: [String]) {
        self.imageUrls = imageUrls
        
        // 이미 뷰가 로드된 경우 즉시 업데이트
        if isViewLoaded {
            setupImageViews()
        }
    }
    
    private func setupImageViews() {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .light)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        btnClose.setImage(image, for: .normal)
        btnClose.tintColor = UIColor(named: "#1A1A1A")
        
        // 이미지가 없는 경우
        if imageUrls.isEmpty {
            showNoImageMessage()
            return
        }
        
        // 이미지가 1개인 경우 - 단일 이미지 뷰
        if imageUrls.count == 1 {
            setupSingleImageView()
        } else {
            // 여러 이미지인 경우 - PageViewController
            setupPageViewController()
        }
        
    }
    
    // 버튼 이벤트 설정
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
    
    // 이미지가 없을 때
    private func showNoImageMessage() {
        let label = UILabel()
        label.text = "해당 이미지가 없습니다."
        label.textColor = .label
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // 이미지가 1개일 때
    private func setupSingleImageView() {
        let scrollView = createZoomableScrollView()
        let imageView = createImageView()
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        
        // ScrollView delegate 연결
        scrollView.delegate = self
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -83),
            
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        loadImage(from: imageUrls[0]) { image in
            DispatchQueue.main.async {
                imageView.image = image
            }
        }
    }
    
    // 이미지가 여러개일 때
    private func setupPageViewController() {
        pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: header.bottomAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -83)
        ])
        
        pageViewController.didMove(toParent: self)
        
        // 첫 번째 이미지로 시작
        let firstViewController = createImageViewController(at: 0)
        pageViewController.setViewControllers([firstViewController],
                                            direction: .forward,
                                            animated: false,
                                            completion: nil)
    }
    
    private func createZoomableScrollView() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }
    
    private func createImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }
    
    private func createImageViewController(at index: Int) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground
        
        let scrollView = createZoomableScrollView()
        let imageView = createImageView()
        
        // ScrollView delegate 연결
        scrollView.delegate = self
        
        viewController.view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        // 인덱스 정보 저장
        viewController.view.tag = index
        
        if index < imageUrls.count {
            let urlString = imageUrls[index]
            loadImage(from: urlString) { image in
                DispatchQueue.main.async {
                    imageView.image = image
                }
            }
        }
        
        return viewController
    }
    
    private func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        // 캐시에서 먼저 확인
        if let cachedImage = imageCache.object(forKey: urlString as NSString) {
            completion(cachedImage)
            return
        }
        
        // URL에서 이미지 다운로드
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                  let image = UIImage(data: data),
                  error == nil else {
                completion(nil)
                return
            }
            
            // 캐시에 저장
            self?.imageCache.setObject(image, forKey: urlString as NSString)
            completion(image)
        }.resume()
    }
    
    private func updatePageControl() {
        // 페이지 컨트롤 제거됨
    }
}

// MARK: - UIPageViewControllerDataSource (여러 이미지일 때만)
extension PhotoSlideViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = viewController.view.tag
        guard index > 0 else { return nil }
        return createImageViewController(at: index - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = viewController.view.tag
        guard index < imageUrls.count - 1 else { return nil }
        return createImageViewController(at: index + 1)
    }
}

// MARK: - UIPageViewControllerDelegate
extension PhotoSlideViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if completed,
           let currentViewController = pageViewController.viewControllers?.first {
            currentIndex = currentViewController.view.tag
            updatePageControl()
        }
    }
}

// MARK: - UIScrollViewDelegate (줌 기능)
extension PhotoSlideViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        // ScrollView의 첫 번째 UIImageView 반환
        return scrollView.subviews.first(where: { $0 is UIImageView })
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // 줌 후 이미지를 중앙에 위치시키기
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
}
