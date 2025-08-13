//
//  GAInterface.swift
//  newsApp
//
//  Created by InTae Gim on 7/23/24.
//  Copyright © 2024 hkcom. All rights reserved.
//

import Foundation
import WebKit

import FirebaseAnalytics

// MARK: 에러 타입 정의
enum GAError: Error {
    case requiredType
    case requiredTitle
    case requiredEventName
}

let deviceId = Analytics.appInstanceID()

class GA4 {

    func hybridData(message: WKScriptMessage) throws {
        let data = (message.body as AnyObject).data(using: String.Encoding.utf8.rawValue,allowLossyConversion: false)!
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            fatalError("\(Error.self)")
        }
        

        do {
            // MARK: GA 데이터 객체 선언
            var gaData: [String: Any] = [:]

            // MARK: 화면 이름 및 데이터 전송 타입 설정
            guard let screenName = json["title"] as? String else { throw GAError.requiredTitle }
            guard let eventType = json["type"] as? String else { throw GAError.requiredType }

            // MARK: 공통 데이터 설정
            for (key, value) in json {
                
                // 맞춤 측정항목 설정
                if key.contains("_amount") {
                    gaData[key] = convertMetric(data: value as Any)
                }
            
                // 맞춤 측정기준 설정
                else if key.contains("hk_") {
                    if let value = value as? String {
                        gaData[key] = value.prefix(500)
                    }
                }
                
                // 사용자 속성 및 사용자ID 설정
                else if key.contains("up_") {
                    if let value = value as? String {
                        Analytics.setUserProperty(value, forName: key)
                        if key == "up_uid" {
                            Analytics.setUserID(value)
                        }
                    }
                }
            }
            
            
            
            // ClientID 설정
            Analytics.setUserProperty(Analytics.appInstanceID(), forName: "up_cid")

            // MARK: 데이터 전송
            // 화면 데이터 전송
            if eventType == "P" {
                gaData[AnalyticsParameterScreenName] = screenName
                Analytics.logEvent(AnalyticsEventScreenView, parameters: gaData)
            }
            // 이벤트 데이터 전송
            else if eventType == "E" {
                guard let eventName = json["event_name"] as? String else { throw GAError.requiredEventName }
                Analytics.logEvent(eventName, parameters: gaData)
            }
            
            
        } catch {
//            switch error {
//            case GAError.requiredType:
//                print("GA4_Error: type 값 확인 부탁드립니다.")
//            case GAError.requiredTitle:
//                print("GA4_Error: title 값 확인 부탁드립니다.")
//            case GAError.requiredEventName:
//                print("GA4_Error: event_name 값 확인 부탁드립니다.")
//            default:
//                print("GA4_Interface_Error")
//            }
        }
    }

    // MARK: 맞춤 측정항목 데이터 형변환 함수 정의
    func convertMetric(data: Any) -> Any {
        guard let stringValue = data as? String else {
            return data
        }
        guard let doubleValue = Double(stringValue) else {
            return "GA4_Metric_Error"
        }

        return doubleValue
    }
}
