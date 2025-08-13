//
//  AdnextInterstitialAd.h
//  Adnext
//
//  Created by gskang on 2016. 4. 19..
//  Copyright © 2016년 mocoplex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIkit/UIkit.h>
#import "AdnextAdsDefine.h"

@class AdnextInterstitialAd;

@protocol AdnextInterstitialAdDelegate <NSObject> 

// 전면광고에 대한 수신성공
- (void)adnextInterstitialAd:(AdnextInterstitialAd *)interstitialAd didReceivedAd:(ADNEXT_ADS_PTYPE)ptype;

// 전면광고에 대한 수신실패
- (void)adnextInterstitialAd:(AdnextInterstitialAd *)interstitialAd didFailedAd:(ADNEXT_ADS_PTYPE)ptype;

// 모든 전면광고에 대한 수신 실패
- (void)adnextInterstitialAdDidFailedAd:(AdnextInterstitialAd *)interstitialAd;

@optional
// 전면광고에 대한 클릭 이벤트 발생
- (void)adnextInterstitialAd:(AdnextInterstitialAd *)interstitialAd didClickedAd:(ADNEXT_ADS_PTYPE)platform;

@end


@protocol AdnextInterstitialAdReportProtocol <NSObject>

- (void)adnextReportMediationPlatformDidFailedAd:(ADNEXT_ADS_PTYPE)ptype;
- (void)adnextReportMediationPlatformDidReceivedAd:(ADNEXT_ADS_PTYPE)ptype;
- (void)adnextReportMediationPlatformDidClosedController:(ADNEXT_ADS_PTYPE)ptype;
- (void)adnextReportMediationPlatformAdClick:(ADNEXT_ADS_PTYPE)ptype;

@end


/**
 *  해당 클래스를 사용하여 ADNEXT 전면배너 기능을 사용할 수 있다.
 */
@interface AdnextInterstitialAd : NSObject <AdnextInterstitialAdReportProtocol> {
    
}

//테스트 모드 설정 값 (기본값 : NO)
@property (nonatomic) BOOL isTestMode;

@property (nonatomic, weak, readonly) UIViewController *rootViewController;


/**
 *  전면광고 요청 생성자
 *
 *  @param rootViewController 전면광고 뷰컨트롤러를 노출한 루트뷰 컨트롤러
 */
- (instancetype)initWithRootViewController:(UIViewController *)rootViewController;


/**
 *  젼면광고를 요청한다.
 *  요청한 애드넥스트 광고를 요청하고 성공 시 콜백을 호출한다.
 *
 *  @param adnextAppKey 애드넥스트 앱키 (미디에이션 설정정보를 갖는 키값)
 *  @param delegate 광고 요청 및 수신 상태에 대한 델리게이트
 */
- (BOOL)requestAdWithKey:(NSString *)adnextAppKey adDelegate:(id<AdnextInterstitialAdDelegate>)delegate;

/**
 *  전면광고 요청을 중단한다.
 */
- (void)stopAdReqeust;

@end
