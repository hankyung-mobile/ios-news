//
//  FullAdViewController.swift
//  newsApp
//
//  Created by hkcom on 02/06/2020.
//  Copyright © 2020 hkcom. All rights reserved.
//

import Foundation
import UIKit


class FullAdViewController: UIViewController {
    
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var checkButton: UIButton!
    
    var banner: AdnextDynamicAdView!
    var isStop = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.9)

        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        bannerViewLaout()
        self.baseView.addSubview(self.banner)
    }
    
    
    @IBAction func closeAction(_ sender: Any) {
        if (isStop) {
            let date = DateFormatter()
            date.dateFormat = "yyyy-MM-dd"
            UserDefaults.standard.set(date.string(from: Date()), forKey: "isMainFullAdStopDay")
        }
        self.presentingViewController?.dismiss(animated: true)
    }
    
    @objc func appMovedToBackground() {
        self.presentingViewController?.dismiss(animated: false)
    }
    
    
    @IBAction func stopButtonAction(_ sender: Any) {
        
        if self.isStop {

            self.isStop = false
            let image = UIImage(named: "ad_check.png")
            checkButton.setImage(image, for: .normal)
        }
        else {
            self.isStop = true
            let image = UIImage(named: "ad_checked.png")
            checkButton.setImage(image, for: .normal)
        }

    }
    
    
    func bannerViewLaout() {
        self.banner.frame = CGRect(x: 0, y: 0, width: self.baseView.frame.size.width, height: self.baseView.frame.size.height)
        self.banner.layer.frame = CGRect(x: 0, y: 0, width: self.baseView.frame.size.width, height: self.baseView.frame.size.height)
        self.banner.backgroundColor = UIColor.clear
    }
}
