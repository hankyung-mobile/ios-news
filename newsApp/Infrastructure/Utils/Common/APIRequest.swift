//
//  APIRequest.swift
//  newsApp
//
//  Created by hkcom on 2022/06/21.
//  Copyright © 2022 hkcom. All rights reserved.
//

import Foundation

func requestJsonData(url: String, method: String = "GET", parameter: Dictionary<String, String> = [:], completion: @escaping (_ data: Dictionary<String, Any>) -> Void) {
    
    var url = url
    
    let formDataString = (parameter.compactMap({ (key, value) -> String in return "\(key)=\(value)" }) as Array).joined(separator: "&")
    
    if(method == "GET" && parameter.count > 0){
        url  += "?\(formDataString)"
    }
    
    let requestUrl = URL(string: url)!
    var request = URLRequest(url: requestUrl)
    
    request.httpMethod = method
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    if method == "POST" && parameter.count > 0  {
        let formEncodedData = formDataString.data(using: .utf8)
        request.httpBody = formEncodedData
    }

    URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
        do {
            if let responseData = try JSONSerialization.jsonObject(with: data ?? Data(), options: []) as? [String: Any] {
                completion(responseData)
            }
            else {
                completion([:])
            }
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
            completion([:])
        }
        
    }).resume()
  
    
}


func requestSet(url: String, method: String = "GET", parameter: Dictionary<String, String> = [:]) {
    
    var url = url
    
    let formDataString = (parameter.compactMap({ (key, value) -> String in return "\(key)=\(value)" }) as Array).joined(separator: "&")
    
    if(method == "GET" && parameter.count > 0){
        url  += "?\(formDataString)"
    }
    
    let requestUrl = URL(string: url)!
    var request = URLRequest(url: requestUrl)
    
    request.httpMethod = method
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    if method == "POST" && parameter.count > 0  {
        let formEncodedData = formDataString.data(using: .utf8)
        request.httpBody = formEncodedData
    }

    URLSession.shared.dataTask(with: request).resume()
  
    
}

