//
//  AdnextAdBannerView.h
//  Adnext
//
//  Created by gskang on 2016. 4. 19..
//  Copyright © 2016년 mocoplex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdnextAdsDefine.h"

@class AdnextAdBannerView;

@protocol AdnextAdBannerViewDelegate <NSObject>

// AdnextAdBannerView 광고요청 재개 상태에서 내부적인 상태 변화를 통지합니다.
- (void)adnextAdBannerView:(AdnextAdBannerView *)bannerView didChangeState:(ADNEXT_ADS_STATE)state withExtraInfo:(id)info;

// 광고의 성공 상태를 반환합니다.
- (void)adnextAdBannerView:(AdnextAdBannerView *)bannerView didReceivedAd:(ADNEXT_ADS_PTYPE)platform;

// 광고의 실패 상태를 반환합니다.
- (void)adnextAdBannerView:(AdnextAdBannerView *)bannerView didFailedAd:(ADNEXT_ADS_PTYPE)platform;

// 광고의 최종 실패 상태를 반환합니다.
- (BOOL)adnextAdBannerViewDidFailedAtAllPlatform:(AdnextAdBannerView *)bannerView;

@end


@protocol AdnextAdBannerViewReportProtocol <NSObject>

- (void)adnextReportMediationPlatformDidReceivedAd:(ADNEXT_ADS_PTYPE)ptype withView:(UIView *)adView;
- (void)adnextReportMediationPlatformDidFailedAd:(ADNEXT_ADS_PTYPE)ptype;

- (void)adnextReportMediationPlatformAdClick:(ADNEXT_ADS_PTYPE)ptype;

@end


typedef NS_ENUM(NSInteger, ADN_ADVIEW_VERTICAL_ALIGN) {
    ADN_ADVIEW_VERTICAL_ALIGN_BOTTOM = 0, //DEFAULT
    ADN_ADVIEW_VERTICAL_ALIGN_TOP,
};

/**
 *  해당 클래스를 사용하여 애드넥스트 띠배너 기능을 사용할 수 있다.
 */
@interface AdnextAdBannerView : UIView  <AdnextAdBannerViewReportProtocol> {
    
}

@property (nonatomic) ADN_ADVIEW_VERTICAL_ALIGN verticalAlign;

// a테스트 모드 설정 값 (기본값 : NO)
@property (nonatomic) BOOL isTestMode;

// 설정된 배너 플랫폼의 요청이 한바퀴 완료된 후 처음부터 재시작할지 여부,
// 기본값 : NO (값이 NO일 경우 마지막 수신한 광고 뷰가 유지된다.)
@property (nonatomic) BOOL repeatLoop;

// 모든 스케쥴 광고가 실패한 이후 다음 루프까지의 대기 시간
// 기본 설정 값 10초 (설정 가능 범위 값 1~120초)
@property (nonatomic) NSUInteger repeatLoopWaitTime;

// 애드넥스트 / 하우스 모든 광고에 실패한 경우에 대한 백필뷰
@property (nonatomic, strong) UIView *backFillView;

/**
 *  배너 광고를 요청한다.
 *  요청한 애드넥스트 키값에 해당하는 띠배너 광고에 대해서 순차적으로 광고를 요청하고 성공/실패 시 콜백을 호출한다.
 *
 *  @param adnextAppKey 애드넥스트 앱키 (mid)
 *  @param delegate 광고 요청 및 수신 상태에 대한 델리게이트
 */
- (BOOL)startAdViewWithKey:(NSString *)adnextAppKey
        rootViewController:(UIViewController *)rootViewController
                adDelegate:(id<AdnextAdBannerViewDelegate>)delegate;

/**
 *  전면광고 요청을 중단한다.
 */
- (void)stopAdView;

@end


