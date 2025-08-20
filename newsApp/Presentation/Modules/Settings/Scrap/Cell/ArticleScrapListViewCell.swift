//
//  ArticleScrapListViewCell.swift
//  newsApp
//
//  Created by jay on 7/8/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit

protocol ArticleScrapCellDelegate: AnyObject {
    func cellDidToggleSelection(_ cell: ArticleScrapListViewCell)
}

class ArticleScrapListViewCell: UITableViewCell {
    @IBOutlet weak var svCheckbox: UIStackView!
    @IBOutlet weak var imgCheckbox: UIImageView!
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbScrapDate: UILabel!
    @IBOutlet weak var svScrapList: UIStackView!
    @IBOutlet weak var lbScrap: UILabel!
    @IBOutlet weak var lyDivider: UIView!
    
    weak var delegate: ArticleScrapCellDelegate?
    private var isScrapSelected: Bool = false
    private var scrapItem: ScrapItem?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private func setupUI() {
        // 초기 체크박스 이미지 설정
        imgCheckbox.image = UIImage(named: "unChecked")
        imgCheckbox.tintColor = .systemGray
        
        // ✅ 제스처 제거 - ViewController에서 처리
    }
    
    // ✅ 외부에서 호출할 수 있도록 public으로 변경
    func toggleSelection() {
        isScrapSelected.toggle()
        updateCheckbox()
    }
    
    private func updateCheckbox() {
        let imageName = isScrapSelected ? "checked" : "unChecked"
        let color: UIColor = isScrapSelected ? .systemBlue : .systemGray
        
        UIView.transition(with: imgCheckbox,
                         duration: 0.2,
                         options: .transitionCrossDissolve) {
            self.imgCheckbox.image = UIImage(named: imageName)
            self.imgCheckbox.tintColor = color
        }
    }
    
    // ✅ 메인 configure 메서드
    func configure(with item: ScrapItem, isEditMode: Bool = false, isScrapSelected: Bool = false) {
        self.scrapItem = item
        self.isScrapSelected = isScrapSelected
        
        // 기본 데이터 설정
        lbTitle.text = item.title
//        lbPubDate.text = item.pub_date
        lbScrapDate.text = item.scrap_date
        
        let fontSize = UIFont.preferredFont(forTextStyle: .caption1).pointSize
        let boldFont = UIFont.boldSystemFont(ofSize: fontSize)
        
        lbScrap.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: boldFont)
        lbScrap.adjustsFontForContentSizeCategory = true
        
        // 편집 모드 설정
        svCheckbox.isHidden = !isEditMode
        
        // 체크박스 상태 업데이트
        updateCheckbox()
    }
    
    // ✅ 현재 아이템과 선택 상태 반환
    func getCurrentItem() -> (ScrapItem?, Bool) {
        return (scrapItem, isScrapSelected)
    }
    
    // ✅ 편집 모드 설정 (애니메이션 포함)
    func setEditMode(_ isEditMode: Bool, isScrapSelected: Bool = false, animated: Bool = true) {
        self.isScrapSelected = isScrapSelected
        updateCheckbox()
        
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.svCheckbox.isHidden = !isEditMode
                self.svCheckbox.alpha = isEditMode ? 1.0 : 0.0
            }
        } else {
            svCheckbox.isHidden = !isEditMode
            svCheckbox.alpha = isEditMode ? 1.0 : 0.0
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isScrapSelected = false
        scrapItem = nil
        updateCheckbox()
    }
}
