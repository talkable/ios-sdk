//
//  TKBLOfferChecker.h
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 01.03.16.
//  Copyright © 2016 Talkable. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

typedef void (^TKBLOfferExistingHandler)(BOOL isExist, NSString* localizedErrorMessage);

@interface TKBLOfferChecker : NSObject <WKNavigationDelegate>

- (void)performWithHTMLString:(NSString*)htmlString baseURL:(NSURL*)baseURL callback:(TKBLOfferExistingHandler)callback;

@end
