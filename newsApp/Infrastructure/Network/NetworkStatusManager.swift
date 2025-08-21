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
    private init() {}
    
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
}
