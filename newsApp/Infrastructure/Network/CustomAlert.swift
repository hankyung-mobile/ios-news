//
//  CustomAlert.swift
//  newsApp
//
//  Created by jay on 8/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit

class CustomAlert {
   static let shared = CustomAlert()
   private var currentAlert: UIView?
   
   func showNetworkError() {
       show(message: "인터넷 연결이 없습니다. 인터넷에 연결해주세요.")
   }
   
   func show(message: String) {
       DispatchQueue.main.async { [weak self] in
           // 이미 얼럿이 떠있으면 return
           if self?.currentAlert != nil {
               return
           }
           self?.createAlert(message: message)
       }
   }
   
   private func createAlert(message: String) {
       // iOS 15+ 호환 윈도우 접근
       var window: UIWindow?
       
       if #available(iOS 15.0, *) {
           guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
           window = windowScene.windows.first(where: { $0.isKeyWindow })
       } else {
           window = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
       }
       
       guard let keyWindow = window else { return }
       
       let alertView = UIView()
       alertView.backgroundColor = .black
       alertView.layer.cornerRadius = 12
       alertView.translatesAutoresizingMaskIntoConstraints = false
       
       let label = UILabel()
       label.text = message
       label.textColor = .white
       label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
       label.textAlignment = .center
       label.numberOfLines = 1
       label.translatesAutoresizingMaskIntoConstraints = false
       
       keyWindow.addSubview(alertView)
       alertView.addSubview(label)
       
       let tabBarHeight: CGFloat = 83
       
       NSLayoutConstraint.activate([
           alertView.leadingAnchor.constraint(equalTo: keyWindow.leadingAnchor, constant: 20),
           alertView.trailingAnchor.constraint(equalTo: keyWindow.trailingAnchor, constant: -20),
           alertView.bottomAnchor.constraint(equalTo: keyWindow.bottomAnchor, constant: -(tabBarHeight + 20)),
           
           label.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 16),
           label.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -16),
           label.topAnchor.constraint(equalTo: alertView.topAnchor, constant: 16),
           label.bottomAnchor.constraint(equalTo: alertView.bottomAnchor, constant: -16)
       ])
       
       alertView.transform = CGAffineTransform(translationX: 0, y: 100)
       alertView.alpha = 0
       
       UIView.animate(withDuration: 0.3) {
           alertView.transform = .identity
           alertView.alpha = 1
       }
       
       currentAlert = alertView
       
       DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
           self?.hideAlert()
       }
   }
   
   @objc func hideAlert() {
       guard let alertView = currentAlert else { return }
       
       UIView.animate(withDuration: 0.2) {
           alertView.transform = CGAffineTransform(translationX: 0, y: 100)
           alertView.alpha = 0
       } completion: { [weak self] _ in
           alertView.removeFromSuperview()
           self?.currentAlert = nil
       }
   }
}
