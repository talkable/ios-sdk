//
//  Talkable.h
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 06.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <Social/Social.h>
#import "TalkableDelegate.h"
#import "TKBLConstants.h"

#define TKBLLog(format, ...)		[[Talkable manager] debug] ? NSLog([@"[Talkable]: " stringByAppendingString:format], ##__VA_ARGS__) : nil

@interface Talkable : NSObject

@property (nonatomic, retain) NSString*             apiKey;
@property (nonatomic, retain) NSString*             siteSlug;
@property (nonatomic, retain) NSString*             server;
@property (nonatomic, assign) id<TalkableDelegate>  delegate;
@property (nonatomic, assign) BOOL                  debug;

+ (Talkable*)manager;

- (void)setApiKey:(NSString*)apiKey andSiteSlug:(NSString*)siteSlug;
- (void)setApiKey:(NSString*)apiKey andSiteSlug:(NSString*)siteSlug server:(NSString*)server;

- (NSString*)visitorUUID;
- (NSString*)deviceIdentifier;

- (void)registerCoupon:(NSString*)coupon;
- (NSString*)coupon;

- (void)registerURLScheme:(NSString*)urlScheme __deprecated;

#pragma mark - [Handlers]

- (BOOL)handleOpenURL:(NSURL*)url;

- (BOOL)handleURLParams:(NSDictionary* _Nonnull)urlParams;

#pragma mark - [Integration]

- (void)registerOrigin:(TKBLOriginType)type params:(NSDictionary*)params;

#pragma mark - [API]

- (void)createOrigin:(NSDictionary*)params withHandler:(TKBLCompletionHandler)handler;

- (void)retrieveRewardsWithHandler:(TKBLCompletionHandler)handler;
- (void)retrieveRewards:(NSDictionary*)params withHandler:(TKBLCompletionHandler)handler;

- (void)retrieveOffer:(NSString*)shortUrlCode withHandler:(TKBLCompletionHandler)handler;
- (void)retrieveOffer:(NSString*)shortUrlCode withParams:(NSDictionary*)params andHandler:(TKBLCompletionHandler)handler;

- (void)createShare:(NSString*)shortUrlCode channel:(NSString*)channel withHandler:(TKBLCompletionHandler)handler __deprecated;
- (void)createShare:(NSString*)shortUrlCode channel:(NSString*)channel withParams:(NSDictionary*)params andHandler:(TKBLCompletionHandler)handler __deprecated;

- (void)createSocialShare:(NSString*)shortUrlCode channel:(NSString*)channel withHandler:(TKBLCompletionHandler)handler;
- (void)createSocialShare:(NSString*)shortUrlCode channel:(NSString*)channel withParams:(NSDictionary*)params andHandler:(TKBLCompletionHandler)handler;

- (void)createEmailShare:(NSString*)shortUrlCode recipients:(NSString*)recipients withHandler:(TKBLCompletionHandler)handler;
- (void)createEmailShare:(NSString*)shortUrlCode recipients:(NSString*)recipients withParams:(NSDictionary*)params andHandler:(TKBLCompletionHandler)handler;

#pragma mark - [Sharing]

- (SLComposeViewController*)socialShare:(NSDictionary*)params;
- (UIActivityViewController*)nativeShare:(NSDictionary*)params;

@end
