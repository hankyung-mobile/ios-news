//
//  String+Extensions.swift
//  newsApp
//
//  Created by jay on 7/7/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

extension String {
    var urlDecoded: String {
        return self.removingPercentEncoding ?? self
    }
}
