//
//  AdnextSDK.h
//  Adnext
//
//  Created by mars on 11/07/2019.
//  Copyright © 2019 mocoplex. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * SDK version 1.0 / 2019.7.16 am 11:11 build
 *
 * 애드넥스트 전용 광고 뷰
 * 애드넥스트 플랫폼만 사용할 수 있는 이미지/웹뷰 광고 & 동영상전면 광고 제공 클래스
 */

//애드넥스트 네트워크 배너
#import <Adnext/AdnextNetworkAd.h> // 애드넥스트 이미지 & 비디오 전면광고
#import <Adnext/AdnextBandAdView.h> // (320 x 50) 규격 소재사이즈 띠배너뷰

// (Width x Height) 동적 소재사이즈 광고
#import <Adnext/AdnextDynamicAdView.h> // 애드넥스트 가변 width * height 이미지 광고뷰
#import <Adnext/AdnextDynamicBannerController.h> // 애드넥스트 전면광고 제공 기본 UIViewController


@interface AdnextSDK : NSObject

+ (NSString *)sdkVersion;

@end

