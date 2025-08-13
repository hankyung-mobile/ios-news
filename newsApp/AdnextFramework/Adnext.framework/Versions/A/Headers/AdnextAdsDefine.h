//
//  AdnextAdsDefine.h
//  Adnext
//
//  Created by mars on 15/07/2019.
//  Copyright © 2019 mocoplex. All rights reserved.
//

#import <Foundation/Foundation.h>

//광고 AID 정의 타입
typedef NS_ENUM(NSInteger, ADNEXT_ADS_PTYPE) {
    
    ADNEXT_ADS_PTYPE_DEFAULT        = -100,
    ADNEXT_ADS_PTYPE_ADNEXT         = 7,    //Adnext
    ADNEXT_ADS_PTYPE_ADNEXTHOUSE    = 711,  //Adnext-House
};


typedef NS_ENUM(NSInteger, ADNEXT_ADS_STATE) {
    
    ADNEXT_ADS_STATE_INVALID_SUPERVIEW = -9999,
    ADNEXT_ADS_STATE_INVALID_APP_KEY,
    ADNEXT_ADS_STATE_INVALID_SESSION,
    ADNEXT_ADS_STATE_INVALID_SCHEDULE,
    ADNEXT_ADS_STATE_INVALID_PKEY,
    
    ADNEXT_ADS_STATE_STARTED = 0,
    ADNEXT_ADS_STATE_PREPARED,
    ADNEXT_ADS_STATE_STOPPED,
    
    ADNEXT_ADS_STATE_RECEIVED_AD,
    ADNEXT_ADS_STATE_FAILED_AD,
    ADNEXT_ADS_STATE_FAILED_ALL,
    ADNEXT_ADS_STATE_BANNER_CLICKED,
};


NS_ASSUME_NONNULL_BEGIN

@interface AdnextAdsDefine : NSObject

+ (NSString *)nameOfAdsPtype:(ADNEXT_ADS_PTYPE)ptype;
+ (NSString *)descriptionOfState:(ADNEXT_ADS_STATE)state;

@end

NS_ASSUME_NONNULL_END
