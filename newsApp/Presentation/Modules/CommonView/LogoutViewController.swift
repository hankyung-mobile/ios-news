//
//  LogoutViewController.swift
//  newsApp
//
//  Created by hkcom on 2022/06/28.
//  Copyright © 2022 hkcom. All rights reserved.
//

import UIKit

class LogoutViewController: UIViewController {
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicator.startAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        deleteLoginData()
        
        let accountLogoutURL = returnAccountURL("logout")!
        let parameter = returnAccountParameter("logout")
        
        requestSet(url: accountLogoutURL, method: "POST", parameter: parameter)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            newsViewController.goMainUrl = SITEURL
//            newsViewController.reload()

            if
                tabBarViewController?.selectedIndex == 1,
                let nvc = tabBarViewController?.selectedViewController as? UINavigationController,
                let stvc = nvc.topViewController as? SettingTableViewController
            {
                stvc.reloadLoginCell()
            }
            self.presentingViewController?.view.showToast("로그아웃 되었습니다.", withDuration: 1.5, delay: 1.0)
            self.presentingViewController?.dismiss(animated: false)
        }
    }
}
