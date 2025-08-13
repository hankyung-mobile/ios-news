//
//  AdnextManager.h
//  AdnextSDK
//
//  Created by mocoplex on 2015. 1. 12..
//  Copyright (c) 2015년 mocoplex. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const ADNextSessionDidFinishedLinkNotification;
extern NSString * const ADNextSessionDidFailedLinkNotification;

@class ADNextSession;

@protocol ADNextSessionDelegate <NSObject>

@optional

- (void)ADNextSession:(ADNextSession *)session didFinishedLinkWithUserInfo:(NSDictionary *)userInfo;
- (void)ADNextSession:(ADNextSession *)session didFailedLinkWithError:(NSError *)error;

@end


@interface ADNextSession : NSObject

@property (nonatomic, weak) id<ADNextSessionDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *appKey;

- (instancetype)initWithAdnextKey:(NSString *)appKey;
- (instancetype)initTestSessionWithAdnextKey:(NSString *)appKey;

- (instancetype)initWithAdnextKey:(NSString *)appKey configSession:(ADNextSession *)session;

- (void)linkSession;
- (NSDictionary *)appConfigurations;

+ (void)setDebugMode;

+ (ADNextSession *)sharedSessionForKey:(NSString *)key isTestMode:(BOOL)isTestMode;
+ (void)clearAllSharedSession;

@end
