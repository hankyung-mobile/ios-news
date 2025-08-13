//
//  MemoryManager.swift
//  newsApp
//
//  Created by jay on 5/20/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

/// 메모리 사용량 모니터링 및 관리 클래스
class MemoryManager {
    // 싱글톤 인스턴스
    static let shared = MemoryManager()
    
//    // 메모리 경고 이벤트
//    let memoryWarning = PublishRelay<Void>()
//    
//    // 메모리 사용량 모니터링 간격 (초)
//    private let monitoringInterval: TimeInterval = 5.0
//    
//    // 메모리 임계값 (사용 가능한 메모리가 이 값 이하로 떨어지면 경고)
//    private let memoryThreshold: UInt64 = 100 * 1024 * 1024  // 100MB
//    
//    // 모니터링 중 여부
//    private var isMonitoring = false
//    
//    // 타이머 및 디스포즈백
//    private var timer: Timer?
//    private let disposeBag = DisposeBag()
//    
//    private init() {
//        // 메모리 경고 알림 관찰
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(handleMemoryWarning),
//            name: UIApplication.didReceiveMemoryWarningNotification,
//            object: nil
//        )
//    }
//    
//    deinit {
//        NotificationCenter.default.removeObserver(self)
//        stopMonitoring()
//    }
//    
//    // MARK: - 메모리 모니터링
//    
//    /// 메모리 모니터링 시작
//    func startMonitoring() {
//        guard !isMonitoring else { return }
//        
//        isMonitoring = true
//        
//        // 타이머 설정
//        timer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
//            self?.checkMemoryUsage()
//        }
//    }
//    
//    /// 메모리 모니터링 중지
//    func stopMonitoring() {
//        guard isMonitoring else { return }
//        
//        isMonitoring = false
//        timer?.invalidate()
//        timer = nil
//    }
//    
//    /// 메모리 사용량 확인
//    private func checkMemoryUsage() {
//        let usedMemory = getUsedMemory()
//        let totalMemory = getTotalMemory()
//        let freeMemory = totalMemory - usedMemory
//        
//        // 로그 출력
//        print("📊 Memory: Used \(formatMemorySize(usedMemory)), Free \(formatMemorySize(freeMemory)), Total \(formatMemorySize(totalMemory))")
//        
//        // 임계값 확인
//        if freeMemory < memoryThreshold {
//            // 메모리 경고 이벤트 발생
//            memoryWarning.accept(())
//        }
//    }
//    
//    /// 메모리 경고 처리
//    @objc private func handleMemoryWarning() {
//        print("⚠️ Memory Warning received!")
//        memoryWarning.accept(())
//    }
//    
//    // MARK: - 메모리 정보 조회
//    
//    /// 앱이 사용 중인 메모리 크기 (바이트)
//    func getUsedMemory() -> UInt64 {
//        var info = mach_task_basic_info()
//        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
//        
//        let result = withUnsafeMutablePointer(to: &info) {
//            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
//                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
//            }
//        }
//        
//        if result == KERN_SUCCESS {
//            return info.resident_size
//        } else {
//            return 0
//        }
//    }
//    
//    /// 전체 시스템 메모리 크기 (바이트)
//    func getTotalMemory() -> UInt64 {
//        return ProcessInfo.processInfo.physicalMemory
//    }
//    
//    // MARK: - 유틸리티
//    
//    /// 메모리 크기를 사람이 읽기 쉬운 형식으로 변환
//    func formatMemorySize(_ bytes: UInt64) -> String {
//        let formatter = ByteCountFormatter()
//        formatter.allowedUnits = [.useAll]
//        formatter.countStyle = .file
//        return formatter.string(fromByteCount: Int64(bytes))
//    }
//    
//    /// 메모리 캐시 정리
//    func clearMemoryCaches() {
//        // 이미지 캐시 정리
//        URLCache.shared.removeAllCachedResponses()
//        
//        // 디스크 및 메모리 캐시 정리
//        let dataTypes = Set([WKWebsiteDataTypeDiskCache,
//                            WKWebsiteDataTypeMemoryCache])
//        
//        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes,
//                                              modifiedSince: Date(timeIntervalSince1970: 0)) {
//            print("✅ Memory caches cleared")
//        }
//        
//        // GC 유도
//        autoreleasepool {
//            // 추가 정리 작업이 필요한 경우
//        }
//    }
}
