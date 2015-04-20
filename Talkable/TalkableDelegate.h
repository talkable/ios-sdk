//
//  TalkableDelegate.h
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 09.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import <Social/Social.h>
#import "TKBLTypes.h"

@protocol TalkableDelegate <NSObject>

@optional

- (void)didRegisterOrigin:(TKBLOriginType)type withURL:(NSURL*)url;
- (void)didRegisterOrigin:(TKBLOriginType)type withWebView:(UIWebView*)webView;

- (BOOL)shouldPresentTalkableOfferViewController:(UIViewController*)controller;
- (UIViewController*)viewControllerForPresentingTalkableOfferViewController;

@end
