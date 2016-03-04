//
//  TKBLTypes.h
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 09.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

typedef NS_ENUM(NSUInteger, TKBLOriginType) {
    TKBLAffiliateMember = 0,
    TKBLPurchase,
    TKBLEvent
};

typedef NS_ENUM(NSUInteger, TKBLError) {
    TKBLNetworkError        = 1000,
    TKBLApiError            = 1001,
    TKBLRequestError        = 1002,
    TKBLCampaignError       = 1003
};

extern NSString* const UIImageDownloadErrorDomain;
typedef void (^TKBLCompletionHandler)(NSDictionary* result, NSError* error);
