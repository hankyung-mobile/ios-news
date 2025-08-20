//
//  TermSearchTableViewCell.swift
//  newsApp
//
//  Created by jay on 7/29/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit

class TermSearchTableViewCell: UITableViewCell {

    @IBOutlet weak var lbSubTitle: UILabel!
    @IBOutlet weak var lbTitle: UILabel!
    
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
        lbSubTitle.text = nil

    }
    
    func configure(with item: TermItem) {
        lbTitle.text = item.word ?? ""
        lbSubTitle.text = item.content ?? ""
    }

}
