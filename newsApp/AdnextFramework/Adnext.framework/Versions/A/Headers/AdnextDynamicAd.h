//
//  AdnextDynamicAd.h
//  Adnext
//
//  Created by mars on 12/07/2019.
//  Copyright © 2019 mocoplex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AdnextDynamicAdState){
    
    AdnextDynamicAdStateRequestStart        = 1000,        //요청 시작
    AdnextDynamicAdStateReceivedAd          = 1001,        //광고 응답 성공
    
    AdnextDynamicAdStateSetViewHidden       = 9998,         //광고뷰 속성 hidden YES로 변경되는 상태를 알림
    AdnextDynamicAdStateSetViewVisible      = 9999,         //광고뷰 속성 hidden NO로 변경되는 상태를 알림
    
    AdnextDynamicAdStateResponseEmptyAd     = -1002,        //광고 응답 실패 - 광고 없음
    
    AdnextDynamicAdStateNetworkError        = -1003,        //요청 네트워크 에러
    AdnextDynamicAdStateRequestFailed       = -1004,        //요청 실패
    AdnextDynamicAdStateResponseFailed      = -1005,        //요청 응답 실패
    AdnextDynamicAdStateNotFoundImageSource = -1006,        //광고 응답 실패 - 이미지 리소를 찾을 수 없음
    AdnextDynamicAdStateSessionError        = -1007,        //광고 요청 실패 - 세션 에러
    AdnextDynamicAdStateNotFoundAdmSource   = -1008,        //광고 응답 실패 - 광고 소스 에러
    AdnextDynamicAdStateInvalidKey          = -1009,        //광고 요청 실패 - 유효하지 않은 요청 키
    AdnextDynamicAdStateSessionLinkError    = -1010,        //광고 요청 실패 - 세션 연결 실패
    AdnextDynamicAdStateWebLoadFailed       = -1011,        //광고 요청 실패 - 웹 로딩 실패
    
    AdnextDynamicAdStateEmptySchedule       = -1012,        //광고 요청 실패 - 애드넥스트 스케쥴 사용시 스케쥴 미포함
    AdnextDynamicAdStateInvalidSchedule     = -1013,        //광고 요청 실패 - 애드넥스트 스케쥴 사용시 스케쥴 설정 오류
    
    AdnextDynamicAdStateServerInternalError = -4444,        //광고 요청 실패 - 게이트웨이서버 내부에러코드 발생.
};


@class AdnextDynamicAd;

@protocol AdnextDynamicAdDelegate <NSObject>

- (void)adnextDynamicAdDidReceivedAd:(AdnextDynamicAd *)dynamicBanner;
- (void)adnextDynamicAd:(AdnextDynamicAd *)dynamicBanner didFailedAdWithState:(AdnextDynamicAdState)state;

@end

// 구버전 클래스명 : ALDynamicAd
@interface AdnextDynamicAd : NSObject {
    
}

@property (nonatomic) BOOL isTestMode; //default : NO
@property (nonatomic, strong, readonly) NSError *internalError;

/**
 *  애드넥스트 키값으로 초기화합니다.
 *  애드넥스트 설정 세션 연결은 내부적으로 처리됩니다.
 */
- (id)initWithKey:(NSString *)key
      contentSize:(CGSize)size
         delegate:(id<AdnextDynamicAdDelegate>)delegate;


// 띠 배너 요청
- (BOOL)loadRequestBanner;

// 전면 배너 요청
- (BOOL)loadRequestInterstitial;

// 광고 요청 취소
- (void)cancelAdRequest;


// 배너 뷰 화면에 노출 처리
- (void)attachToView:(UIView *)adContainerView;


// 배너 뷰 화면에서 제거 처리
- (void)detachFromContainerView;


// 배너 뷰의 프레임을 재조정할 필요가 있을 경우 호출
- (void)needLayoutSubviews:(CGRect)frame;


// 전면 배너를 모달뷰로 사용 시 노출 처리
- (void)presentAdWithParentViewController:(UIViewController *)ctr
                                 animated:(BOOL)animate;


+ (NSString *)logForBannerState:(AdnextDynamicAdState)state;

@end
