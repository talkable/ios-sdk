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

#pragma mark - [Talkable Messages]

- (void)tkblShareOfferViaFacebook:(NSDictionary*)params sender:(id)sender {
    [self shareViaChannel:TKBLShareChannelFacebook withParams:params andSender:sender];
}

- (void)tkblShareOfferViaTwitter:(NSDictionary*)params sender:(id)sender {
    [self shareViaChannel:TKBLShareChannelTwitter withParams:params andSender:sender];
}

#pragma mark - [UIWebViewDelegate]

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if ([[[request URL] scheme] isEqualToString:TKBL_CROSS_REQUEST_SCHEMA]) {
        NSString* message    = [self messageFromURL:[request URL]];
        NSDictionary* params = [self paramsFromURL:[request URL]];
        
        if (message) {
            [self notifyMessage:message withParams:params sender:webView];
            [self proccessMessage:message withParams:params sender:webView];
        }
        
        return NO;
    }
    return YES;
}

#pragma mark - [Private]

- (NSString*)messageFromURL:(NSURL*)url {
    NSString* message = [url host];
    if (!message) {
        message = [url path];
    }
    return message;
}

- (NSDictionary*)paramsFromURL:(NSURL*)url {
    NSString* query = [url query];
    return [self parseQuery:query];
}

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
    if (!query || [query length] == 0)
        return nil;
    
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

- (SEL)selectorFromMessage:(NSString*)message {
    NSMutableArray* messageComponents = [NSMutableArray array];
    [[message componentsSeparatedByString:@"_"] enumerateObjectsUsingBlock:^(NSString* obj, NSUInteger idx, BOOL* stop){
        [messageComponents addObject:[obj capitalizedString]];
    }];
    SEL msgSelector = NSSelectorFromString([NSString stringWithFormat:@"tkbl%@:sender:", [messageComponents componentsJoinedByString:@""]]);
    
    return msgSelector;
}

- (void)notifyMessage:(NSString*)message withParams:(NSDictionary*)params sender:(id)sender {
    TKBLLog(@"publish message <%@>", message)
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithObject:message forKey:TKBLMessageNameKey];
    if (params) {
        TKBLLog(@"message params - %@", params)
        [userInfo setValue:params forKey:TKBLMessageParamsKey];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TKBLDidPublishMessageNotification
                                                        object:sender
                                                      userInfo:userInfo];
}

- (void)proccessMessage:(NSString*)message withParams:(NSDictionary*)params sender:(id)sender {
    SEL msgSelector = [self selectorFromMessage:message];
    if ([self respondsToSelector:msgSelector]) {
        //[self performSelector:msgSelector withObject:query withObject:webView];
        // more complex implementation to prevent warning
        IMP imp = [self methodForSelector:msgSelector];
        void (*func)(id, SEL, NSDictionary*, id) = (void*)imp;
        func(self, msgSelector, params, sender);
        
    }
}

- (void)shareViaChannel:(NSString*)channel withParams:(NSDictionary*)params andSender:(id)sender {
    if (!params)
        return;

    SLComposeViewController* shareController  = [self shareController:channel];
    
    NSString* claimURL = [params objectForKey:TKBLOfferClaimUrlKey];
    if (claimURL) {
        [shareController addURL:[NSURL URLWithString:claimURL]];
    }
    
    NSString* message = [params objectForKey:TKBLShareMessage];
    if (message) {
        [shareController setInitialText:message];
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
