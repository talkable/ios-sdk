//
//  TKBLOfferTarget.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 08.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import "TKBLOfferTarget.h"
#import "Talkable.h"
#import "UIViewControllerExt.h"

#ifndef TKBL_CROSS_REQUEST_SCHEMA
    #define TKBL_CROSS_REQUEST_SCHEMA @"tkbl"
#endif

@implementation NSObject (TKBLOfferTarget)

#pragma mark - [Talkable Commands]

- (void)tkblClose:(NSDictionary*)params sender:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:TKBLOfferDidSendCloseActionNotification object:sender];
}

- (void)tkblShareViaFacebook:(NSDictionary*)params sender:(id)sender {
    [self shareViaChannel:TKBLShareChannelFacebook withParams:params andSender:sender];
}

- (void)tkblShareViaTwitter:(NSDictionary*)params sender:(id)sender {
    [self shareViaChannel:TKBLShareChannelTwitter withParams:params andSender:sender];
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
            TKBLLog(@"command <%@>", command);
            
            SEL commandSelector = [self selectorFromCommand:command];
            if ([self respondsToSelector:commandSelector]) {
                NSDictionary* params = [self parseQuery:query];
                //[self performSelector:commandSelector withObject:query withObject:webView];
                // more complex implementation to prevent warning
                IMP imp = [self methodForSelector:commandSelector];
                void (*func)(id, SEL, NSDictionary*, id) = (void*)imp;
                func(self, commandSelector, params, webView);
                
            }
        }
        return NO;
    }
    return YES;
}

#pragma mark - [Private]

- (NSDictionary*)parseQuery:(NSString*)query {
//    return [self parseHTTPQuery:query];
    return [self parseJSONQuery:query];
}

- (NSDictionary*)parseHTTPQuery:(NSString*)query {
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

- (NSDictionary*)parseJSONQuery:(NSString*)query {
    NSData* jsonData = [[query stringByRemovingPercentEncoding] dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData)
        return nil;
    
    NSError __autoreleasing *error = error;
    NSDictionary* params = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    if (!error && [params isKindOfClass:[NSDictionary class]]) {
        return params;
    } else {
        TKBLLog(@"Invalid params. %@", error);
        return nil;
    }
}

- (SEL)selectorFromCommand:(NSString*)command {
    NSMutableArray* commandComponents = [NSMutableArray array];
    [[command componentsSeparatedByString:@"-"] enumerateObjectsUsingBlock:^(NSString* obj, NSUInteger idx, BOOL* stop){
        [commandComponents addObject:[obj capitalizedString]];
    }];
    SEL commandSelector = NSSelectorFromString([NSString stringWithFormat:@"tkbl%@:sender:", [commandComponents componentsJoinedByString:@""]]);
    
    return commandSelector;
}

- (void)shareViaChannel:(NSString*)channel withParams:(NSDictionary*)params andSender:(id)sender {
    if (!params)
        return;

    SLComposeViewController* shareController  = [self shareController:channel];
    
    NSString* claimURL = [params objectForKey:TKBLOfferClaimUrlKey];
    if (claimURL) {
        [shareController addURL:[NSURL URLWithString:claimURL]];
    }
    
    NSString* title = [params objectForKey:TKBLShareTitle];
    if (title) {
        [shareController setInitialText:title];
    }
    
    [shareController setCompletionHandler:^(SLComposeViewControllerResult result) {
        if (result == SLComposeViewControllerResultDone) {
            [(UIWebView*)sender stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Talkable.shareSucceeded('%@');", channel]];
        }
    }];
    
    [[UIViewController currentViewController] presentViewController:shareController animated:YES completion:nil];
    
}

- (SLComposeViewController*)shareController:(NSString*)channel {
    NSString* mappedChannel = [[self channelMap] objectForKey:channel];
    return [SLComposeViewController composeViewControllerForServiceType:mappedChannel];
}

- (NSDictionary*)channelMap {
    return @{TKBLShareChannelTwitter: SLServiceTypeTwitter, TKBLShareChannelFacebook: SLServiceTypeFacebook};
}

@end
