//
//  MarketIndexViewController.swift
//  newsApp
//
//  Created by hkcom on 2020/09/01.
//  Copyright © 2020 hkcom. All rights reserved.
//

import UIKit



class MarketIndexViewController: UIViewController {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var pageViewController: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var segmentedView: UIView!
    @IBOutlet weak var separatorView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        marketIndexViewController = self

        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        
        
//        self.activityIndicator.startAnimating()
        
//        if #available(iOS 15.0, *) {
//            return
//        }
        
        guard #available(iOS 15.0, *) else {
            self.segmentedView.backgroundColor = UIColor(named: "NavigationDefaultColor")
            return
        }

        
//        self.segmentedControlView.layer.shadowColor = UIColor.black.cgColor
//        self.segmentedControlView.layer.shadowOffset = CGSize(width: 1, height: 1)
//        self.segmentedControlView.layer.shadowRadius = 3
//        self.segmentedControlView.layer.shadowOpacity = 0.8
        
        
    }
    
    
//    @IBAction func sementedControlChanged(_ sender: UISegmentedControl) {
//        guard let mipvc = children[0] as? MarketIndexPageViewController else {
//            return
//        }
//
//        mipvc.setPageView(index: sender.selectedSegmentIndex)
//    }
    
    
    func activityIndicatorStopAnimation() {
        self.activityIndicator.stopAnimating()
    }

    
}
