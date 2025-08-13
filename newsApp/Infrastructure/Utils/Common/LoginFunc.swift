//
//  LoginFunc.swift
//  newsApp
//
//  Created by hkcom on 2022/06/21.
//  Copyright © 2022 hkcom. All rights reserved.
//

import Foundation

var loginDataSet: Set<String> = []

func saveLoginData(data: [String: String], cookie:[String:Any]) {
    UserDefaults.standard.set(true, forKey: "_ISLOGIN")
    UserDefaults.standard.set(data["loginid"], forKey: "_LOGINID")
    UserDefaults.standard.set(data["ssotoken"], forKey: "_SSOTOKEN")
    UserDefaults.standard.set(data["loginpwd"] , forKey: "_LOGINPWD")
        cookie.forEach { (key, value) in
            if let val = value as? String {
                createCookie(name:key, value: val)
                loginDataSet.insert(key)
            }
        }
}

func saveLoginData(data:[String:Any]) {
    
    // 로그인 여부
    UserDefaults.standard.set(true, forKey: "_ISLOGIN")
    // 자동 로그인용으로 데이터 저장
    UserDefaults.standard.set(data, forKey: "_ACCOUNTDATA")
    
    data.forEach { (key, value) in
        if let val = value as? String {
            UserDefaults.standard.set(val, forKey: key)
            createCookie(name:key, value: val)
            loginDataSet.insert(key)
        }
    }
}


func deleteLoginData() {
    
    NotificationCenter.default.post(name: .logoutSuccess, object: nil)
    
    UserDefaults.standard.set(false, forKey: "_ISLOGIN")
    UserDefaults.standard.removeObject(forKey: "_ACCOUNTDATA")

    loginDataSet.forEach { name in
        UserDefaults.standard.removeObject(forKey: name)
        deleteCookie(name: name)
    }
    deleteLoginCookie()
    
}
