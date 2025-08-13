//
//  MenuPremiumViewModel.swift
//  newsApp
//
//  Created by jay on 6/30/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import RxSwift
import RxCocoa
import Alamofire
import RxAlamofire

enum PremiumCellType {
    case sectionHeader(String?)  // 헤더용 추가
    case sectionAItem(PremiumMenuItem)
    case sectionBItem(PremiumMenuItem)
    case sectionCItem(PremiumMenuItem)
    case sectionDItem(PremiumMenuItem)
}

class MenuPremiumViewModel {
    private let disposeBag = DisposeBag()
    
    let viewDidLoad = PublishSubject<Void>()
    
    lazy var cellTypes: Observable<[PremiumCellType]> = {
        return viewDidLoad
            .map { _ in
                let sections = AppDataManager.shared.getAllPremiumMenuSections()
                var cellTypes: [PremiumCellType] = []
                
                for (index, section) in sections.enumerated() {
                    // 각 섹션 시작 전에 헤더 셀 추가
                    let headerTitle = section.title?.name
                    cellTypes.append(.sectionHeader(headerTitle))
                    
                    switch index {
                    case 0: // A섹션 - 각 아이템별로 셀 생성
                        section.list?.forEach { item in
                            cellTypes.append(.sectionAItem(item))
                        }
                        
                    case 1: // B섹션 - 각 아이템별로 셀 생성
                        section.list?.forEach { item in
                            cellTypes.append(.sectionBItem(item))
                        }
                        
                    case 2: // C섹션 - 각 아이템별로 셀 생성
                        section.list?.forEach { item in
                            cellTypes.append(.sectionCItem(item))
                        }
                        
                    case 3: // D섹션 - 각 아이템별로 셀 생성
                        section.list?.forEach { item in
                            cellTypes.append(.sectionDItem(item))
                        }
                        
                    default: break
                    }
                }
                
                return cellTypes
            }
    }()
}
