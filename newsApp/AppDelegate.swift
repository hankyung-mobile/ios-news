//
//  AppDelegate.swift
//  newsApp
//
//  Created by jay on 29/05/2025.
//  Copyright © 2019 hkcom. All rights reserved.
//

//
//  AppDelegate.swift
//  newsApp
//
//  Created by jay on 29/05/2025.
//  Copyright © 2019 hkcom. All rights reserved.
//

import UIKit
import CoreData
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import RxAlamofire
import RxSwift
import RxCocoa
import GoogleMobileAds


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let disposeBag = DisposeBag()
    private let userService = UserService.shared
    private var isLaunchedByPushNotification = false
    
    // 푸시 알림 중복 처리 방지 플래그
    private var isProcessingPushNotification = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //firebase 설정
        FirebaseApp.configure()
        
        //fcm 설정
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self
        
        if !UserDefaults.standard.bool(forKey: "isLaunched") {
            
            UserDefaults.standard.set(true, forKey: "isLaunched")
            UserDefaults.standard.set(appVersion, forKey: "appVersion")
            
        }
        else if UserDefaults.standard.value(forKey: "appVersion") as? String != appVersion {
            
            isFcmSubscribe = UserDefaults.standard.bool(forKey: IsNotificationKey.news.toString())

            UserDefaults.standard.set(appVersion, forKey: "appVersion")
        }

        application.registerForRemoteNotifications()
        
        
        //네트워크 연결 확인
        guard Reachability.isConnectedToNetwork() else {
            
//            self.window?.rootViewController = UIStoryboard.init(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()
//            let dialog = UIAlertController(title: "오류", message: "네트워크에 연결되지 않아 앱이 종료됩니다.", preferredStyle: .alert)
//            let action = UIAlertAction(title: "확인", style: UIAlertAction.Style.default, handler: { (action) in
//                DispatchQueue.main.async {
//                    UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                        exit(0)
//                    }
//                }
//            })
//            dialog.addAction(action)
//
//            DispatchQueue.main.async {
//                self.window?.rootViewController?.present(dialog, animated: true, completion: nil)
//            }
            return false
        }
    
        //마스터 데이터
        let masterInfo = masterDataDecode()
        loadMasterData()
        loadNewsData()
        loadMarketData()

        
        //저장 마스터 정보가 없는 상태에서 받은 마스터 정보가 없을 경우 에러 처리
//        if masterInfo.count < 5 {
//            
//            if UserDefaults.standard.value(forKey: "masterVersion") == nil {
//                
//                self.window?.rootViewController = UIStoryboard.init(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()
//                
//                let dialog = UIAlertController(title: "오류", message: "기본정보 호출에 실패하여 앱이 종료됩니다.", preferredStyle: .alert)
//                let action = UIAlertAction(title: "확인", style: UIAlertAction.Style.default, handler: { (action) in
//                    DispatchQueue.main.async {
//                        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                            exit(0)
//                        }
//                    }
//                })
//                dialog.addAction(action)
//
//                DispatchQueue.main.async {
//                    self.window?.rootViewController?.present(dialog, animated: true, completion: nil)
//                }
//                return true
//            }else {
//                return true
//            }
//        }
        
        
        //마스터정보 정상 수신
        UserDefaults.standard.set(masterInfo["masterVersion"] as! Int, forKey: "masterVersion")
        UserDefaults.standard.set(masterInfo, forKey: "masterInfo")
        
        //주요 URL 저장
        mainUrl = masterInfo["mainUrl"] as? String ?? mainUrl
        
        //강제업데이트 확인
        
        let forceVersion = masterInfo["forceVersion"] as! String
        let needUpdate = forceVersion.compare(appVersion, options: .numeric) == .orderedDescending
        
        
        if needUpdate {
            self.window?.rootViewController = UIStoryboard.init(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()
            
            let dialog = UIAlertController(title: "업데이트", message: "앱 업데이트 후 이용해 주세요.", preferredStyle: .alert)
            let action = UIAlertAction(title: "확인", style: UIAlertAction.Style.default, handler: { (action) in
                let url:URL = URL(string: appStoreUrl)!
                UIApplication.shared.open(url, options: [:], completionHandler: {(success) in exit(0)})
            })
            dialog.addAction(action)
            
            DispatchQueue.main.async {
                self.window?.rootViewController?.present(dialog, animated: true, completion: nil)
            }
            
            return true
            
        }
        
        // 푸시 알림으로 앱이 시작된 경우 (완전한 중복 방지)
        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            print("🔥 앱 시작시 푸시 알림 감지 - didReceive response 무시 설정")
            // 푸시 알림으로 앱 실행시 날짜 체크 건너뛰기
            isLaunchedByPushNotification = true
            // 푸시 알림 중복처리 방지 플래그
            isProcessingPushNotification = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.userNotificationArticle(userInfo: userInfo)
                // 3초 후에 플래그 해제 (didReceive response가 늦게 올 수도 있음)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.isProcessingPushNotification = false
                }
            }
        }
        
        MobileAds.shared.start(completionHandler: nil)
        
        // 광고 미리 로드
        AdMobManager.shared.loadAd()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
            Messaging.messaging().apnsToken = deviceToken
        }
        

        
        if isFcmSubscribe {
            Messaging.messaging().unsubscribe(fromTopic: TopicName.newsOld.toString())
            Messaging.messaging().subscribe(toTopic: TopicName.news.toString())
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {

    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void){
        
        completionHandler(.newData)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        var urlString: String = SITEURL
        
        if checkUrlPattern(url: url.absoluteString) == "www" {
            
            urlString = url.absoluteString
            
        }
        else if url.absoluteString.contains("hknews://newsview?url=") {
            
            urlString = url.absoluteString.replacingOccurrences(of: "hknews://newsview?url=", with: "")
            
        }
        else if url.absoluteString.contains("hknews://google/link?deep_link_id=") {
            
            urlString = url.valueOf("deep_link_id") ?? SITEURL
            
        }
        
        
        guard let tabbarViewControllers = UIApplication.shared.keyWindowCompat?.rootViewController as? UITabBarController else {
            
            pushArticleUrl = urlString
            
            return true
        }
        guard let currentViewController = tabbarViewControllers.selectedViewController else {return true}
        
        
        if !currentViewController.isKind(of: NewsContentController.classForCoder()) {
            tabbarViewControllers.selectedIndex = 0
        }
        
        guard let openURL = URL(string: urlString) else { return true }
        
        let newsDetailVC = NewsDetailViewController(url: openURL, title: nil)
        
        DispatchQueue.main.async {
            self.presentNewsDetailViewController(newsDetailVC, tabBarController: tabbarViewControllers)
        }
        
        return true
        
    }

    func applicationWillResignActive(_ application: UIApplication) {
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        //시간 저장
        applicationDidEnterBackgroundTime = Date()
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        
        //네트워크 연결 확인
        guard Reachability.isConnectedToNetwork() else { return }
        
        
//        let date = DateFormatter()
//        date.dateFormat = "yyyy-MM-dd"
//        
//        //앱 다시 시작 && 푸시 알림으로 시작된 경우 날짜 체크 건너뛰기
//        if !isLaunchedByPushNotification &&  date.string(from: applicationDidEnterBackgroundTime) != date.string(from: Date()) {
//            exit(0)
//        }
        
        // ✅ 3시간 체크 로직
          let threeHoursInSeconds: TimeInterval = 3 * 60 * 60  // 3시간 = 10800초
          let currentTime = Date()
          let timeDifference = currentTime.timeIntervalSince(applicationDidEnterBackgroundTime)
          
          // 디버깅용 로그
          let elapsedMinutes = Int(timeDifference / 60)
          let elapsedHours = elapsedMinutes / 60
          let remainingMinutes = elapsedMinutes % 60
          print("⏰ 백그라운드 경과 시간: \(elapsedHours)시간 \(remainingMinutes)분")
          
          // 앱 다시 시작 && 푸시 알림으로 시작된 경우 시간 체크 건너뛰기
          if !isLaunchedByPushNotification && timeDifference >= threeHoursInSeconds {
              print("🔄 3시간 경과 - 앱 재구동 (스플래시부터 시작)")
              
              // 로그인 상태, 캐시, 쿠키는 그대로 유지하고 앱만 재시작
              // UserDefaults, Keychain, 쿠키 등은 exit(0)해도 유지됨
              exit(0)
          }
        
        isLaunchedByPushNotification = false

        //선택된 탭 확인 - 30분 이상 백그라운드였을 때만 첫 번째 탭으로 이동
//        if (applicationDidEnterBackgroundTime + 60 * 30) < Date() {
//            guard let tabbarViewControllers = UIApplication.shared.keyWindowCompat?.rootViewController as? UITabBarController else { return }
//            tabbarViewControllers.selectedIndex = 0
//        }
        
//        guard let tabbarViewControllers = UIApplication.shared.keyWindowCompat?.rootViewController as? UITabBarController else { return }
//        guard let currentViewController = tabbarViewControllers.selectedViewController else {return}
//        
//        if currentViewController.restorationIdentifier == "settingNavigation"  {
//            if let snvc = currentViewController as? UINavigationController, let svc = snvc.topViewController as? SettingTableViewController {
//                svc.reloadPushStatusSection()
//            }
//        }
//        else if currentViewController.restorationIdentifier == "pushNavigation" {
//
//            if let pnvc = currentViewController as? UINavigationController, let pvc = pnvc.topViewController as? PushViewController {
//                DispatchQueue.main.async {
//                    pvc.getPushNewsListData()
//                }
//            }
//        }
 
    }

    func applicationDidBecomeActive(_ application: UIApplication) {

        guard let tabbarViewControllers = UIApplication.shared.keyWindowCompat?.rootViewController as? UITabBarController else { return }
        
        if UIApplication.shared.applicationIconBadgeNumber > 0 {
//            tabbarViewControllers.tabBar.items?[0].badgeValue = "1"
        }
        
        checkNetworkStatus()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "newsApp")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - 마스터 데이터 로드
    private func loadMasterData() {
        userService.masterData()
            .subscribe(
                onNext: { master in
                    
                    // 앱 전역에서 사용할 사용자 정보 저장
                    AppDataManager.shared.saveAppData(master)
        
                },
                onError: { error in
                    print("사용자 정보 로드 실패: \(error)")
                    if let masterData = AppDataManager.shared.getMasterData(), masterData.data?.externalUrls?.count ?? 0 > 0 {
                        AppDataManager.shared.saveAppData(masterData)
                    } else {
                        // 저장된 데이터 없을 시.
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    // MARK: - 뉴스 데이터 로드
    private func loadNewsData() {
        userService.newsData()
            .subscribe(
                onNext: { data in
                    
                    // 앱 전역에서 사용할 사용자 정보 저장
                    AppDataManager.shared.saveNewsData(data)
                    MenuFactory.preloadMenus()
                    
        
                },
                onError: { error in
                    print("사용자 정보 로드 실패: \(error)")
                    if let masterData = AppDataManager.shared.getNewsData(), masterData.data?.slide?.count ?? 0 > 0 {
                        AppDataManager.shared.saveNewsData(masterData)
                    } else {
//                       저장된 데이터 없을시
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    // MARK: - 마켓 데이터 로드
    private func loadMarketData() {
        userService.marketData()
            .subscribe(
                onNext: { data in
                    
                    // 앱 전역에서 사용할 사용자 정보 저장
                    AppDataManager.shared.saveMarketData(data)
        
                },
                onError: { error in
                    print("사용자 정보 로드 실패: \(error)")
                    if let masterData = AppDataManager.shared.getMarketData(), masterData.data?.slide?.count ?? 0 > 0 {
                        AppDataManager.shared.saveMarketData(masterData)
                    } else {
//                        let emptyData = Premium(
//                            code: "error",
//                            message: "데이터를 불러올 수 없습니다",
//                            data: PremiumData(slide: [], menu: [])
//                        )
//                        
//                        // 빈 데이터로 ViewModel 동작시키기
//                        AppDataManager.shared.saveMarketData(emptyData)
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
        
        guard let tabbarViewControllers = UIApplication.shared.keyWindowCompat?.rootViewController as? UITabBarController else { return }
        guard let currentViewController = tabbarViewControllers.selectedViewController else {return}

        
        if let pnvc = currentViewController as? UINavigationController, let pvc = pnvc.topViewController as? PushViewController {
            DispatchQueue.main.async {

                pvc.getPushNewsListData()
            }
        }
        else if UIApplication.shared.applicationIconBadgeNumber > 0 {
//            tabbarViewControllers.tabBar.items?[0].badgeValue = "1"
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // 이미 처리 중이면 무시 (앱 시작시 푸시로 인한 중복 방지)
        if isProcessingPushNotification {
            print("🚫 이미 앱 시작시 푸시 처리중 - didReceive response 무시")
            completionHandler()
            return
        }
        
        let userInfo = response.notification.request.content.userInfo
        
        print("📱 didReceive response 호출 - 일반 푸시 처리")
        isProcessingPushNotification = true
        
        // 0.8초 기다린 후 기존 방식으로 처리 (제스처 지원 유지)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.userNotificationArticle(userInfo: userInfo)
            self.isProcessingPushNotification = false
        }
        
        completionHandler()
    }
    
    func userNotificationArticle(userInfo: [AnyHashable : Any] ){
        
        print("📱 userNotificationArticle 호출됨")
        
        // 안전한 캐스팅으로 크래시 방지 (강제 캐스팅 제거)
        if let aid = userInfo["aid"] as? String, !aid.isEmpty {
            pushArticleUrl = userInfo["url"] as? String ?? ""
        }
        else {
            isArticlepushTouch = true
        }
        
        // TabBarController 찾기 (재시도 로직 추가)
        let tabbarViewControllers = findTabBarController()
        
        guard let tabBar = tabbarViewControllers else {
            print("⚠️ TabBarController not found, retrying after delay")
            // TabBar가 준비되지 않았으면 재시도 (최대 3번)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.userNotificationArticleWithRetry(userInfo: userInfo, retryCount: 1)
            }
            return
        }
        
        if let currentViewController = tabBar.selectedViewController {
            if pushArticleUrl.isEmpty {
                tabBar.selectedIndex = 2
                isArticlepushTouch = false
                return
            }
            
            if !currentViewController.isKind(of: NewsContentController.classForCoder()) {
                tabBar.selectedIndex = 0
            }
        } else {
            print("⚠️ No selected view controller in TabBar")
            
            if pushArticleUrl.isEmpty {
                tabBar.selectedIndex = 2
                isArticlepushTouch = false
                return
            }
            
            tabBar.selectedIndex = 0
        }
        
        isArticlepushTouch = false
        
        if pushArticleUrl.isEmpty {
            return
        }
        
        guard let url = URL(string: pushArticleUrl) else {
            print("❌ Invalid URL: \(pushArticleUrl)")
            pushArticleUrl = ""
            return
        }
        
        pushArticleUrl = ""
        
        print("🚀 NewsDetailViewController 생성 - URL: \(url)")
        let newsDetailVC = NewsDetailViewController(url: url, title: nil)
        
        DispatchQueue.main.async {
            self.presentNewsDetailViewController(newsDetailVC, tabBarController: tabBar)
        }
    }
    
    // 재시도 로직을 위한 헬퍼 함수
    private func userNotificationArticleWithRetry(userInfo: [AnyHashable: Any], retryCount: Int) {
        guard retryCount < 3 else {
            print("❌ TabBarController not ready after 3 retries")
            return
        }
        
        guard findTabBarController() != nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.userNotificationArticleWithRetry(userInfo: userInfo, retryCount: retryCount + 1)
            }
            return
        }
        
        userNotificationArticle(userInfo: userInfo)
    }

    // MARK: - 통합된 헬퍼 메서드들 (iOS 14.0+)

    /// Scene에서 첫 번째 window 찾기 (공통 로직)
    private func getFirstWindow() -> UIWindow? {
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                // key window 우선, 없으면 첫 번째 window
                return windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first
            }
        }
        
        // AppDelegate fallback
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            return appDelegate.window
        }
        
        return nil
    }

    /// TabBarController 찾기
    private func findTabBarController() -> UITabBarController? {
        guard let window = getFirstWindow() else { return nil }
        return window.rootViewController as? UITabBarController
    }

    /// 최상위 뷰컨트롤러 찾기
    private func getTopMostViewController() -> UIViewController? {
        guard let window = getFirstWindow() else { return nil }
        return getTopViewController(from: window.rootViewController)
    }

    /// 재귀적으로 최상위 뷰컨트롤러 찾기
    private func getTopViewController(from viewController: UIViewController?) -> UIViewController? {
        guard let viewController = viewController else { return nil }
        
        if let presented = viewController.presentedViewController {
            return getTopViewController(from: presented)
        }
        
        if let navigationController = viewController as? UINavigationController {
            return getTopViewController(from: navigationController.visibleViewController)
        }
        
        if let tabBarController = viewController as? UITabBarController {
            return getTopViewController(from: tabBarController.selectedViewController)
        }
        
        return viewController
    }

    // MARK: - NewsDetailViewController 표시

    private func presentNewsDetailViewController(_ newsDetailVC: NewsDetailViewController, tabBarController: UITabBarController?) {
        
        // 방법 1: Navigation Push (제스처 뒤로가기 자동 지원)
        if let tabBar = tabBarController,
           let navigationController = tabBar.selectedViewController as? UINavigationController {
            
            // WebNavigationDelegate 설정 (연쇄 뉴스 열기 지원)
            if let topViewController = navigationController.topViewController as? WebNavigationDelegate {
                newsDetailVC.webNavigationDelegate = topViewController
            }
            
            navigationController.pushViewController(newsDetailVC, animated: true)
            return
        }
        
        // 방법 2 & 3: Modal 표시 - NavigationController로 감싸서 제스처 지원
        let navController = UINavigationController(rootViewController: newsDetailVC)
        
        // Modal로 열 때도 WebNavigationDelegate 설정
        if let tabBar = tabBarController,
           let currentNavController = tabBar.selectedViewController as? UINavigationController,
           let topViewController = currentNavController.topViewController as? WebNavigationDelegate {
            newsDetailVC.webNavigationDelegate = topViewController
        } else if let topMostVC = getTopMostViewController() as? WebNavigationDelegate {
            newsDetailVC.webNavigationDelegate = topMostVC
        }
        
        let presenter = tabBarController ?? getTopMostViewController()
        presenter?.presentFullScreen(navController, animated: false)
    }
    
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        
        guard let fcmToken = fcmToken, !fcmToken.isEmpty else {
            return
        }
        
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        UserDefaults.standard.set(fcmToken, forKey: "FCMToken")
        let userInfo = getUserIdAndUserNo()
        let userId = userInfo.userId
        let userNo = userInfo.userNo
        let isOn = getThatAsYN(for: IsNotificationKey.news.toString())
        
        var parameters: [String: String] = [
            "fcmtoken": fcmToken,
            "project": "hknews",
            "info": "iOS/\(appVersion)",
            "ison": isOn
        ]

        // 로그인 했을 경우 userId, usernumber 추가
        if UserDefaults.standard.bool(forKey: "_ISLOGIN") {
            parameters["userid"] = userId
            parameters["usernumber"] = userNo
        }
        
        let request = sendFormDataRequest(
            url: "https://mms.hankyung.com/api/fcmtokenupdate",
            dic: parameters,
            header: ["authkey":hkAuthkey],
        )
        sendData(request: request)
    }
}
