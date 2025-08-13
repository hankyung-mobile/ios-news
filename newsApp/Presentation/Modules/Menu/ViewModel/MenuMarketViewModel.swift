//
//  MenuMarketViewModel.swift
//  newsApp
//
//  Created by jay on 7/2/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import RxSwift
import RxCocoa
import Alamofire
import RxAlamofire

enum MarketCellType {
    case banner
    case sectionHeader(String?)  // 헤더용 추가
    case sectionAItem(MarketMenuItem)
    case sectionBItem(MarketMenuItem)
    case sectionCItem(MarketMenuItem)
    case sectionDItem(MarketMenuItem)
}


class MenuMarketViewModel {
    private let disposeBag = DisposeBag()
    
    let viewDidLoad = PublishSubject<Void>()
    
    lazy var cellTypes: Observable<[MarketCellType]> = {
        return viewDidLoad
            .map { _ in
                let sectionsWithKeys = AppDataManager.shared.getAllMarketMenuSectionsWithKeys()
                var cellTypes: [MarketCellType] = []
                
                cellTypes.append(.banner)
                
                for (key, section) in sectionsWithKeys {
                    // 🔥 각 섹션 시작 전에 헤더 셀 추가
                    if key != "A" {
                        let headerTitle = section.title?.name
                        cellTypes.append(.sectionHeader(headerTitle))
                    }
                    
                    // 섹션별 아이템 처리
                    switch key {
                    case "A": // A섹션 - 각 아이템별로 셀 생성
                        section.list?.forEach { item in
                            cellTypes.append(.sectionAItem(item))
                        }
                        
                    case "B": // B섹션 - 각 아이템별로 셀 생성
                        section.list?.forEach { item in
                            cellTypes.append(.sectionBItem(item))
                        }
                        
                    case "C": // C섹션 - 각 아이템별로 셀 생성
                        section.list?.forEach { item in
                            cellTypes.append(.sectionCItem(item))
                        }
                        
                    case "D": // D섹션 - 각 아이템별로 셀 생성
                        section.list?.forEach { item in
                            cellTypes.append(.sectionDItem(item))
                        }
                        
                    default:
                        // E, F, G 등 새로운 섹션들 자동 처리
                        section.list?.forEach { item in
                            cellTypes.append(.sectionDItem(item))
                        }
                    }
                }
                
                return cellTypes
            }
    }()
}
