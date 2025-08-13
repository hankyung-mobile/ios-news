//
//  getIP.swift
//  newsApp
//
//  Created by InTae Gim on 2023/02/17.
//  Copyright © 2023 hkcom. All rights reserved.
//

import Foundation

// V4만 추출하게 수정 -Jay 250508-
func getIpAddress() -> String? {
    var address: String?
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    
    if getifaddrs(&ifaddr) == 0 {
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { return nil }
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            // IPv4 필터링 (AF_INET은 IPv4를 의미)
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                // en0는 WiFi, pdp_ip0는 셀룰러 연결
                if name == "en0" || name == "pdp_ip0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                               &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                    address = String(cString: hostname)
                    break  // 첫 번째 찾은 IPv4 주소를 반환
                }
            }
        }
        freeifaddrs(ifaddr)
    }
    
    return address
}
