//
//  AdMobManager.swift
//  newsApp
//
//  Created by jay on 7/28/25.
//  Copyright © 2025 hkcom. All rights reserved.
//


import GoogleMobileAds

class AdMobManager: NSObject, FullScreenContentDelegate {
    static let shared = AdMobManager()
    
    private var interstitialAd: InterstitialAd?
    private var pendingViewController: UIViewController?
    private let adUnitID = "ca-app-pub-1515829298859818/5149509965" // 테스트 ID
    private var isLoading = false
    
    var isAdReady: Bool {
        return interstitialAd != nil
    }
    
    private override init() {
        super.init()
    }
    
    func loadAd() {
        // 이미 로딩 중이면 중복 로드 방지
        guard !isLoading else { return }
        
        isLoading = true
        
        InterstitialAd.load(with: adUnitID,
                            request: Request()) { [weak self] ad, error in
            self?.isLoading = false
            
            if let error = error {
                print("광고 로드 실패: \(error)")
                return
            }
            
            self?.interstitialAd = ad
            self?.interstitialAd?.fullScreenContentDelegate = self
            print("광고 로드 성공!")
            
            // 대기 중인 VC가 있으면 광고 표시
            if let pendingVC = self?.pendingViewController {
                DispatchQueue.main.async {
                    self?.showAd(from: pendingVC)
                    self?.pendingViewController = nil
                }
            }
        }
    }
    
    func showAd(from viewController: UIViewController) {
        if let ad = interstitialAd {
            // 광고가 준비되어 있으면 바로 표시
            ad.present(from: viewController)
        } else {
            // 광고가 준비되지 않았으면 VC 저장하고 로드
            print("광고 준비 중... VC 대기열에 저장")
            pendingViewController = viewController
            
            // 로딩 중이 아니면 광고 로드 시작
            if !isLoading {
                loadAd()
            }
        }
    }
    
    // MARK: - FullScreenContentDelegate
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("광고 닫힘")
        interstitialAd = nil
        pendingViewController = nil
        
        // 다음 광고 미리 로드
        loadAd()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("광고 표시 실패: \(error)")
        interstitialAd = nil
        pendingViewController = nil
    }
}
