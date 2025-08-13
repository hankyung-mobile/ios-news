//
//  HaederTableViewCell.swift
//  newsApp
//
//  Created by jay on 6/27/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit

class HeaderTableViewCell: UITableViewCell {

    @IBOutlet weak var svTitleName: UIStackView!
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var topOfDivider: UIView!
    @IBOutlet weak var botOfDivider: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 셀 재사용 시 초기화
        lbName.text = nil
        // 다른 UI 요소들도 초기화
    }
    
    func configure(with title: String?, type: MenuType) {
        if type == .NEWS {
            botOfDivider.isHidden = true
        }
        
        if type == .MARKET {
            topOfDivider.isHidden = true
        }
        
        let footnoteSize = UIFont.preferredFont(forTextStyle: .footnote).pointSize
           let boldFont = UIFont.boldSystemFont(ofSize: footnoteSize)
        
        lbName.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: boldFont)
        lbName.adjustsFontForContentSizeCategory = true
        
        if let name = title, name != "" {
            svTitleName.isHidden = false
            lbName?.text = name
        } else {
            svTitleName.isHidden = true
        }

    }

}
