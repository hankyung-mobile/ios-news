//
//  NetworkStatusManager.swift
//  newsApp
//
//  Created by jay on 8/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import SystemConfiguration

class NetworkStatusManager {
    static let shared = NetworkStatusManager()
    
    private var reachability: SCNetworkReachability?
    private var isMonitoring = false
    
    private init() {}
    
    // 기존 동기식 체크 (유지)
    func isConnected() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else { return false }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        return flags.contains(.reachable) && !flags.contains(.connectionRequired)
    }
    
    // 실시간 감지 추가
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        reachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }
        
        guard let reachability = reachability else { return }
        
        // 콜백 설정
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        let callback: SCNetworkReachabilityCallBack = { (reachability, flags, info) in
            guard let info = info else { return }
            let manager = Unmanaged<NetworkStatusManager>.fromOpaque(info).takeUnretainedValue()
            
            DispatchQueue.main.async {
                let isConnected = flags.contains(.reachable) && !flags.contains(.connectionRequired)
                
                NotificationCenter.default.post(
                    name: .networkStatusChanged,
                    object: nil,
                    userInfo: ["isConnected": isConnected]
                )
            }
        }
        
        SCNetworkReachabilitySetCallback(reachability, callback, &context)
        SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        
        isMonitoring = true
        print("🌐 네트워크 모니터링 시작 (SystemConfiguration)")
    }
    
    func stopMonitoring() {
        guard let reachability = reachability, isMonitoring else { return }
        
        SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        self.reachability = nil
        isMonitoring = false
        
        print("🌐 네트워크 모니터링 중지")
    }
}
