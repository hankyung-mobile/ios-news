//
//  UIView+Extesions.swift
//  newsApp
//
//  Created by jay on 6/27/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

extension UIView {
    var rx_tap: Observable<UITapGestureRecognizer> {
        let tapGesture = UITapGestureRecognizer()
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
        return tapGesture.rx.event.asObservable()
    }
}
