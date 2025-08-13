//
//  MenuTableViewCell.swift
//  newsApp
//
//  Created by jay on 6/26/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit

class MenuTableViewCell: UITableViewCell {
    
    @IBOutlet weak var lb: UILabel!
    @IBOutlet weak var divider: UIView!
    @IBOutlet weak var gapView: UIView!
    @IBOutlet weak var imgExternal: UIImageView!
    @IBOutlet weak var svSub: UIStackView!
    @IBOutlet weak var lbSub: UILabel!
    @IBOutlet weak var lyFirstCellGap: UIView!
    @IBOutlet weak var lyLastCellGap: UIView!
    @IBOutlet weak var heightOfLyFirstCellGap: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func configure(with item: NewsMenuItem, isLastCell: Bool = false) {
        lb?.text = item.title ?? "제목 없음"
        imgExternal.isHidden = !(item.browser == "EXT")
        divider.isHidden = isLastCell
        gapView.isHidden = isLastCell
        
        if let subtitle = item.subtitle, !subtitle.isEmpty {
            svSub.isHidden = false
            lyFirstCellGap.isHidden = false
            lbSub.text = subtitle
        } else {
            svSub.isHidden = true
            lyFirstCellGap.isHidden = true
        }
    }
    
    func configure(with item: PremiumMenuItem, isLastCell: Bool = false) {
        lb?.text = item.title ?? "제목 없음"
        imgExternal.isHidden = !(item.browser == "EXT")
        divider.isHidden = isLastCell
    }
    
    func configure(with item: MarketMenuItem, isLastCell: Bool = false) {
        lb?.text = item.title ?? "제목 없음"
        imgExternal.isHidden = !(item.browser == "EXT")
        divider.isHidden = isLastCell
        gapView.isHidden = isLastCell
    }
}
