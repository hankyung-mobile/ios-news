//
//  NetworkManager.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Alamofire
import RxAlamofire

class NetworkManager {
    static let shared = NetworkManager()
    
    // 커스텀 설정
    var timeoutInterval: TimeInterval = 10
    var retryCount: Int = 2
    var enableLogging: Bool = true
    
    private init() {}
    
    func request<T: Codable>(
        _ router: APIRouter,
        parameters: [String: Any]? = nil,
        responseType: T.Type,
        timeout: TimeInterval? = nil,
        retries: Int? = nil
    ) -> Observable<T> {
        
        let finalTimeout = timeout ?? timeoutInterval
        let finalRetries = retries ?? retryCount
        
        // URLRequest 생성 및 로깅
        let urlRequest: URLRequest
          do {
              var baseRequest = try router.asURLRequest()
              
              if let parameters = parameters {
                  let method = baseRequest.httpMethod ?? "GET"
                  
                  if method == "GET" || method == "DELETE" {
                      // GET, DELETE: 쿼리 파라미터 (인코딩 없이)
                      if let url = baseRequest.url,
                         var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                          let queryString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
                          urlComponents.query = queryString
                          baseRequest.url = urlComponents.url
                      }
                  } else {
                      // POST, PUT, PATCH: 바디에 JSON
                      let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
                      baseRequest.httpBody = jsonData
                      baseRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                  }
              }
              
              urlRequest = baseRequest
              logRequest(urlRequest, parameters: parameters)
        } catch {
            return Observable.error(NetworkError.networkError("URLRequest 생성 실패: \(error.localizedDescription)"))
        }
        return RxAlamofire
            .request(urlRequest)
            .validate(statusCode: 200..<300)
            .responseJSON()
            .retry(finalRetries)
            .timeout(.seconds(Int(finalTimeout)), scheduler: MainScheduler.instance)
            .map { dataResponse -> T in
                guard let json = dataResponse.value else {
                    throw NetworkError.invalidResponse
                }
                
                if let response = dataResponse.response {
                    self.logResponse(response, data: json)
                }
                
                let data = try JSONSerialization.data(withJSONObject: json)
                return try JSONDecoder().decode(T.self, from: data)
            }
            .catch { error -> Observable<T> in
                self.logError(error)
                return Observable.error(self.handleError(error))
            }
    }
    
    // URLRequest 로깅
    private func logRequest(_ request: URLRequest, parameters: [String: Any]?) {
        guard enableLogging else { return }
        
        print("🌐 ===== Network Request =====")
        print("URL: \(request.url?.absoluteString ?? "Unknown")")
        print("Method: \(request.httpMethod ?? "Unknown")")
        print("Parameters: \(parameters?.description ?? "Unknown")")
//        print("호출 스택: \(Thread.callStackSymbols)")
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            print("Headers: \(headers)")
        }
        
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
        print("Timeout: \(request.timeoutInterval)s")
        print("=============================")
    }
    
    // Response 로깅
    private func logResponse(_ response: HTTPURLResponse, data: Any) {
        guard enableLogging else { return }
        
        print("✅ ===== Network Response =====")
        print("Status Code: \(response.statusCode)")
        print("Data: \(data)")
        print("==============================")
    }
    
    // Error 로깅
    private func logError(_ error: Error) {
        guard enableLogging else { return }
        
        print("❌ ===== Network Error =====")
         print("Error Type: \(type(of: error))")
         print("Error: \(error.localizedDescription)")
         print("Error Description: \(error)")
         print("===========================")
    }
    
    private func handleError(_ error: Error) -> NetworkError {
        
        if let afError = error as? AFError {
            switch afError {
            case .responseValidationFailed(let reason):
                if case .unacceptableStatusCode(let code) = reason {
                    return NetworkError.serverError(code)
                }
                return NetworkError.invalidResponse
            case .sessionTaskFailed(let urlError as URLError):
                if urlError.code == .timedOut {
                    return NetworkError.networkError("요청 시간 초과")
                }
                return NetworkError.networkError(urlError.localizedDescription)
            default:
                return NetworkError.networkError(afError.localizedDescription)
            }
        }
        return NetworkError.networkError(error.localizedDescription)
    }
}

enum NetworkError: Error {
    case invalidResponse
    case serverError(Int)
    case decodingError
    case networkError(String)
    
    var message: String {
        switch self {
        case .invalidResponse: return "응답이 유효하지 않습니다"
        case .serverError(let code): return "서버 에러 (\(code))"
        case .decodingError: return "데이터 변환 실패"
        case .networkError(let msg): return msg
        }
    }
}
