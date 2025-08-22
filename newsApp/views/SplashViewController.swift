//
//  SplashViewController.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//
 
import Foundation
import UIKit
import Firebase
import FirebaseMessaging
 
class SplashViewController: UIViewController {
    
    @IBOutlet weak var imgLogo: UIImageView!
    @IBOutlet weak var lbTime: UILabel!
    
    var check = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showLocalTime()
        animateLogo {
            
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                if settings.authorizationStatus == .notDetermined {
                    
                    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                    
                    UNUserNotificationCenter.current().requestAuthorization(options: authOptions){ (granted, error) in
                        
                        if granted {
                            UserDefaults.standard.set(true, forKey: IsNotificationKey.news.toString())
                            Messaging.messaging().subscribe(toTopic: TopicName.news.toString())
                        }
                        else {
                            UserDefaults.standard.set(false, forKey: IsNotificationKey.news.toString())
                        }
                        self.check += 1
                        self.changeRootView()
                    }
                }
                else {
                    self.check += 1
                    self.changeRootView()
                }
            }
            
            //        guard UserDefaults.standard.bool(forKey: "_ISLOGIN") else {
            //            DispatchQueue.main.async {
            //                deleteLoginData()
            //            }
            //            self.check += 1
            //            self.changeRootView()
            //            return
            //        }
            
            if UserDefaults.standard.string(forKey: "_LOGINID") != nil {
                UserDefaults.standard.removeObject(forKey: "_LOGINID")
                UserDefaults.standard.removeObject(forKey: "_LOGINPWD")
                UserDefaults.standard.removeObject(forKey: "_SSOTOKEN")
            }
            
            
//            guard UserDefaults.standard.string(forKey: "ssoToken") != nil else {
//                DispatchQueue.main.async {
//                    deleteLoginData()
//                }
//                self.check += 1
//                self.changeRootView()
//                return
//            }
            
            
            
            guard let accountCheckUrl = returnAccountURL("check") else {
//                DispatchQueue.main.async {
//                    deleteLoginData()
//                }
                self.check += 1
                self.changeRootView()
                
                return
            }
            
            
            let parameter = returnAccountParameter("check")
            
            requestJsonData(url: accountCheckUrl, method: "POST", parameter: parameter, completion: { (data) in
                
                let returnCode = data["return_code"] as? String
                // 로그인 확인
                if returnCode == "0000" {
                    
                    if var accountdata: Dictionary = UserDefaults.standard.dictionary(forKey: "_ACCOUNTDATA") {
                        // 로그인 유지
                        if data["_hk_token"] != nil {
                            accountdata["_hk_token"] = data["_hk_token"]
                        }
                        
                        // 로그인 처리
                        DispatchQueue.main.async {
                            saveLoginData(data: accountdata)
                        }
                    }
                } else if let code = returnCode, !code.isEmpty {
                    // 서버가 명시적으로 실패 코드를 보낸 경우만 로그아웃
                    print("❌ 서버에서 로그인 실패 응답: \(code)")
                    
                    DispatchQueue.main.async {
                        deleteLoginData()
                    }
                    
                } else {
                    // return_code가 없거나 null인 경우 - 네트워크/서버 문제로 간주하고 로그인 유지
                    print("⚠️ 서버 응답 오류 (네트워크/서버 문제) - 로그인 상태 유지")
                    // 로그아웃하지 않음
                }
                
                self.check += 1
                self.changeRootView()
                return
                
            })
            
        }
    }

    func animateLogo(completion: @escaping () -> Void) {
        imgLogo.transform = CGAffineTransform(translationX: 0, y: 30)
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       options: [.curveEaseOut],
                       animations: {
            self.imgLogo.transform = CGAffineTransform(translationX: 0, y: 0)
        }, completion: { _ in
            // 애니메이션 완료 후 2초 대기 후 completion 실행
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completion()
            }
        })
    }

    func showLocalTime() {
        lbTime.text = formatDate(Date())
    }

    func fetchServerTime() {
        let url = URL(string: "https://worldtimeapi.org/api/timezone/Asia/Seoul")!
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let datetime = json["datetime"] as? String else { return }

            let formatter = ISO8601DateFormatter()
            if let serverDate = formatter.date(from: datetime) {
                DispatchQueue.main.async {
                    self.lbTime.text = self.formatDate(serverDate)
                }
            }
        }
        task.resume()
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter.string(from: date)
    }


    func changeRootView() {
        guard self.check == 2 else {return}
        
        DispatchQueue.main.async {
            
            if #available(iOS 13.0, *) {
                let tabbarController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabBarController") as! TabBarController
                
//                if isArticlepushTouch && pushArticleUrl.isEmpty {
//                    isArticlepushTouch = false
//                    tabbarController.selectedIndex = 2
//                }
//                let homeNav = UINavigationController(rootViewController: tabbarController)
                UIApplication.shared.windows.first?.rootViewController = tabbarController
                
                // 첫 실행 체크 및 도움말 뷰 표시
                self.checkAndShowTutorial(on: tabbarController)
                
            } else {
                let tabbarController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabBarController") as! TabBarController
                
                if isArticlepushTouch && pushArticleUrl.isEmpty {
                    isArticlepushTouch = false
                    tabbarController.selectedIndex = 2
                }
                UIApplication.shared.windows.first?.rootViewController = tabbarController
                
                // 첫 실행 체크 및 도움말 뷰 표시
                self.checkAndShowTutorial(on: tabbarController)
            }
            UIApplication.shared.windows.first?.makeKeyAndVisible()
        }
    }

    func checkAndShowTutorial(on viewController: UIViewController) {
        let hasShownTutorial = UserDefaults.standard.bool(forKey: "hasShownTutorial")
        
        if !hasShownTutorial {
            // 약간의 딜레이를 주어 메인 뷰가 완전히 로드된 후 실행
            DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
                self.showTutorialView(on: viewController)
            }
        }
    }

    func showTutorialView(on viewController: UIViewController) {
        // Storyboard에서 도움말 뷰컨트롤러 생성
        guard let tutorialVC = UIStoryboard(name: "Usage", bundle: nil).instantiateViewController(withIdentifier: "UsageViewController") as? UsageViewController else {
            return
        }
        
        // 모달로 표시
        tutorialVC.modalPresentationStyle = .fullScreen
        tutorialVC.modalTransitionStyle = .crossDissolve
        
        viewController.present(tutorialVC, animated: true) {
            // 도움말이 표시되면 플래그 저장
            UserDefaults.standard.set(true, forKey: "hasShownTutorial")
        }
    }
    
    
}


