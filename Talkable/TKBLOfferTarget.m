//
//  TKBLOfferTarget.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 08.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import <MessageUI/MessageUI.h>

#import "TKBLOfferTarget.h"
#import "Talkable.h"
#import "TKBLHelper.h"
#import "TKBLSmsWatcher.h"
#import "TKBLContactsLoader.h"
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

- (void)tkblShareOfferViaSms:(NSDictionary*)params sender:(id)sender {
    if (![MFMessageComposeViewController canSendText]) {
        TKBLLog(@"Current device does'nt support SMS sending'", nil);
        [self publishFeaturesInfo:sender];
        return;
    }
    
    NSString* message = [params objectForKey:TKBLShareMessage];
    if (!message) {
        message = [NSString string];
    }
    
    NSString* claimURL = [params objectForKey:TKBLOfferClaimUrlKey];
    if (claimURL && ![message containsString:claimURL]) {
        message = [NSString stringWithFormat:@"%@ %@", message, claimURL];
    }
    
    id recipients = [params objectForKey:TKBLShareRecipients];
    NSArray* recipientsList = nil;
    if (recipients) {
        if ([recipients isKindOfClass:[NSArray class]]) {
            recipientsList = recipients;
        } else if ([recipients isKindOfClass:[NSString class]]) {
            recipientsList = [(NSString*)recipients componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",;"]];
        }
    }
    
    MFMessageComposeViewController* controller = [[MFMessageComposeViewController alloc] init];
    [controller setBody:message];
    if (recipientsList) {
        [controller setRecipients:recipientsList];
    }
    
    TKBLSmsWatcher* watcher = [[TKBLSmsWatcher alloc] init];
    watcher.successCompletionHandler = ^(void){
        [(UIWebView*)sender stringByEvaluatingJavaScriptFromString:@"Talkable.shareSucceeded('native_sms');"];
    };
    controller.messageComposeDelegate = watcher;
    [[UIViewController currentViewController] presentViewController:controller animated:YES completion:nil];
}

- (void)tkblPutToClipboard:(NSDictionary*)params sender:(id)sender {
    NSString* text = [params objectForKey:TKBLClipboardTextKey];
    if (text) {
        UIPasteboard* pasteBoard = [UIPasteboard generalPasteboard];
        pasteBoard.persistent = YES;
        [pasteBoard setString:text];
    } else {
        TKBLLog(@"Specify URL for key '%@'", TKBLClipboardTextKey);
    }
}

- (void)tkblImportContacts:(NSDictionary*)params sender:(id)sender {
    [[TKBLContactsLoader loader] loadContactsWithComplitionHandler:^(NSArray* contacts) {
        TKBLLog(@"Imported contacts - %@", contacts);
        NSData* data = [NSJSONSerialization dataWithJSONObject:@{@"contacts":contacts} options:0 error:nil];
        NSString* json =  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([json length] > 0) {
            NSString* script = [NSString stringWithFormat:@"Talkable.publish('contacts_imported', %@)", json];
            [(UIWebView*)sender stringByEvaluatingJavaScriptFromString:script];
        }
    }];
}

- (void)tkblGetNativeSupport:(NSDictionary*)params sender:(id)sender {
    [self publishFeaturesInfo:sender];
}

#pragma mark - [UIWebViewDelegate]

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if ([[[request URL] scheme] isEqualToString:TKBL_CROSS_REQUEST_SCHEMA]) {
        NSString* jsonQueue = [webView stringByEvaluatingJavaScriptFromString:@"Talkable.popNativeMobileEvents();"];
        
        NSArray* events = [self parseEventsQueue:jsonQueue];
        [events enumerateObjectsUsingBlock:^(id event, NSUInteger idx, BOOL *stop) {
            if ([event isKindOfClass:[NSDictionary class]]) {
                NSString* message       = [event objectForKey:TKBLMessageNameKey];
                NSDictionary* params    = [event objectForKey:TKBLMessageDataKey];
                if (message) {
                    [self notifyMessage:message withParams:params sender:webView];
                    [self proccessMessage:message withParams:params sender:webView];
                }
            }

        }];
        
        return NO;
    }
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked &&
        ![self isAnchorNavigation:webView.request.URL to:request.URL]) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    
    return YES;
}

#pragma mark - [Private]

- (BOOL)isAnchorNavigation:(NSURL*)currentURL to:(NSURL*)requestedURL {
    return [[self urlStringWithoutAnchor:currentURL] isEqualToString:[self urlStringWithoutAnchor:requestedURL]];
}

- (NSString*)urlStringWithoutAnchor:(NSURL*)url {
    NSString* anchor = [NSString stringWithFormat:@"#%@", url.fragment];
    return [url.absoluteString stringByReplacingOccurrencesOfString:anchor withString:@""];
}

- (NSArray*)parseEventsQueue:(NSString*)jsonString {
    if (!jsonString || [jsonString length] == 0)
        return nil;
    
    NSData* jsonData = [[jsonString stringByRemovingPercentEncoding] dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData)
        return nil;
    
    NSError __autoreleasing *error = error;
    NSArray* queue = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    if (!error && [queue isKindOfClass:[NSArray class]]) {
        return queue;
    } else {
        TKBLLog(@"Invalid events queue %@ Error - %@", [jsonString stringByRemovingPercentEncoding], error);
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
    TKBLLog(@"publish message <%@>", message);
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithObject:message forKey:TKBLMessageNameKey];
    if (params) {
        TKBLLog(@"message params - %@", params);
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

- (void)publishFeaturesInfo:(id)recipient {
    NSDictionary* info = [TKBLHelper featuresInfo];
    NSData* data = [NSJSONSerialization dataWithJSONObject:info options:0 error:nil];
    NSString* json =  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString* script = [NSString stringWithFormat:@"Talkable.publish('native_support', %@)", json];
    [(UIWebView*)recipient stringByEvaluatingJavaScriptFromString:script];
}

- (void)shareViaLinkWithParams:(NSDictionary*)params andSender:(id)sender {
    NSMutableArray* activityItems = [NSMutableArray array];
    
    NSString* message = [params objectForKey:TKBLShareMessage];
    if (message) {
        [activityItems addObject:message];
    }
    
    NSString* claimURL = [params objectForKey:TKBLOfferClaimUrlKey];
    if (claimURL) {
        [activityItems addObject:[NSURL URLWithString:claimURL]];
    }
    
    if ([activityItems count] == 0) return;
    
    UIActivityViewController* controller = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    
    [controller setCompletionWithItemsHandler:^(NSString* activityType, BOOL completed, NSArray* returnedItems, NSError*activityError) {
        if (!completed) return;
        [(UIWebView*)sender stringByEvaluatingJavaScriptFromString:@"Talkable.shareSucceeded('other');"];
        
    }];
    
    [controller setExcludedActivityTypes:@[UIActivityTypePostToFacebook, UIActivityTypePostToTwitter]];
    
    [[UIViewController currentViewController] presentViewController:controller animated:YES completion:nil];
}

- (SLComposeViewController*)shareController:(NSString*)channel {
    NSString* mappedChannel = [[self channelMap] objectForKey:channel];
    return [SLComposeViewController composeViewControllerForServiceType:mappedChannel];
}

- (NSDictionary*)channelMap {
    return @{TKBLShareChannelTwitter: SLServiceTypeTwitter, TKBLShareChannelFacebook: SLServiceTypeFacebook};
}

@end
