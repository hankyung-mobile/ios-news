//
//  HkMediaGroupControllerTableViewCell.swift
//  newsApp
//
//  Created by jay on 7/31/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit

class HkMediaGroupControllerTableViewCell: UITableViewCell {

    @IBOutlet weak var lb: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(with item: HKMediaItem, isLastCell: Bool = false) {
        lb?.text = item.title ?? "제목 없음"
    }

}
