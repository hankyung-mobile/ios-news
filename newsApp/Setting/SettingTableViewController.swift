//
//  SettingTableViewController.swift
//  newsApp
//
//  Created by hkcom on 2020/10/23.
//  Copyright © 2020 hkcom. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseMessaging

class SettingTableViewController: UITableViewController {
    
    // 섹션 타입 정의
    enum SectionType: Int, CaseIterable {
        case account = 0
        case notification
        case totalSubscription  // 선택적으로 표시/숨김 가능한 섹션
        case subscription
        case appVersion
        
        // 활성 섹션 목록
        static var activeSections: [SectionType] {
            var sections = [account, notification , appVersion]
            
            // 특정 조건에 따라 추가 섹션 표시
            if UserDefaults.standard.bool(forKey: "_ISLOGIN") {
                sections.insert(.totalSubscription, at: 2)
            }
            
            if UserDefaults.standard.bool(forKey: "_ISLOGIN") {
                sections.insert(.subscription, at: 3)
            }
            
            return sections
        }
        
        // 실제 테이블뷰 섹션 인덱스 계산
        static func indexFor(_ type: SectionType) -> Int? {
            return activeSections.firstIndex(of: type)
        }
    }
    
    var notificationAuthorizationStatus = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized {
                self.notificationAuthorizationStatus = true
            }
            else {
                self.notificationAuthorizationStatus = false
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
    }
    
    func reloadPushStatusSection() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized {
                self.notificationAuthorizationStatus = true
            }
            else {
                self.notificationAuthorizationStatus = false
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func reloadLoginCell(){
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // 실제 섹션 타입 가져오기
        let sectionType = SectionType.activeSections[indexPath.section]
        
        switch sectionType {
        case .account:
            guard UserDefaults.standard.bool(forKey: "_ISLOGIN") else {
                
                guard let accountView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AccountViewController") as? AccountViewController else { return }
                
                accountView.accountViewType = "login"
                
                accountView.modalTransitionStyle = UIModalTransitionStyle.coverVertical
                self.present(accountView, animated: true, completion: nil)
                
                tableView.deselectRow(at: indexPath, animated: false)
                return
                
            }
            
            
            if indexPath.row == 1 {
                
                guard let accountView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AccountViewController") as? AccountViewController else { return }
                
                accountView.accountViewType = "accountInfo"
                
                accountView.modalTransitionStyle = UIModalTransitionStyle.coverVertical
                self.present(accountView, animated: true, completion: nil)
                
                tableView.deselectRow(at: indexPath, animated: false)
                
                return
            }
            
            let alert = UIAlertController(title: nil, message: "로그아웃 하시겠습니까?", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "확인", style: .default, handler : {(action) in
                
                guard let logoutView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LogoutViewController") as? LogoutViewController else { return }
                self.present(logoutView, animated: false)
                
            })
            let cancel = UIAlertAction(title: "취소", style: .cancel, handler : nil)
            alert.addAction(cancel)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            
            tableView.deselectRow(at: indexPath, animated: false)
            return
            
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return SectionType.activeSections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        let sectionType = SectionType.activeSections[section]
        
        switch sectionType {
        case .account:
            return nil
        case .notification:
            return "알림관리"
        case .totalSubscription:
            return "기자구독알림"
        case .subscription:
            return nil
        case .appVersion:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        let sectionType = SectionType.activeSections[section]
        
        switch sectionType {
        case .account:
            return nil
        case .notification:
            return nil
        case .totalSubscription:
            return "구독한 기자의 개별 알림을 설정합니다.\n기자를 구족하고 새 기사의 알림을 받아보세요"
        case .subscription:
            return "가나다순으로 정렬됩니다"
        case .appVersion:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // 실제 섹션 타입 가져오기
        let sectionType = SectionType.activeSections[section]
        
        switch sectionType {
        case .account:
            return UserDefaults.standard.bool(forKey: "_ISLOGIN") ? 2 : 1
        case .notification:
            return 1
        case .totalSubscription:
            return 1
        case .subscription:
            return 1
        case .appVersion:
            return 1
        }
        
    }
    
    //    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    //        // 섹션 2와 3은 titleForHeaderInSection에서 타이틀을 설정했으므로
    //        // 헤더 유지 (또는 원하는 높이로 조정)
    //        if section == 2 || section == 3 {
    //            return UITableView.automaticDimension
    //        }
    //        // 다른 섹션은 헤더 없음
    //        return 0.1 // iOS에서 허용하는 최소값 (완전히 0은 허용되지 않음)
    //    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 실제 섹션 타입 가져오기
        let sectionType = SectionType.activeSections[indexPath.section]
        
        switch sectionType {
        case .account:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "rightDisclosuerCell", for: indexPath) as? SettingTableViewRightDisclosuerCell else { return UITableViewCell() }
            
            if UserDefaults.standard.bool(forKey: "_ISLOGIN") {
                if(indexPath.row == 1){
                    cell.title.text = "계정관리"
                } else if(indexPath.row == 0){
                    cell.title.text = "로그아웃"
                }
            } else {
                cell.title.text = "로그인"
            }
            
            return cell
            
        case .notification:
            if notificationAuthorizationStatus {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as? SettingTableViewSwitchCell else { return UITableViewCell() }
                cell.title.text = "속보 & 주요기사 알림"
                cell.switchButton.tag = 1
                
                let notificationStatus = UserDefaults.standard.bool(forKey: IsNotificationKey.news.toString())
                
                if notificationStatus {
                    cell.switchButton.isOn = true
                }
                else {
                    cell.switchButton.isOn = false
                }
                
                return cell
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "notificationAuthorizationCell", for: indexPath)
            
            return cell
            
        case .totalSubscription:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "eachSubscriptionCell", for: indexPath) as? SettingTableViewEachSubscriptionCell else { return UITableViewCell() }
            cell.title.text = "구독자"
            cell.subTitle.text = "구독일 24.11.23 34:00"
            return cell
            
        case .subscription:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "eachSubscriptionCell", for: indexPath) as? SettingTableViewEachSubscriptionCell else { return UITableViewCell() }
            cell.title.text = "구독자"
            cell.subTitle.text = "구독일 24.11.23 34:00"
            return cell
            
        case .appVersion:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "rightDetailCell", for: indexPath) as? SettingTableViewRightDetailCell else { return UITableViewCell() }
            cell.title.text = "버전"
            cell.detail.text = appVersion
            return cell
            
        }
    }
}



class SettingTableViewSwitchCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var switchButton: UISwitch!
    
    @IBAction func changeSwitch(_ sender: UISwitch) {
        pushChange(sender)
    }
    
    func pushChange(_ sender: UISwitch) {
        
        if sender.isOn {
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                if settings.authorizationStatus == .authorized {
                    Messaging.messaging().subscribe(toTopic: TopicName.news.toString()) { error in
                        print(error as Any)
                        if error != nil {
                            UserDefaults.standard.set(false, forKey: IsNotificationKey.news.toString())
                            self.sendDataWhenComplete()
                            DispatchQueue.main.async {
                                sender.isOn = false
                            }
                            
                        } else {
                            UserDefaults.standard.set(true, forKey: IsNotificationKey.news.toString())
                            self.sendDataWhenComplete()
                        }
                    }
                    
                }
                else {
                    DispatchQueue.main.async {
                        sender.isOn = false
                    }
                    
                    let dialog = UIAlertController(title: "알림설정", message: "기기의 설정 > 알림 > 한국경제에서\n'알림허용'을 ON하고 설정가능", preferredStyle: .alert)
                    let action = UIAlertAction(title: "확인", style: UIAlertAction.Style.default)
                    dialog.addAction(action)
                    DispatchQueue.main.async {
                        settingTableViewController.present(dialog, animated: true, completion: nil)
                    }
                }
            }
        }
        else {
            Messaging.messaging().unsubscribe(fromTopic: TopicName.news.toString()) { error in
                
            }
            UserDefaults.standard.set(false, forKey: IsNotificationKey.news.toString())
            self.sendDataWhenComplete()
            
            Messaging.messaging().unsubscribe(fromTopic: TopicName.newsOld.toString())
        }
    }
    
    func sendDataWhenComplete() {
        let fcmToken = UserDefaults.standard.string(forKey: "FCMToken")
        let userInfo = getUserIdAndUserNo()
        let userId = userInfo.userId
        let userNo = userInfo.userNo
        let isOn = getThatAsYN(for: IsNotificationKey.news.toString())
        
        var parameters: [String: String] = [
            "fcmtoken": fcmToken ?? "",
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

class SettingTableViewNotificationAuthorizationCell: UITableViewCell {
    
    @IBAction func openSettingsTapped(_ sender: Any) {
        if let appSettings = URL(string: UIApplication.openSettingsURLString){
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }
}


class SettingTableViewRightDetailCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var detail: UILabel!
}

class SettingTableViewDisclosureCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
}

class SettingTableViewRightDisclosuerCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
}

class SettingTableViewEachSubscriptionCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subTitle: UILabel!
    @IBOutlet weak var btnSwitch: UISwitch!
    
}
