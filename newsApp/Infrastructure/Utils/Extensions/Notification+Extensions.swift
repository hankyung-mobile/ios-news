//
//  Notification+Extensions.swift
//  newsApp
//
//  Created by jay on 6/4/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let loginSuccess = Notification.Name("LoginSuccessNotification")
    static let logoutSuccess = Notification.Name("LogoutSuccessNotification")
    static let moveToNewsPage = Notification.Name("moveToNewsPage")
    static let moveToPremiumPage = Notification.Name("moveToPremiumPage")
    static let moveToMarketPage = Notification.Name("moveToMarketPage")
    static let reporterDeleted = Notification.Name("reporterDeleted")
    static let closeSearchView = Notification.Name("closeSearchView")
    static let scrollToTop = Notification.Name("scrollToTop")
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}
