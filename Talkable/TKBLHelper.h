//
//  TKBLHelper.h
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 29.07.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TKBLHelper : NSObject

+ (NSString*)currentAppVersion;

+ (BOOL)wasAppUpdated;

+ (void)registerInstall;
+ (BOOL)installRegistered;

+ (NSDictionary*)featuresInfo;

+ (BOOL)isFacebookMessengerInstalled;
+ (BOOL)isWhatsAppInstalled;
+ (BOOL)isFacebookSharingUsingSocialFrameworkAvailable;

+ (UIViewController*) topMostController;

@end
