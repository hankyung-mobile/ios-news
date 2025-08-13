//
//  SearchCollectionViewCell.swift
//  newsApp
//
//  Created by jay on 7/25/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit

class SearchCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var svType: UIStackView!
    
    // MARK: - Properties
    override var isSelected: Bool {
        didSet {
            updateSelectionState()
        }
    }
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 셀 재사용 시 초기화
        
        
        lbName.text = nil
    }
    
    // MARK: - Setup
    private func setupUI() {
        // 셀 기본 스타일 설정
//        layer.cornerRadius = 8
//        layer.masksToBounds = true
//        backgroundColor = UIColor.systemBackground
//
//        // 선택 효과를 위한 설정
//        layer.borderWidth = 2
//        layer.borderColor = UIColor.clear.cgColor

    }
    
    // MARK: - Configuration
    func configure(with item: SearchItem) {
        lbName.text = item.title
    }
    
    // MARK: - Selection State
    private func updateSelectionState() {
        UIView.animate(withDuration: 0.2) {
            if self.isSelected {
                self.svType.backgroundColor = UIColor(named: "#1A1A1A")
                self.lbName.textColor = UIColor(named: "#F8F8F8")
            } else {
                self.svType.backgroundColor = UIColor(named: "#F2F2F2")
                self.lbName.textColor = UIColor(named: "#212121")
            }
        }
    }
    
    
}
