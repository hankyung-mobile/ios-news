//
//  SearchLastTableViewCell.swift
//  newsApp
//
//  Created by jay on 8/18/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit

class SearchLastTableViewCell: UITableViewCell {

    @IBOutlet weak var lbDescription: UILabel!
    @IBOutlet weak var constantBottom: NSLayoutConstraint!
    @IBOutlet weak var constantTop: NSLayoutConstraint!
    @IBOutlet weak var heightOfLabel: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        lbDescription.numberOfLines = 0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
