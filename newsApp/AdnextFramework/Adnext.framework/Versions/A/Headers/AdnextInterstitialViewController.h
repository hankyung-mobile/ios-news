//
//  ALAdInterstitialViewController.h
//  AdnextSDK
//
//  Created by mocoplex on 2015. 1. 15..
//  Copyright (c) 2015년 mocoplex. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AdnextBannerEvent;
@class AdnextInterstitialViewController;
@class ADNextSession;

@protocol AdnextInterstitialControllerDelegate <NSObject>

- (void)adnextInterstitialControllerDismiss:(AdnextInterstitialViewController *)controller;
- (void)adnextInterstitialControllerDidClicked:(AdnextInterstitialViewController *)controller;

@end

/**< 애드넥스트 전면광고 뷰 컨트롤러 */
@interface AdnextInterstitialViewController : UIViewController

- (instancetype)initWithBannerEvent:(AdnextBannerEvent *)bannerEvent
                            session:(ADNextSession *)session;

- (instancetype)initWithWebUrl:(NSURL *)webUrl;

@property (nonatomic, weak) id <AdnextInterstitialControllerDelegate>delegate;
@property (nonatomic, strong) UIColor *bgColor;

@end
