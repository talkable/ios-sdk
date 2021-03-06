//
//  TKBLOfferTarget.h
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 08.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface TKBLOfferTarget: NSObject <WKScriptMessageHandler>

- (id)initWithWebView:(WKWebView*)webView;

- (BOOL)isUsed;

@end
