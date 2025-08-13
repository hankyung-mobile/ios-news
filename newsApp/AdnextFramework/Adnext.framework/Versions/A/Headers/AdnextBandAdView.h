//
//  ALAdnextBannerView.h
//  Adnext
//
//  Created by gskang on 2016. 2. 25..
//  Copyright © 2016년 mocoplex. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AdnextBandAdState){
    
    //광고 요청 시작
    AdnextBandAdStateRequestStart = 0,
    
    //광고 수신 성공
    AdnextBandAdStateReceivedAd,
    
    //광고 없음
    AdnextBandAdStateResponseEmptyAd,
    
    //애드넥스트 스케쥴 설정에 애드넥스트 미포함 상태로 광고 요청이 불가능한 상태
    AdnextBandAdStateEmptyInSchedule,
    
    //광고요청 네트워크 에러
    AdnextBandAdStateNetworkError,
    
    //광고요청 실패
    AdnextBandAdStateRequestFailed,
    
    //광고응답 실패
    AdnextBandAdStateResponseFailed,
    
    //애드넥스트 설정 정보 요청실패
    AdnextBandAdStateSessionError,
    
    //광고에 필요한 리소스 수신실패
    AdnextBandAdStateNotFoundAdmSource,
    
    //광고키 에러
    AdnextBandAdStateInvalidKeyError,
    
    //광고뷰 로드 에러
    AdnextBandAdStateViewLoadError,
};


/**
 *  애드넥스트 네트워크 이미지 광고(띠배너)를 사용하기 위한 광고 뷰
 */
@interface AdnextBandAdView : UIView {
    
}

//테스트 모드 설정 값 (기본값 : NO)
@property (nonatomic) BOOL isTestMode;

//애드넥스트 하우스 광고여부 (기본값 : NO)
@property (nonatomic) BOOL isHouseMode;

//요청 타임아웃 (기본 : 1초)
@property (nonatomic) NSTimeInterval timeoutInterval;

//애드넥스트 광고 자동갱신 시간 적용 여부 (기본값: NO)
@property (nonatomic) BOOL autoRefresh;

//백그라운드 색상 지정, 미지정 시 광고에 포함된 색상값으로 노출 됨.
@property (nonatomic, strong) UIColor *bannerBackgroundColor;

//네트워크 등 최신 에러상태
@property (nonatomic, strong, readonly) NSError *error;

/**
 *  광고 요청 시작 메소드
 *  @param adnextKey 애드넥스트 키
 */
- (void)startAdRequestWithKey:(NSString *)adnextKey;

/**
 *  광고 요청 중지 메소드
 */
- (void)stopAdRequest;

/**
 *  광고 요청 상태 변경알림 블록 지정 메소드
 *
 *  @param handler 블럭 함수
 */
- (void)setRequestAdStateHandler:(void (^)(AdnextBandAdState state))handler;


/**
 *  광고 클릭 이벤트 블록 지정 메소드
 *
 *  @param handler 블럭 함수
 */
- (void)setBannerClickEvent:(void (^)(NSError *error))handler;

/**
 *  키 값에 해당하는 세션정보 값들을 모두 클리어한다.
 *  이후 startAdRequestWithKey: 메소드를 통해 키 설정값이 다시 로딩된다.
 */
+ (void)clearAllSharedSession;

/**
 *  Error Log 출력 설정
 */
+ (void)setLogging:(BOOL)logging;

/**
 *  ALAdnextBannerState 상태 코드 설명 문자열 반환 메소드
 */
+ (NSString *)logMessageForState:(AdnextBandAdState)state;

@end
