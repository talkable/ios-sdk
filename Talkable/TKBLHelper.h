//
//  TKBLHelper.h
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 29.07.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TKBLHelper : NSObject

+ (NSString* _Nullable)currentAppVersion;

+ (BOOL)wasAppUpdated;

+ (void)registerInstall;
+ (BOOL)installRegistered;

+ (NSDictionary* _Nonnull)featuresInfo;

+ (BOOL)isFacebookMessengerInstalled;
+ (BOOL)isWhatsAppInstalled;
+ (BOOL)isFacebookSharingUsingSocialFrameworkAvailable;

+ (UIViewController* _Nullable)topMostController;
+ (UIWindow* _Nullable)keyWindow;
+ (void)openURL:(NSURL* _Nonnull)url;

@end
