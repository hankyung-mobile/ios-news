//
//  MenuViewController.swift
//  newsApp
//
//  Created by jay on 6/25/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

enum MenuType {
    case NEWS
    case PREMIUM
    case MARKET
}

class MenuViewController: UIViewController {
    
    @IBOutlet weak var menuTableView: UITableView!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var imgHeader: UIImageView!
    
    private let disposeBag = DisposeBag()
    private var cellTypes: [Any] = []
    
    // 뉴스 네비게이션 델리게이트 추가
    weak var webNavigationDelegate: WebNavigationDelegate?
    
    var menuType: MenuType = .NEWS
    private var newsViewModel: MenuPageViewModel?
    private var premiumViewModel: MenuPremiumViewModel?
    private var marketViewModel: MenuMarketViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setupViewModel()
        menuTableView.delegate = self
        menuTableView.dataSource = self
        bindViewModel()
        setupButtonEvents()
        
        
        loadData()
    }
    
    private func loadData() {
        switch menuType {
        case .NEWS:
            newsViewModel?.viewDidLoad.onNext(())
            imgHeader.image = UIImage(named: "newsMenu")
        case .PREMIUM:
            premiumViewModel?.viewDidLoad.onNext(())
            imgHeader.image = UIImage(named: "premiumMenu")
        case .MARKET:
            marketViewModel?.viewDidLoad.onNext(())
            imgHeader.image = UIImage(named: "marketMenu")
        }
    }
    
    private func setupViewModel() {
        // 타입에 따라 해당 ViewModel만 생성
        switch menuType {
        case .NEWS:
            newsViewModel = MenuPageViewModel()
        case .PREMIUM:
            premiumViewModel = MenuPremiumViewModel()
        case .MARKET:
            marketViewModel = MenuMarketViewModel()
        }
    }
    
    private func bindViewModel() {
        let cellTypesObservable: Observable<[Any]>
        
        switch menuType {
        case .NEWS:
            cellTypesObservable = newsViewModel!.cellTypes.map { $0 as [Any] }
        case .PREMIUM:
            cellTypesObservable = premiumViewModel!.cellTypes.map { $0 as [Any] }
        case .MARKET:
            cellTypesObservable = marketViewModel!.cellTypes.map { $0 as [Any] }
        }
        
        // 한 번만 바인딩
        cellTypesObservable
            .subscribe(onNext: { [weak self] cellTypes in
                self?.cellTypes = cellTypes
                self?.menuTableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
    
    private func setupButtonEvents() {
        // 메뉴 버튼 이벤트
        btnClose.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance) // 중복 탭 방지
            .subscribe(onNext: { [weak self] in
                
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func isLastItemInCurrentSection(at index: Int) -> Bool {
        // 현재 인덱스 이후에 같은 섹션 타입이 없는지 체크
        guard index < cellTypes.count - 1 else { return true }
        
        // 메뉴 타입에 따라 분기
        switch menuType {
        case .NEWS:
            let currentType = cellTypes[index] as! NewsCellType
            let nextType = cellTypes[index + 1] as! NewsCellType
            
            switch (currentType, nextType) {
            case (.sectionAItem, .sectionAItem),
                 (.sectionCItem, .sectionCItem),
                 (.sectionDItem, .sectionDItem):
                return false
            default:
                return true
            }
            
        case .PREMIUM:
            // 프리미엄 로직
            let currentType = cellTypes[index] as! PremiumCellType
            let nextType = cellTypes[index + 1] as! PremiumCellType
            
            switch (currentType, nextType) {
            case (.sectionAItem, .sectionAItem),
                 (.sectionBItem, .sectionBItem),
                 (.sectionCItem, .sectionCItem),
                 (.sectionDItem, .sectionDItem):
                return false
            default:
                return true
            }
            
        case .MARKET:
            // 마켓 로직
            let currentType = cellTypes[index] as! MarketCellType
            let nextType = cellTypes[index + 1] as! MarketCellType
            
            switch (currentType, nextType) {
            case (.sectionAItem, .sectionAItem),
                 (.sectionBItem, .sectionBItem),
                 (.sectionCItem, .sectionCItem),
                 (.sectionDItem, .sectionDItem):
                return false
            default:
                return true
            }
        }
    }
    
    private func handleItemSelection(item: Any) {
        var urlString: String?
        var isSlide: Bool?
        var browser: String?
        var title: String?
        
        // 타입별로 값 추출
        if let newsItem = item as? NewsMenuItem {
            urlString = newsItem.url
            isSlide = newsItem.isSlide
            browser = newsItem.browser
            title = newsItem.title
        } else if let premiumItem = item as? PremiumMenuItem {
            urlString = premiumItem.url
            isSlide = premiumItem.isSlide
            browser = premiumItem.browser
            title = premiumItem.title
        } else if let marketItem = item as? MarketMenuItem {
            urlString = marketItem.url
            isSlide = marketItem.isSlide
            title = marketItem.title
        }
        
        guard let url = urlString, !url.isEmpty,
              let validURL = URL(string: url) else {
            print("유효하지 않은 URL: \(urlString ?? "nil")")
            return
        }
        
        if isSlide == false {
            switch browser {
            case "WV":
                openInternalBrowser(url: validURL)
            case "MWV-G":
                webNavigationDelegate?.openNewsDetail(url: validURL, title: title)
                self.dismiss(animated: true)
            case "EXT":
                UIApplication.shared.open(validURL, options: [:])
            default:
                return
            }
        } else {
            
            // isSlide가 true인 경우 페이지 이동
            switch self.menuType {
            case .NEWS:
                NotificationCenter.default.post(
                    name: .moveToNewsPage,
                    object: nil,
                    userInfo: ["url": url]
                )
            case .PREMIUM:
                NotificationCenter.default.post(
                    name: .moveToPremiumPage,
                    object: nil,
                    userInfo: ["url": url]
                )
            case .MARKET:
                NotificationCenter.default.post(
                    name: .moveToMarketPage,
                    object: nil,
                    userInfo: ["url": url]
                )
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.dismiss(animated: true)
            }
        }
    }
    
    private func openInternalBrowser(url: URL) {
        let internalBrowserVC = InternalBrowserViewController(url: url)
        let navigationController = UINavigationController(rootViewController: internalBrowserVC)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)
    }
    
}

extension MenuViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < cellTypes.count else { return UITableViewCell() }
        
        let cellType = cellTypes[indexPath.row]
        
        // 메뉴 타입에 따라 분기 처리
        switch menuType {
        case .NEWS:
            return configureNewsCell(cellType as! NewsCellType, at: indexPath)
        case .PREMIUM:
            return configurePremiumCell(cellType as! PremiumCellType, at: indexPath)
        case .MARKET:
            return configureMarketCell(cellType as! MarketCellType, at: indexPath)
        }
    }
    
    private func configureNewsCell(_ cellType: NewsCellType, at indexPath: IndexPath) -> UITableViewCell {
        let isLastCell = indexPath.row == cellTypes.count - 1
        
        switch cellType {
        case .banner:
            guard let cell = menuTableView.dequeueReusableCell(withIdentifier: "MenuBannerTableViewCell", for: indexPath) as? MenuBannerTableViewCell else {
                return UITableViewCell()
            }
            return cell
            
        case .sectionHeader(let title):
            guard let cell = menuTableView.dequeueReusableCell(withIdentifier: "HeaderTableViewCell", for: indexPath) as? HeaderTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: title ?? "", type: menuType)
            return cell
            
        case .sectionAItem(let item), .sectionCItem(let item), .sectionDItem(let item):
            guard let cell = menuTableView.dequeueReusableCell(withIdentifier: "MenuTableViewCell", for: indexPath) as? MenuTableViewCell else {
                return UITableViewCell()
            }
            let isLastInSection = isLastItemInCurrentSection(at: indexPath.row)
            cell.configure(with: item, isLastCell: isLastInSection)
            
            cell.lyLastCellGap.isHidden = !isLastCell
            return cell
            
        case .sectionBGrid(let items):
            guard let cell = menuTableView.dequeueReusableCell(withIdentifier: "DynamicGridButtonCell", for: indexPath) as? DynamicGridButtonCell else {
                return UITableViewCell()
            }
            let buttonTitles = items.compactMap { $0.title }
            let buttonUrls = items.compactMap { $0.iconUrl }
            cell.configure(with: buttonTitles,imageUrls: buttonUrls)
            cell.delegate = self
            return cell
        }
    }
    
    private func configurePremiumCell(_ cellType: PremiumCellType, at indexPath: IndexPath) -> UITableViewCell {
        switch cellType {
        case .sectionHeader(let title):
            guard let cell = menuTableView.dequeueReusableCell(withIdentifier: "HeaderTableViewCell", for: indexPath) as? HeaderTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: title ?? "", type: menuType)
            return cell
            
        case .sectionAItem(let item), .sectionBItem(let item), .sectionCItem(let item), .sectionDItem(let item):
            guard let cell = menuTableView.dequeueReusableCell(withIdentifier: "MenuTableViewCell", for: indexPath) as? MenuTableViewCell else {
                return UITableViewCell()
            }
            let isLastInSection = isLastItemInCurrentSection(at: indexPath.row)
            cell.configure(with: item, isLastCell: isLastInSection)
            return cell
        }
    }
    
    private func configureMarketCell(_ cellType: MarketCellType, at indexPath: IndexPath) -> UITableViewCell {
        let isLastCell = indexPath.row == cellTypes.count - 1
        let isFirstCell = indexPath.row == 1
        
        switch cellType {
        case .banner:
            guard let cell = menuTableView.dequeueReusableCell(withIdentifier: "MenuBannerTableViewCell", for: indexPath) as? MenuBannerTableViewCell else {
                return UITableViewCell()
            }
            return cell
        case .sectionHeader(let title):
            guard let cell = menuTableView.dequeueReusableCell(withIdentifier: "HeaderTableViewCell", for: indexPath) as? HeaderTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: title ?? "", type: menuType)
            return cell
            
        case .sectionAItem(let item), .sectionBItem(let item), .sectionCItem(let item), .sectionDItem(let item):
            guard let cell = menuTableView.dequeueReusableCell(withIdentifier: "MenuTableViewCell", for: indexPath) as? MenuTableViewCell else {
                return UITableViewCell()
            }
            let isLastInSection = isLastItemInCurrentSection(at: indexPath.row)
            cell.configure(with: item, isLastCell: isLastInSection)
            
            if isFirstCell {
                cell.lyFirstCellGap.isHidden = false
                cell.heightOfLyFirstCellGap.constant = 24
            } else {
                cell.lyFirstCellGap.isHidden = true
                cell.heightOfLyFirstCellGap.constant = 13
            }
            cell.lyLastCellGap.isHidden = !isLastCell
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension MenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.row < cellTypes.count else { return }
        let cellType = cellTypes[indexPath.row]
        
        // 메뉴 타입에 따라 분기
        switch menuType {
        case .NEWS:
            handleNewsSelection(cellType as! NewsCellType, at: indexPath)
        case .PREMIUM:
            handlePremiumSelection(cellType as! PremiumCellType, at: indexPath)
        case .MARKET:
            handleMarketSelection(cellType as! MarketCellType, at: indexPath)
        }
    }
    
    private func handleNewsSelection(_ cellType: NewsCellType, at indexPath: IndexPath) {
        switch cellType {
        case .banner:
            // 헤더 셀은 선택 불가
            break
            
        case .sectionHeader:
            // 헤더 셀은 선택 불가
            break
            
        case .sectionAItem(let item), .sectionCItem(let item), .sectionDItem(let item):
            if item.url != nil {
                handleItemSelection(item: item)
            }
            
        case .sectionBGrid:
            // B섹션은 버튼 터치에서만 처리
            break
        }
    }
    
    private func handlePremiumSelection(_ cellType: PremiumCellType, at indexPath: IndexPath) {
        // 프리미엄 셀 선택 처리
        switch cellType {
        case .sectionHeader:
            // 헤더 셀은 선택 불가
            break
            
        case .sectionAItem(let item), .sectionBItem(let item), .sectionCItem(let item), .sectionDItem(let item):
            if item.url != nil {
                handleItemSelection(item: item)
            }
        }
    }
    
    private func handleMarketSelection(_ cellType: MarketCellType, at indexPath: IndexPath) {
        // 프리미엄 셀 선택 처리
        switch cellType {
        case .banner:
            // 헤더 셀은 선택 불가
            break
        case .sectionHeader:
            // 헤더 셀은 선택 불가
            break
            
        case .sectionAItem(let item), .sectionBItem(let item), .sectionCItem(let item), .sectionDItem(let item):
            if item.url != nil {
                handleItemSelection(item: item)
            }
        }
    }
}

// MARK: - Delegate 구현
extension MenuViewController: DynamicGridButtonCellDelegate {
    func gridButtonCell(_ cell: DynamicGridButtonCell, didSelectButtonAt index: Int, title: String) {
        guard let indexPath = menuTableView.indexPath(for: cell),
              indexPath.row < cellTypes.count else { return }
        
        // 메뉴 타입에 따라 분기
        switch menuType {
        case .NEWS:
            guard case .sectionBGrid(let items) = cellTypes[indexPath.row] as! NewsCellType,
                  index < items.count else { return }
            
            let selectedItem = items[index]
            handleItemSelection(item: selectedItem)
            
        case .PREMIUM, .MARKET:
            // 프리미엄 그리드 버튼 처리
            break
        }
        
//        dismiss(animated: true)
    }
}

extension MenuViewController {
    func getNewsViewModel() -> MenuPageViewModel? {
        return newsViewModel
    }
    
    func getPremiumViewModel() -> MenuPremiumViewModel? {
        return premiumViewModel
    }
    
    func getMarketViewModel() -> MenuMarketViewModel? {
        return marketViewModel
    }
}
