//
//  StockSearchTableViewCell.swift
//  newsApp
//
//  Created by jay on 7/29/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit

class StockSearchTableViewCell: UITableViewCell {

    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbCode: UILabel!
    @IBOutlet weak var lbMarket: UILabel!
    
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
        
        // 기존 데이터 초기화
        lbTitle.text = nil
        lbCode.text = nil
        lbMarket.text = nil

    }
    
    func configure(with item: StockItem) {
        let subHeadSize = UIFont.preferredFont(forTextStyle: .subheadline).pointSize
        let boldFont = UIFont.boldSystemFont(ofSize: subHeadSize)
        
        lbCode.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: boldFont)
        
        lbTitle.text = item.name
        lbCode.text = item.code
        lbMarket.text = item.market
    }

}
