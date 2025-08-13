//
//  SettingsViewController.swift
//  newsApp
//
//  Created by jay on 6/16/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var divider: UIView!
    @IBOutlet weak var svLogin: UIStackView!
    @IBOutlet weak var svLogout: UIStackView!
    @IBOutlet weak var svLoginInfo: UIStackView!
    @IBOutlet weak var svScrap: UIStackView!
    @IBOutlet weak var svMyStock: UIStackView!
    @IBOutlet weak var svManagerNoti: UIStackView!
    @IBOutlet weak var svReporters: UIStackView!
    @IBOutlet weak var svNewsLetter: UIStackView!
    @IBOutlet weak var svHKMediaGroup: UIStackView!
    @IBOutlet weak var svFont: UIStackView!
    @IBOutlet weak var lyAuthorizedNoti: UIView!
    @IBOutlet weak var lyLogin: UIView!
    @IBOutlet weak var lyLoginInfo: UIView!
    @IBOutlet weak var lyLogout: UIView!
    @IBOutlet weak var lyManagerNoti: UIView!
    @IBOutlet weak var imgLoginType: UIImageView!
    @IBOutlet weak var lbUserId: UILabel!
    @IBOutlet weak var btnBell: UIButton!
    
    @IBOutlet weak var lbInfoNotification: UILabel!
    @IBOutlet weak var lbInfoFont: UILabel!
    @IBOutlet weak var lbNonMember: UILabel!
    @IBOutlet weak var lbVersion: UILabel!
    @IBOutlet weak var btnSwitch: UISwitch!
    
    @IBOutlet weak var svUsage: UIStackView!
    @IBOutlet weak var svPolicy: UIStackView!
    @IBOutlet weak var svHelpDesk: UIStackView!
    @IBOutlet weak var lbPersonal: UILabel!
    
    private let disposeBag = DisposeBag()
    
    private let viewModel = PushListViewModel()
    
    // 뉴스 네비게이션 델리게이트 추가
    weak var webNavigationDelegate: WebNavigationDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        observeLoginState()
        setupButtonEvents()
        setupNotificationObserver()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkNotificationStatus()
        viewModel.loadFirstPage(with: ["" : ""])
    }
    
    private func setupButtonEvents() {
        
        svLogin.rx_tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                
                self?.showLoginView()
                return
                
            })
            .disposed(by: disposeBag)
        
        svLogout.rx_tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                
                let alert = UIAlertController(title: nil, message: "로그아웃 하시겠습니까?", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "확인", style: .default, handler : {(action) in
                    
                    guard let logoutView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LogoutViewController") as? LogoutViewController else { return }
                    self?.present(logoutView, animated: false)
                    
                })
                let cancel = UIAlertAction(title: "취소", style: .cancel, handler : nil)
                alert.addAction(cancel)
                alert.addAction(okAction)
                self?.present(alert, animated: true, completion: nil)
                
            })
            .disposed(by: disposeBag)
        
        svLoginInfo.rx_tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                
                guard let accountView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AccountViewController") as? AccountViewController else { return }
                
                accountView.accountViewType = "accountInfo"
                
                accountView.modalTransitionStyle = UIModalTransitionStyle.coverVertical
                self?.present(accountView, animated: true, completion: nil)
                
            })
            .disposed(by: disposeBag)
        
        svScrap.rx_tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                
                if !(self?.isLoggedIn() ?? false) {
                    self?.showLoginView()
                    return
                }
                
                let storyboard = UIStoryboard(name: "ArticleScrap", bundle: nil)
                let scrapListVC = storyboard.instantiateViewController(withIdentifier: "ArticleScrapViewController") as! ArticleScrapViewController
                
                // 받은 데이터로 파라미터 전달
                scrapListVC.parameters = getUserTokensParams()
                scrapListVC.webNavigationDelegate = self
                
                //                // 벋은 데이터로 타이틀 전달
                //                sectionListVC.viewTitle = sectionName
                
                self?.navigationController?.pushViewController(scrapListVC, animated: true)
                
            })
            .disposed(by: disposeBag)
        
        svMyStock.rx_tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                
                if !(self?.isLoggedIn() ?? false) {
                    self?.showLoginView()
                    return
                }
                let validURL = URL(string: "https://markets-dev.hankyung.com/hkapp/my-stock")
                self?.openNewsDetail(url: validURL!, title: "마이증권")
                
            })
            .disposed(by: disposeBag)
        
        svManagerNoti.rx_tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                
                if let appSettings = URL(string: UIApplication.openSettingsURLString){
                    UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                }
                
            })
            .disposed(by: disposeBag)
        
        svReporters.rx_tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                
                if !(self?.isLoggedIn() ?? false) {
                    self?.showLoginView()
                    return
                }
                
                let storyboard = UIStoryboard(name: "Reporters", bundle: nil)
                let reportersVC = storyboard.instantiateViewController(withIdentifier: "ReportersViewController") as! ReportersViewController
                
                // 받은 데이터로 파라미터 전달
                reportersVC.parameters = getUserTokensParams()
                reportersVC.webNavigationDelegate = self
                
                //                // 벋은 데이터로 타이틀 전달
                //                sectionListVC.viewTitle = sectionName
                
                self?.navigationController?.pushViewController(reportersVC, animated: true)
                
            })
            .disposed(by: disposeBag)
        
        svUsage.rx_tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                
                let internalBrowserVC = InternalBrowserViewController(url: URL(string: "https://stg-webview.hankyung.com/help/policy")!)
                let navigationController = UINavigationController(rootViewController: internalBrowserVC)
                navigationController.modalPresentationStyle = .formSheet
                self?.present(navigationController, animated: true)
                
            })
            .disposed(by: disposeBag)
        
        svPolicy.rx_tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                
                let internalBrowserVC = InternalBrowserViewController(url: URL(string: "https://stg-webview.hankyung.com/help/privacy")!)
                let navigationController = UINavigationController(rootViewController: internalBrowserVC)
                navigationController.modalPresentationStyle = .formSheet
                self?.present(navigationController, animated: true)
                
            })
            .disposed(by: disposeBag)
        
        svHelpDesk.rx_tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                
                let internalBrowserVC = InternalBrowserViewController(url: URL(string: "https://stg-webview.hankyung.com/help")!)
                let navigationController = UINavigationController(rootViewController: internalBrowserVC)
                navigationController.modalPresentationStyle = .formSheet
                self?.present(navigationController, animated: true)
                
            })
            .disposed(by: disposeBag)
        
        svNewsLetter.rx_tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                
                self?.openNewsDetail(url: URL(string: "https://stg-webview.hankyung.com/newsletter")!, title: "뉴스레터")
                
            })
            .disposed(by: disposeBag)
        
        btnBell.rx_tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                
                let storyboard = UIStoryboard(name: "PushList", bundle: nil)
                let pushVC = storyboard.instantiateViewController(withIdentifier: "PushListController") as! PushListController
                
                // 받은 데이터로 파라미터 전달
                pushVC.webNavigationDelegate = self
                
                //                // 벋은 데이터로 타이틀 전달
                //                sectionListVC.viewTitle = sectionName
                
                self?.navigationController?.pushViewController(pushVC, animated: true)
                
            })
            .disposed(by: disposeBag)
        
        svHKMediaGroup.rx_tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                
                let storyboard = UIStoryboard(name: "HkMediaGroup", bundle: nil)
                let pushVC = storyboard.instantiateViewController(withIdentifier: "HkMediaGroupController") as! HkMediaGroupController
                
                // 받은 데이터로 파라미터 전달
                pushVC.webNavigationDelegate = self
                
                //                // 벋은 데이터로 타이틀 전달
                //                sectionListVC.viewTitle = sectionName
                
                self?.navigationController?.pushViewController(pushVC, animated: true)
                
            })
            .disposed(by: disposeBag)
        
        svFont.rx_tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                
                // 안전한 방식
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            })
            .disposed(by: disposeBag)
  
    }
    
    private func bindViewModel() {
        // 아이템 리스트 바인딩 (articles → items로 변경)
        Observable.combineLatest(
              viewModel.items,
              viewModel.isLoadingRelay
          )
            .skip(1)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] items, isLoading in
                
                if !isLoading {
                    guard let firstItem = items.first,
                          let itemsReservedTime = firstItem.reservedtime else {
                        print("items의 첫 번째 아이템 또는 reservedTime이 없습니다")
                        return
                    }
                    
                    guard let pushDataItems = AppDataManager.shared.getPushData(),
                          let firstPushItem = pushDataItems.first,
                          let pushDataReservedTime = firstPushItem.reservedtime else {
                        print("pushData의 첫 번째 아이템 또는 reservedTime이 없습니다")
                        self?.btnBell.setImage(UIImage(named: "iconNewNoti"), for: .normal)
                        return
                    }
                    
                    // 두 값 비교
                    if itemsReservedTime == pushDataReservedTime {
                        print("reservedTime이 같습니다: \(itemsReservedTime)")
                        self?.btnBell.setImage(UIImage(named: "iconNoti"), for: .normal)
                        // 같을 때 로직
                    } else {
                        print("reservedTime이 다릅니다. items: \(itemsReservedTime), pushData: \(pushDataReservedTime)")
                        self?.btnBell.setImage(UIImage(named: "iconNewNoti"), for: .normal)
                        // 다를 때 로직
                    }
                }
            })
            .disposed(by: disposeBag)
        
        // 에러 바인딩
        viewModel.errorRelay
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in

            })
            .disposed(by: disposeBag)
    }
    
    private func observeLoginState() {
        // 초기값 설정
        setupViews(isLogin: self.isLoggedIn())
        updateLoginTypeImage()
        updateUserId()
        
        // UserDefaults 변경 감지
        NotificationCenter.default.rx
            .notification(UserDefaults.didChangeNotification)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in

                let accountData = UserDefaults.standard.object(forKey: "_ACCOUNTDATA")
                
                self?.setupViews(isLogin: self?.isLoggedIn() ?? false)
                self?.updateLoginTypeImage()
                self?.updateUserId()
            })
            .disposed(by: disposeBag)
    }
    
    private func setupViews(isLogin: Bool) {
        
        if isLogin {
            // 로그인 상태: svLogin 숨기고 svLogout 보이기
            lyLogin.isHidden = true
            lyLoginInfo.isHidden = false
            lyLogout.isHidden = false
            lbPersonal.text = "개인 맞춤형 서비스"
        } else {
            // 비로그인 상태: svLogin 보이고 svLogout 숨기기
            lyLogin.isHidden = false
            lyLoginInfo.isHidden = true
            lyLogout.isHidden = true
            lbPersonal.text = "개인 맞춤형 서비스는 로그인 후 이용 가능합니다."
        }
        
        lbInfoNotification.text = "시스템 설정에서 알림이 꺼져 있습니다.\n원활한 알림 수신을 위해 시스템 설정에서 앱 알림을\n활성화해 주세요."
        lbInfoFont.text = "이 앱의 텍스트 크기는 기기의 설정을 통해 변경할 수 있습니다.\n설정 > 디스플레이 및 밝기 > 텍스트 크기"
        lbNonMember.text = "개인 맞춤형 서비스, 회원전용 콘텐츠에 접근하려\n면 로그인하십시오."
        lbVersion.text = appVersion
        
        btnSwitch.onTintColor = UIColor(named: "#0879D1")
        
//        divider.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.06)
//        divider.layer.shadowOpacity = 0.85
//        divider.layer.shadowOffset = CGSize(width: 0, height: -2)
//        divider.layer.shadowRadius = 4
    }
    
    private func setLoginTypeImage(loginType: String) {
        
        // 라디우스 설정
        imgLoginType.layer.cornerRadius = 26
        imgLoginType.layer.masksToBounds = true
        
        switch loginType {
        case "kakao":
            imgLoginType.image = UIImage(named: "kakaoLoginIcon")
        case "naver":
            imgLoginType.image = UIImage(named: "naverLoginIcon")
        case "google":
            imgLoginType.image = UIImage(named: "googleLoginIcon")
        case "apple":
            imgLoginType.image = UIImage(named: "appleLoginIcon")
        case "email":
            imgLoginType.image = UIImage(named: "hkLoginIcon")
        default:
            imgLoginType.image = nil
        }
    }
    
    private func updateLoginTypeImage() {
        guard let accountData = UserDefaults.standard.object(forKey: "_ACCOUNTDATA") as? [String: Any],
              let loginType = accountData["login_type"] as? String else {
            imgLoginType.image = nil
            return
        }
        
        setLoginTypeImage(loginType: loginType)
    }
    
    private func updateUserId() {
        guard let accountData = UserDefaults.standard.object(forKey: "_ACCOUNTDATA") as? [String: Any],
              let userId = accountData["UserId"] as? String else {
            lbUserId.text = ""
            return
        }
        
        lbUserId.text = userId.urlDecoded
    }
    
    private func setupNotificationObserver() {
        // 앱 포그라운드 복귀 시에만 체크
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .flatMapLatest { _ in
                Observable.create { observer in
                    UNUserNotificationCenter.current().getNotificationSettings { settings in
                        observer.onNext(settings.authorizationStatus)
                        observer.onCompleted()
                    }
                    return Disposables.create()
                }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] status in
                self?.updateUI(for: status)
            })
            .disposed(by: disposeBag)
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.updateUI(for: settings.authorizationStatus)
            }
        }
    }

    private func updateUI(for status: UNAuthorizationStatus) {
        lyManagerNoti.isHidden = (status == .authorized)
        lyAuthorizedNoti.isHidden = ( status != .authorized)
    }
    
    func isLoggedIn() -> Bool {
        guard let accountData = UserDefaults.standard.object(forKey: "_ACCOUNTDATA") as? [String: Any] else {
            return false  // _ACCOUNTDATA 없으면 false
        }
        
        // login_type은 필수 - 없거나 빈값이면 false
//        guard let loginType = accountData["login_type"] as? String,
//              !loginType.isEmpty else {
//            return false
//        }
//        
//        
//        guard let userId = accountData["UserId"] as? String,
//              !userId.isEmpty else {
//            return false
//        }
        
        // 최소 하나의 토큰은 있어야 함 - 모든 토큰이 없거나 빈값이면 false
        let tokens = [
            accountData["_hk_token"] as? String,
            accountData["ssoToken"] as? String
        ].compactMap { $0 }.filter { !$0.isEmpty }
        
        guard !tokens.isEmpty else {
            return false  // 유효한 토큰이 하나도 없으면 false
        }
        
        // 사용자 ID 체크 - 없거나 빈값이면 false
        guard let ssoId = accountData["SSOid"] as? String,
              !ssoId.isEmpty else {
            return false
        }
        
        return true  // 모든 조건을 만족해야 true
    }
    
    private func showLoginView() {
        guard let accountView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AccountViewController") as? AccountViewController else { return }
        
        accountView.accountViewType = "login"
        
        accountView.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        self.present(accountView, animated: true, completion: nil)
    }
}

// MARK: - WebNavigationDelegate
extension SettingsViewController: WebNavigationDelegate {
    func openNewsDetail(url: URL, title: String?) {
        print("NewsContentController: Opening news detail for URL: \(url)")
        
        let newsDetailVC = NewsDetailViewController(url: url, title: title)
        newsDetailVC.webNavigationDelegate = self
        newsDetailVC.hidesBottomBarWhenPushed = false
        
        navigationController?.pushViewController(newsDetailVC, animated: true)
    }
}
