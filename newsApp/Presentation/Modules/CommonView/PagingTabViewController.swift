//
//  PagingTabViewController.swift
//  newsApp
//
//  Created by jay on 7/31/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit

// MARK: - UI Constants for Easy Maintenance
fileprivate enum UI {
    static let tabHeight: CGFloat = 28.0
    static let labelHeight: CGFloat = 20.0
    static let indicatorHeight: CGFloat = 4.0
    static let labelToIndicatorPadding: CGFloat = 6.0
    static let cellHorizontalPadding: CGFloat = 4.0
    static let cellSpacing: CGFloat = 16.0
    static let defaultFontSize: CGFloat = 15.0
    static let dividerHeight: CGFloat = 1.0
}

// MARK: - Delegate Protocol
protocol PagingTabViewDelegate: AnyObject {
    func pagingTabView(didSelectTabAt index: Int)
}

// MARK: - PagingTabView (The Reusable View)
class PagingTabView: UIView {
    
    // MARK: - Properties
    weak var delegate: PagingTabViewDelegate?
    private var tabTitles: [String] = []
    private var selectedTabIndex: Int = 0
    
    private var cachedLayoutAttributes: [Int: UICollectionViewLayoutAttributes] = [:]
    private var lastProgress: CGFloat = -1
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = UI.cellSpacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.showsHorizontalScrollIndicator = false
        cv.register(TabCell.self, forCellWithReuseIdentifier: TabCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        cv.delaysContentTouches = false  // 터치 지연 제거
        cv.canCancelContentTouches = true
        return cv
    }()
    
    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(named: "#1A1A1A")
        view.layer.cornerRadius = UI.indicatorHeight / 2
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.22)
        return view
    }()
    
    private var hasInitialScrolled = false
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        cachedLayoutAttributes.removeAll()
        lastProgress = -1
        
        if !hasInitialScrolled && selectedTabIndex < tabTitles.count {
            hasInitialScrolled = true
            let indexPath = IndexPath(item: selectedTabIndex, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let expandedBounds = bounds.insetBy(dx: -5, dy: -10)
        return expandedBounds.contains(point)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        addSubview(collectionView)
        addSubview(dividerView)
        collectionView.addSubview(indicatorView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // CollectionView가 디바이더 위에 위치하도록 제약 조건 수정
            collectionView.topAnchor.constraint(equalTo: self.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            // 디바이더를 뷰의 가장 하단에 고정
            dividerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            dividerView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: UI.dividerHeight)
        ])
    }
    
    // MARK: - Public Methods
    func configure(with titles: [String], initialIndex: Int) {
        self.tabTitles = titles
        self.selectedTabIndex = initialIndex
        self.collectionView.reloadData()
        
        cachedLayoutAttributes.removeAll()
        lastProgress = -1
        
        DispatchQueue.main.async {
            self.collectionView.selectItem(at: IndexPath(item: initialIndex, section: 0), animated: false, scrollPosition: .centeredHorizontally)
            self.setInitialTab(at: initialIndex)
        }
    }
    
    private func setInitialTab(at index: Int) {
        guard index >= 0, index < tabTitles.count else { return }
        
        let indexPath = IndexPath(item: index, section: 0)
        
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        moveIndicator(to: index, animated: false)
        
        print("🎯 초기 탭 설정 완료: index=\(index)")
    }
    
    func selectTab(at index: Int) {
        guard index != selectedTabIndex,
              index >= 0,
              index < tabTitles.count else { return }
        
        let previousIndex = selectedTabIndex
        selectedTabIndex = index
        
        collectionView.selectItem(at: IndexPath(item: index, section: 0), animated: true, scrollPosition: .centeredHorizontally)
        moveIndicator(to: index, animated: true)
        
        print("🎯 탭 선택: \(previousIndex) → \(index)")
    }
    
    func updateIndicator(from currentIndex: Int, to targetIndex: Int, with progress: CGFloat) {
        guard abs(progress - lastProgress) > 0.01 else { return }
        guard progress >= 0 && progress <= 1 else { return }
        
        lastProgress = progress
        
        let currentAttrs = getCachedLayoutAttributes(for: currentIndex)
        let targetAttrs = getCachedLayoutAttributes(for: targetIndex)
        
        guard let current = currentAttrs, let target = targetAttrs else { return }
        
        let deltaX = target.frame.origin.x - current.frame.origin.x
        let deltaWidth = target.frame.width - current.frame.width
        
        let x = current.frame.origin.x + (deltaX * progress)
        let width = current.frame.width + (deltaWidth * progress)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        indicatorView.frame = CGRect(
            x: x,
            y: collectionView.bounds.height - UI.indicatorHeight,
            width: width,
            height: UI.indicatorHeight
        )
        
        CATransaction.commit()
    }
    
    private func getCachedLayoutAttributes(for index: Int) -> UICollectionViewLayoutAttributes? {
        if let cached = cachedLayoutAttributes[index] {
            return cached
        }
        
        let indexPath = IndexPath(item: index, section: 0)
        if let attributes = collectionView.layoutAttributesForItem(at: indexPath) {
            cachedLayoutAttributes[index] = attributes
            return attributes
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    private func moveIndicator(to index: Int, animated: Bool) {
        guard index >= 0,
              index < tabTitles.count else {
            print("⚠️ moveIndicator 실패: index=\(index), tabTitles.count=\(tabTitles.count)")
            return
        }
        
        let attributes = getCachedLayoutAttributes(for: index)
        guard let attrs = attributes else { return }
        
        let indicatorFrame = CGRect(
            x: attrs.frame.origin.x,
            y: collectionView.bounds.height - UI.indicatorHeight,
            width: attrs.frame.width,
            height: UI.indicatorHeight
        )
        
        print("📍 인디케이터 이동: index=\(index), frame=\(indicatorFrame), animated=\(animated)")
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.1, options: [.curveEaseOut]) {
                self.indicatorView.frame = indicatorFrame
            } completion: { _ in
                print("✅ 인디케이터 애니메이션 완료")
            }
        } else {
            self.indicatorView.frame = indicatorFrame
            print("✅ 인디케이터 즉시 이동 완료")
        }
    }
}

// MARK: - CollectionView DataSource & Delegate
extension PagingTabView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabTitles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TabCell.identifier, for: indexPath) as! TabCell
        cell.configure(with: tabTitles[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("🔥 탭 터치됨: \(indexPath.item)")
        delegate?.pagingTabView(didSelectTabAt: indexPath.item)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let title = tabTitles[indexPath.item]
        let font = UIFont.systemFont(ofSize: UI.defaultFontSize, weight: .medium)
        let width = title.size(withAttributes: [.font: font]).width + (UI.cellHorizontalPadding * 2)
        // ✅ 수정된 부분: 전체 탭 뷰 높이에서 디바이더 높이를 뺀 만큼을 셀 높이로 사용
        return CGSize(width: width, height: UI.tabHeight - UI.dividerHeight)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        cachedLayoutAttributes.removeAll()
    }
}

// MARK: - Tab Cell
fileprivate class TabCell: UICollectionViewCell {
    static let identifier = "TabCell"
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: UI.defaultFontSize)
        return label
    }()
    
    override var isSelected: Bool {
        didSet {
            titleLabel.font = isSelected ? .boldSystemFont(ofSize: UI.defaultFontSize) : .systemFont(ofSize: UI.defaultFontSize)
            titleLabel.textColor = UIColor(named: "1A1A1A")
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: UI.labelHeight),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -(UI.indicatorHeight + UI.labelToIndicatorPadding))
        ])
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(with title: String) { titleLabel.text = title }
}
