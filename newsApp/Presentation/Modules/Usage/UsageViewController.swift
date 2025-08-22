//
//  UsageViewController.swift
//  newsApp
//
//  Created by jay on 8/22/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit

class UsageViewController: UIViewController {
    
    // UI 컴포넌트들
    private var containerView: UIView!
    private var pageViewController: UIPageViewController!
    private var pageControl: UIPageControl!
    private var nextButton: UIButton!
    private var buttonStackView: UIStackView!
    
    // 데이터
    private var pages: [UsagePageViewController] = []
    private var currentIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPages()
        setupPageViewController()
    }
    
    private func setupUI() {
        // 배경 설정 - 흰색으로 깔끔하게
        view.backgroundColor = .white
        
        // 컨테이너 뷰 생성
        createContainerView()
        
        // 페이지 뷰컨트롤러 생성 (이제 전체 영역 사용)
        createPageViewController()
        
        // 페이지 컨트롤 생성
        createPageControl()
        
        // 버튼들 생성
        createButtons()
        
        // 레이아웃 설정
        setupConstraints()
    }
    
    private func createContainerView() {
        containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
    }
    
    private func createPageViewController() {
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        addChild(pageViewController)
        containerView.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
    }
    
    private func createPageControl() {
        pageControl = UIPageControl()
        pageControl.numberOfPages = 4  // 4개 페이지로 변경
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor(named: "neutral90*")
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.currentPageIndicatorTintColor =  UIColor(named: "neutral10*")
        containerView.addSubview(pageControl)
        pageControl.addTarget(self, action: #selector(pageControlTapped(_:)), for: .valueChanged)
    }
    
    @objc private func pageControlTapped(_ sender: UIPageControl) {
        let targetIndex = sender.currentPage
        
        // 어떤 페이지든 자유롭게 이동 가능
        if targetIndex < pages.count && targetIndex != currentIndex {
            let direction: UIPageViewController.NavigationDirection = targetIndex > currentIndex ? .forward : .reverse
            
            pageViewController.setViewControllers([pages[targetIndex]], direction: direction, animated: false) { _ in
                self.currentIndex = targetIndex
                self.updateUI()
            }
        }
    }
    
    private func createButtons() {
        // Next/Skip 버튼은 마지막 페이지에서만 표시
        nextButton = UIButton(type: .system)
        nextButton.setTitle("건너뛰기", for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.backgroundColor = UIColor.black
        nextButton.layer.cornerRadius = 20
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        
        buttonStackView = UIStackView(arrangedSubviews: [nextButton])
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 12
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(buttonStackView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 컨테이너 뷰 - 화면 전체 사용
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // 페이지 뷰컨트롤러 - 페이지 컨트롤 위까지 확장
            pageViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -20),
            
            // 페이지 컨트롤
            pageControl.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -30),
            
            // 버튼 스택뷰 - 하단 고정
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 64),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -64),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -40),
            buttonStackView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupPages() {
        for i in 0..<4 {  // 4개 페이지로 변경
            let page = UsagePageViewController()
            page.pageIndex = i
            pages.append(page)
        }
    }
    
    private func setupPageViewController() {
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        if let firstPage = pages.first {
            pageViewController.setViewControllers([firstPage], direction: .forward, animated: false, completion: nil)
        }
    }
    
    @objc private func skipButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func nextButtonTapped() {
        // 마지막 페이지에서 건너뛰기 버튼 클릭 시 닫기
        dismiss(animated: true, completion: nil)
    }
    
    private func updateUI() {
        pageControl.currentPage = currentIndex
        
        // 마지막 페이지에서만 버튼 표시
        if currentIndex == pages.count - 1 {
            nextButton.setTitle("한경 시작하기", for: .normal)
        } else {
//            nextButton.isHidden = true
            nextButton.setTitle("건너뛰기", for: .normal)
        }
    }
}

// MARK: - UIPageViewController DataSource & Delegate
extension UsageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let pageVC = viewController as? UsagePageViewController,
              let index = pages.firstIndex(of: pageVC),
              index > 0 else { return nil }
        return pages[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let pageVC = viewController as? UsagePageViewController,
              let index = pages.firstIndex(of: pageVC),
              index < pages.count - 1 else { return nil }
        return pages[index + 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if completed,
           let currentVC = pageViewController.viewControllers?.first as? UsagePageViewController,
           let index = pages.firstIndex(of: currentVC) {
            currentIndex = index
            updateUI()
        }
    }
}

// MARK: - UsagePageViewController.swift (개별 페이지)

class UsagePageViewController: UIViewController {
    
    // UI 컴포넌트들 - 이미지와 텍스트 모두 포함
    private var imageView: UIImageView!
    private var titleLabel: UILabel!
    private var descriptionLabel: UILabel!
    private var textContainerView: UIView!
    
    var pageIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupContent()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // 이미지뷰 생성
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // 텍스트 컨테이너 뷰
        textContainerView = UIView()
        textContainerView.backgroundColor = .systemBackground
        textContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textContainerView)
        
        // 타이틀 라벨 생성
        titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        textContainerView.addSubview(titleLabel)
        
        // 설명 라벨 생성
        descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.systemFont(ofSize: 15)
        descriptionLabel.textColor = .label
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        textContainerView.addSubview(descriptionLabel)
        
        // 레이아웃 설정
        NSLayoutConstraint.activate([
            // 이미지뷰 - 상단 60% 영역
            imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 88),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 64),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -64),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            // 텍스트 컨테이너 뷰 - 하단 영역
            textContainerView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            textContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 타이틀 라벨
            titleLabel.topAnchor.constraint(equalTo: textContainerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: textContainerView.leadingAnchor, constant: 64),
            titleLabel.trailingAnchor.constraint(equalTo: textContainerView.trailingAnchor, constant: -64),
            
            // 설명 라벨
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: textContainerView.leadingAnchor, constant: 64),
            descriptionLabel.trailingAnchor.constraint(equalTo: textContainerView.trailingAnchor, constant: -64),
        ])
    }
    
    private func setupContent() {
        switch pageIndex {
        case 0:
            titleLabel.text = "새로운 메인페이지"
            descriptionLabel.text = "한눈에, 쉽게, 빠르게!\n이제 메인 화면을 좌우로 넘기며 필요한 정보\n를 더 편하게 확인하세요."
            
            if let customImage = UIImage(named: "usage_first") {
                imageView.image = customImage
            } else {
                imageView.image = UIImage(systemName: "newspaper.fill")
                imageView.tintColor = .systemBlue
            }
            
        case 1:
            titleLabel.text = "탭 한 번이면 OK!"
            descriptionLabel.text = "이제 하단 탭으로 원하는 콘텐츠에 더 빠르게\n 접근하세요."
            
            if let customImage = UIImage(named: "usage_second") {
                imageView.image = customImage
            } else {
                imageView.image = UIImage(systemName: "bookmark.fill")
                imageView.tintColor = .systemBlue
            }
            
        case 2:
            titleLabel.text = "ALICE 업그레이드!"
            descriptionLabel.text = "AI 검색으로 더 쉽고 빠르게!\n검색은 ALICE에게.\n복잡한 정보, 빠르게 요약해드립니다."
            
            if let customImage = UIImage(named: "usage_third") {
                imageView.image = customImage
            } else {
                imageView.image = UIImage(systemName: "bell.fill")
                imageView.tintColor = .systemBlue
            }
            
        case 3:
            titleLabel.text = "한경의 모든 데이터, 마켓에서\n한눈에 확인해보세요."
            descriptionLabel.text = ""
            
            if let customImage = UIImage(named: "usage_fourth") {
                imageView.image = customImage
            } else {
                imageView.image = UIImage(systemName: "person.crop.circle.fill")
                imageView.tintColor = .systemBlue
            }
            
        default:
            break
        }
    }
}
