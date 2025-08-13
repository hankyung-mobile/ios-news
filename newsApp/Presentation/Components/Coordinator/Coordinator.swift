//
//  Coordinator.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import UIKit

// 기본 코디네이터 프로토콜
protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get }
    
    func start()
    func childDidFinish(_ child: Coordinator?)
}

// 기본 구현
extension Coordinator {
    func childDidFinish(_ child: Coordinator?) {
        if let child = child,
           let index = childCoordinators.firstIndex(where: { $0 === child }) {
            childCoordinators.remove(at: index)
            print("👋 Child coordinator removed: \(type(of: child))")
        }
    }
    
    func showAlert(title: String?, message: String?, on viewController: UIViewController, actions: [UIAlertAction] = []) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if actions.isEmpty {
            alertController.addAction(UIAlertAction(title: "확인", style: .default))
        } else {
            for action in actions {
                alertController.addAction(action)
            }
        }
        
        viewController.present(alertController, animated: true)
    }
}
