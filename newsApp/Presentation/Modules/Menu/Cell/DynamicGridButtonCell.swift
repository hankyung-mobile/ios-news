//
//  DynamicGridButtonCell.swift
//  newsApp
//
//  Created by jay on 6/26/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit

protocol DynamicGridButtonCellDelegate: AnyObject {
    func gridButtonCell(_ cell: DynamicGridButtonCell, didSelectButtonAt index: Int, title: String)
}

class DynamicGridButtonCell: UITableViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet weak var containerView: UIView!
    
    // MARK: - Properties
    weak var delegate: DynamicGridButtonCellDelegate?
    private var buttonTitles: [String] = []
    private var buttonIcons: [String] = [] // SF Symbol 이름들
    private var buttonImageUrls: [String?] = [] // SVG URL들 저장
    private var currentNumberOfColumns: Int = 4
    
    // MARK: - Constants
    private let itemWidth: CGFloat = 74
    private let itemHeight: CGFloat = 71
    private let itemSpacing: CGFloat = 16
    private let verticalPadding: CGFloat = 0
    private let minimumHorizontalPadding: CGFloat = 20
    
    private var isRotating = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // 다크모드가 변경되었을 때만 업데이트
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            print("🌓 다크모드 변경 감지 - 이미지 틴트 업데이트")
            updateAllImageTints()
        }
    }
    
    private func setupUI() {
        containerView.backgroundColor = .clear
        selectionStyle = .none
    }
    
    // MARK: - Configuration
    func configure(with buttonTitles: [String], icons: [String]? = nil, imageUrls: [String?]? = nil) {
        self.buttonTitles = buttonTitles
        self.buttonIcons = icons ?? getDefaultIcons(for: buttonTitles)
        self.buttonImageUrls = imageUrls ?? [] // SVG URL 배열 저장
        
        createButtonGrid()
    }
    
    // 기본 아이콘 매핑 (한글 텍스트에 맞는 SF Symbol)
    private func getDefaultIcons(for titles: [String]) -> [String] {
        var icons: [String] = []
        
        for title in titles {
            switch title {
            case "코인마켓":
                icons.append("chart.line.uptrend.xyaxis")
            case "글로벌마켓":
                icons.append("globe")
            case "집코노미":
                icons.append("house.fill")
            case "오피니언":
                icons.append("message.fill")
            case "경제":
                icons.append("chart.bar.fill")
            case "금융":
                icons.append("dollarsign.circle.fill")
            case "산업":
                icons.append("building.2.fill")
            case "유통":
                icons.append("shippingbox.fill")
            case "테크":
                icons.append("cpu")
            case "국제":
                icons.append("globe.americas.fill")
            case "정치":
                icons.append("building.columns.fill")
            case "사회":
                icons.append("person.3.fill")
            case "골프":
                icons.append("sportscourt.fill")
            case "문화":
                icons.append("theatermasks.fill")
            case "한경트래블":
                icons.append("airplane")
            case "트렌드":
                icons.append("arrow.up.right")
            default:
                icons.append("square.grid.2x2")
            }
        }
        
        return icons
    }
    
    // 화면 크기에 따른 열 개수 계산
    private func calculateNumberOfColumns(for width: CGFloat) -> Int {
        // 사용 가능한 너비 계산 (최소 패딩 고려)
        let availableWidth = width - (minimumHorizontalPadding * 2)
        
        // 최대 열 개수 계산 (아이템 너비 + 간격 고려)
        var columns = 1
        while true {
            let totalItemWidth = itemWidth * CGFloat(columns)
            let totalSpacing = itemSpacing * CGFloat(columns - 1)
            let totalWidth = totalItemWidth + totalSpacing
            
            if totalWidth <= availableWidth {
                columns += 1
            } else {
                break
            }
        }
        
        // 최소 1개, 최대값은 제한 없음
        return max(1, columns - 1)
    }
    
    // 셀의 높이를 계산하는 메서드
    func calculateCellHeight(for width: CGFloat) -> CGFloat {
        let columns = calculateNumberOfColumns(for: width)
        let numberOfRows = ceil(Double(buttonTitles.count) / Double(columns))
        let totalHeight = (itemHeight * CGFloat(numberOfRows)) +
                         (itemSpacing * CGFloat(numberOfRows - 1)) +
                         (verticalPadding * 2)
        return totalHeight
    }
    
    private func createButtonGrid() {
        // 기존 뷰 제거
        containerView.subviews.forEach { $0.removeFromSuperview() }
        
        guard !buttonTitles.isEmpty else { return }
        
        // 현재 화면 너비 가져오기
        let screenWidth = containerView.frame.width > 0 ? containerView.frame.width : UIScreen.main.bounds.width
        
        // 열 개수 계산
        currentNumberOfColumns = calculateNumberOfColumns(for: screenWidth)
        
        // 그리드 컨테이너 뷰
        let gridContainer = UIView()
        containerView.addSubview(gridContainer)
        gridContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 중앙 정렬을 위한 패딩 계산
        let totalItemWidth = (itemWidth * CGFloat(currentNumberOfColumns))
        let totalSpacing = itemSpacing * CGFloat(currentNumberOfColumns - 1)
        let totalWidth = totalItemWidth + totalSpacing
        let horizontalPadding = max((screenWidth - totalWidth) / 2, minimumHorizontalPadding)
        
        NSLayoutConstraint.activate([
            gridContainer.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            gridContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            gridContainer.widthAnchor.constraint(equalToConstant: totalWidth),
            gridContainer.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -verticalPadding),
        ])
        
        // 버튼 생성 및 배치
        for (index, title) in buttonTitles.enumerated() {
            let button = createImageButton(
                title: title,
                icon: index < buttonIcons.count ? buttonIcons[index] : "square.grid.2x2",
                index: index
            )
            gridContainer.addSubview(button)
            
            button.translatesAutoresizingMaskIntoConstraints = false
            
            // 위치 계산
            let column = index % currentNumberOfColumns
            let row = index / currentNumberOfColumns
            
            let xPosition = CGFloat(column) * (itemWidth + itemSpacing)
            let yPosition = CGFloat(row) * (itemHeight + itemSpacing)
            
            // 제약조건 설정
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: gridContainer.leadingAnchor, constant: xPosition),
                button.topAnchor.constraint(equalTo: gridContainer.topAnchor, constant: yPosition),
                button.widthAnchor.constraint(equalToConstant: itemWidth),
                button.heightAnchor.constraint(equalToConstant: itemHeight)
            ])
        }
        
        // gridContainer의 높이 설정 (마지막 행까지 포함)
        let numberOfRows = ceil(Double(buttonTitles.count) / Double(currentNumberOfColumns))
        let containerHeight = (itemHeight * CGFloat(numberOfRows)) + (itemSpacing * CGFloat(numberOfRows - 1))
        gridContainer.heightAnchor.constraint(equalToConstant: containerHeight).isActive = true
    }
    
    private func createImageButton(title: String, icon: String, index: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = index
        
        // 버튼 스타일
        button.backgroundColor = .clear
//        button.layer.cornerRadius = 8
//        button.layer.borderWidth = 0.5
//        button.layer.borderColor = UIColor.separator.cgColor
        
        // 컨테이너 뷰
        let containerStack = UIStackView()
        containerStack.axis = .vertical
        containerStack.alignment = .center
        containerStack.spacing = 8
        containerStack.distribution = .fillProportionally
        containerStack.isUserInteractionEnabled = false
        
        // 아이콘 이미지뷰
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        
        // SVG URL이 있으면 처리
        if index < buttonImageUrls.count,
           let imageUrl = buttonImageUrls[index],
           !imageUrl.isEmpty {
            
            // 🔥 변환된 이미지 캐시에서 먼저 확인 - 즉시 표시!
            if let cachedImage = SVGImageCache.shared.getCachedImage(for: imageUrl) {
                imageView.image = cachedImage
                applyTintColorToSVGImage(imageView)
//                print("⚡ 캐시된 이미지 즉시 표시: \(imageUrl)")
            } else {
                // 🔥 시작 시 투명하게
                imageView.alpha = 0.1
                
                imageView.loadSVG(url: imageUrl, defaultImage: nil, size: CGSize(width: 36, height: 36), animated: false) {
                    DispatchQueue.main.async {
                        // 🔥 커스텀 페이드인 애니메이션
                        UIView.animate(withDuration: 0.8, delay: 0, options: [.curveEaseOut]) {
                            imageView.alpha = 1.0
                        }
                        self.applyTintColorToSVGImage(imageView)
                    }
                    print("📦 새로 로드 완료: \(imageUrl)")
                }
            }
        } else {
            // SVG URL이 없으면 SF Symbol만 사용
            let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
            imageView.image = UIImage(systemName: icon, withConfiguration: config)
            imageView.tintColor = .label
        }
        
        // 나머지 코드는 동일...
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        
        containerStack.addArrangedSubview(imageView)
        containerStack.addArrangedSubview(label)
        
        button.addSubview(containerStack)
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerStack.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            containerStack.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            containerStack.leadingAnchor.constraint(greaterThanOrEqualTo: button.leadingAnchor, constant: 4),
            containerStack.trailingAnchor.constraint(lessThanOrEqualTo: button.trailingAnchor, constant: -4),
            
            imageView.widthAnchor.constraint(equalToConstant: 36),
            imageView.heightAnchor.constraint(equalToConstant: 36),
            
            label.widthAnchor.constraint(lessThanOrEqualTo: button.widthAnchor, constant: -8)
        ])
        
        // 터치 이벤트
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        return button
    }
    
    private func applyTintColorToSVGImage(_ imageView: UIImageView) {
        guard let image = imageView.image else { return }
        
        imageView.image = image.withRenderingMode(.alwaysTemplate)
        
        if traitCollection.userInterfaceStyle == .dark {
            // 다크모드: 커스텀 색상 적용
            imageView.tintColor = UIColor.white // 또는 원하는 색상
        } else {
            // 라이트모드: 커스텀 색상 적용
            imageView.tintColor = UIColor.black
        }
    }
    
    private func updateAllImageTints() {
        // 모든 버튼의 이미지뷰 찾아서 틴트 업데이트
        containerView.subviews.forEach { gridContainer in
            gridContainer.subviews.forEach { button in
                if let button = button as? UIButton {
                    // 버튼 내부의 이미지뷰 찾기
                    findImageViewInButton(button) { imageView in
                        // SVG 이미지만 틴트 적용 (SF Symbol 제외)
                        if imageView.image?.renderingMode == .alwaysTemplate {
                            applyTintColorToSVGImage(imageView)
                        }
                    }
                }
            }
        }
    }

    // 🔥 버튼 내부의 이미지뷰 찾기 헬퍼 메서드
    private func findImageViewInButton(_ button: UIButton, completion: (UIImageView) -> Void) {
        button.subviews.forEach { stackView in
            if let stackView = stackView as? UIStackView {
                stackView.arrangedSubviews.forEach { view in
                    if let imageView = view as? UIImageView {
                        completion(imageView)
                    }
                }
            }
        }
    }
    
    // MARK: - Button Actions
    @objc private func buttonTapped(_ sender: UIButton) {
        guard sender.tag < buttonTitles.count else { return }
        let title = buttonTitles[sender.tag]
        delegate?.gridButtonCell(self, didSelectButtonAt: sender.tag, title: title)
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            sender.alpha = 0.8
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
            sender.alpha = 1.0
        }
    }
    
    // 레이아웃 변경 감지
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard !buttonTitles.isEmpty,
              containerView.frame.width > 0 else { return }
        
        let newColumns = calculateNumberOfColumns(for: containerView.frame.width)
        
        // 열 개수가 변경되었을 때만 재생성
        if newColumns != currentNumberOfColumns && !isRotating {
            print("🔄 열 개수 변경 감지: \(currentNumberOfColumns) -> \(newColumns)")
            
            isRotating = true
            currentNumberOfColumns = newColumns
            
            // 메인 큐에서 비동기로 실행
            DispatchQueue.main.async { [weak self] in
                self?.createButtonGrid()
                self?.isRotating = false
                
                // 테이블뷰에 높이 변경 알림
                if let tableView = self?.superview as? UITableView {
                    tableView.beginUpdates()
                    tableView.endUpdates()
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        containerView.subviews.forEach { $0.removeFromSuperview() }
        buttonTitles.removeAll()
        buttonIcons.removeAll()
        buttonImageUrls.removeAll()
        currentNumberOfColumns = 4
    }
}
