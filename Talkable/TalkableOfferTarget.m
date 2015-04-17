//
//  TalkableOfferTarget.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 08.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import "TalkableOfferTarget.h"
#import "TalkableConstants.h"

#ifndef TKBL_CROSS_REQUEST_SCHEMA
    #define TKBL_CROSS_REQUEST_SCHEMA @"tkbl"
#endif

@implementation NSObject (TalkableOfferTarget)

#pragma mark - [Talkable Commands]

- (void)TKBLClose:(NSString*)query sender:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:TKBLOfferDidSendCloseActionNotification object:sender];
}

- (void)TKBLShareViaFacebook:(NSString*)query sender:(id)sender {
    [self shareViaChannel:TKBLShareChannelFacebook query:query sender:sender];
}

- (void)TKBLShareViaTwitter:(NSString*)query sender:(id)sender {
    [self shareViaChannel:TKBLShareChannelTwitter query:query sender:sender];
}

#pragma mark - [UIWebViewDelegate]

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if ([[[request URL] scheme] isEqualToString:TKBL_CROSS_REQUEST_SCHEMA]) {
        NSString* query = [[request URL] query];
        NSString* command = [[request URL] host];
        if (!command) {
            command = [[request URL] path];
        }
        if (command) {
            SEL commandSelector = [self selectorFromCommand:command];
            if ([self respondsToSelector:commandSelector]) {
                //[self performSelector:commandSelector withObject:query withObject:webView];
                // more complex implementation to prevent warning
                IMP imp = [self methodForSelector:commandSelector];
                void (*func)(id, SEL, NSString*, id) = (void*)imp;
                func(self, commandSelector, query, webView);
                
            }
        }
        return NO;
    }
    return YES;
}

#pragma mark - [Private]

- (NSDictionary*)parseQuery:(NSString*)query {
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    [[query componentsSeparatedByString:@"&"] enumerateObjectsUsingBlock:^(NSString* pair, NSUInteger idx, BOOL* stop){
        if (pair) {
            NSArray* pairComponents = [pair componentsSeparatedByString:@"="];
            NSString* name = [[pairComponents firstObject] stringByRemovingPercentEncoding];
            NSString* value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
            if ([pairComponents count] > 0) {
                [params setObject:value forKey:name];
            } else {
                [params setObject:@"" forKey:name];
            }
        }
    }];
    return [NSDictionary dictionaryWithDictionary:params];
}

- (SEL)selectorFromCommand:(NSString*)command {
    NSMutableArray* commandComponents = [NSMutableArray array];
    [[command componentsSeparatedByString:@"-"] enumerateObjectsUsingBlock:^(NSString* obj, NSUInteger idx, BOOL* stop){
        [commandComponents addObject:[obj capitalizedString]];
    }];
    SEL commandSelector = NSSelectorFromString([NSString stringWithFormat:@"TKBL%@:sender:", [commandComponents componentsJoinedByString:@""]]);
    
    return commandSelector;
}

- (void)shareViaChannel:(NSString*)channel query:(NSString*)query sender:(id)sender {
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithDictionary:[self parseQuery:query]];
    [userInfo setObject:channel forKey:TKBLShareChannel];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TKBLOfferDidSendShareActionNotification object:sender userInfo:userInfo];
}

@end
