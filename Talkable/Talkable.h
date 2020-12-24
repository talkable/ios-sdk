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

@property (nonatomic, retain) NSString* _Nullable             apiKey;
@property (nonatomic, retain) NSString* _Nullable             siteSlug;
@property (nonatomic, retain) NSString* _Nullable             server;
@property (nonatomic, assign) id<TalkableDelegate> _Nullable  delegate;
@property (nonatomic, assign) BOOL                            debug;
@property (nonatomic, assign) BOOL                            skipFirstInstallCheck;
@property (nonatomic, assign) BOOL                            skipReinstallCheck;
@property (nonatomic, assign) BOOL                            ignoreStoredDeviceIdentity;
@property (nonatomic, assign) BOOL                            ignoreUrlScheme;

+ (Talkable* _Nullable)manager;

- (void)setApiKey:(NSString* _Nullable)apiKey andSiteSlug:(NSString* _Nullable)siteSlug;
- (void)setApiKey:(NSString* _Nullable)apiKey andSiteSlug:(NSString* _Nullable)siteSlug server:(NSString* _Nullable)server;

- (NSString* _Nullable)visitorUUID;
- (NSString* _Nullable)deviceIdentifier;

- (void)registerCoupon:(NSString* _Nullable)coupon;
- (NSString* _Nullable)coupon;

- (void)registerURLScheme:(NSString* _Nullable)urlScheme __deprecated;

#pragma mark - [Handlers]

- (BOOL)handleOpenURL:(NSURL* _Nullable)url;

- (BOOL)handleURLParams:(NSDictionary* _Nonnull)urlParams;

#pragma mark - [Integration]

- (void)registerOrigin:(TKBLOriginType)type params:(NSDictionary* _Nullable)params;

#pragma mark - [API]

- (void)createOrigin:(NSDictionary* _Nullable)params withHandler:(TKBLCompletionHandler _Nullable)handler;

- (void)retrieveRewardsWithHandler:(TKBLCompletionHandler _Nullable)handler;
- (void)retrieveRewards:(NSDictionary* _Nullable)params withHandler:(TKBLCompletionHandler _Nullable)handler;

- (void)retrieveOffer:(NSString* _Nullable)shortUrlCode withHandler:(TKBLCompletionHandler _Nullable)handler;
- (void)retrieveOffer:(NSString* _Nullable)shortUrlCode withParams:(NSDictionary* _Nullable)params andHandler:(TKBLCompletionHandler _Nullable)handler;

- (void)createShare:(NSString* _Nullable)shortUrlCode channel:(NSString* _Nullable)channel withHandler:(TKBLCompletionHandler _Nullable)handler __deprecated;
- (void)createShare:(NSString* _Nullable)shortUrlCode channel:(NSString* _Nullable)channel withParams:(NSDictionary* _Nullable)params andHandler:(TKBLCompletionHandler _Nullable)handler __deprecated;

- (void)createSocialShare:(NSString* _Nullable)shortUrlCode channel:(NSString* _Nullable)channel withHandler:(TKBLCompletionHandler _Nullable)handler;
- (void)createSocialShare:(NSString* _Nullable)shortUrlCode channel:(NSString* _Nullable)channel withParams:(NSDictionary* _Nullable)params andHandler:(TKBLCompletionHandler _Nullable)handler;

- (void)createEmailShare:(NSString* _Nullable)shortUrlCode recipients:(NSString* _Nullable)recipients withHandler:(TKBLCompletionHandler _Nullable)handler;
- (void)createEmailShare:(NSString* _Nullable)shortUrlCode recipients:(NSString* _Nullable)recipients withParams:(NSDictionary* _Nullable)params andHandler:(TKBLCompletionHandler _Nullable)handler;

#pragma mark - [Sharing]

- (SLComposeViewController* _Nullable)socialShare:(NSDictionary* _Nullable)params __deprecated;
- (UIActivityViewController* _Nullable)nativeShare:(NSDictionary* _Nullable)params;

@end
