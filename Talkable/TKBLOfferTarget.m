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

@implementation NSObject (TKBLOfferTarget)

#pragma mark - [Talkable Messages]

- (void)tkblShareOfferViaFacebook:(NSDictionary*)params sender:(id)sender {
    [self shareViaChannel:TKBLShareChannelFacebook withParams:params andSender:sender];
}

- (void)tkblShareOfferViaTwitter:(NSDictionary*)params sender:(id)sender {
    [self shareViaChannel:TKBLShareChannelTwitter withParams:params andSender:sender];
}

- (void)tkblShareOfferViaFacebookMessage:(NSDictionary*)params sender:(id)sender {
    if (![TKBLHelper isFacebookMessangerInstalled]) {
        TKBLLog(@"Facebook Messanger is not installed. Check http://docs.talkable.com/ios_sdk/getting_started.html#configuration for more details about using Facebook Messanger as a sharing channel.", nil);
        [self publishFeaturesInfo:sender];
        return;
    }
    
    // There is no way to pass a text to fb messanger, only an url.
    NSString* claimURL = [params objectForKey:TKBLOfferClaimUrlKey];
    NSString* escapedClaimURL = [claimURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    UIApplication* app = [UIApplication sharedApplication];
    
    // There is no way to check whether user shared a message or not
    [(UIWebView*)sender stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Talkable.shareSucceeded('%@');", TKBLShareChannelFacebookMessage]];
    [app openURL:[NSURL URLWithString:[NSString stringWithFormat:@"fb-messenger://share?link=%@", escapedClaimURL]]];
    
}

- (void)tkblShareOfferViaSms:(NSDictionary*)params sender:(id)sender {
    if (![MFMessageComposeViewController canSendText]) {
        TKBLLog(@"Current device does'nt support SMS sending", nil);
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
        NSString* script = [NSString stringWithFormat:@"Talkable.shareSucceeded('%@');", TKBLShareChannelSMS];
        [(WKWebView*)sender evaluateJavaScript:script completionHandler:nil];
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
            [(WKWebView*)sender evaluateJavaScript:script completionHandler:nil];
        }
    }];
}

- (void)tkblGetNativeSupport:(NSDictionary*)params sender:(id)sender {
    [self publishFeaturesInfo:sender];
}

#pragma mark - [WKNavigationDelegate]

- (void)webView:(WKWebView*)webView decidePolicyForNavigationAction:(WKNavigationAction*)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated &&
        ![self isAnchorNavigation:webView.URL to:navigationAction.request.URL]) {
        [[UIApplication sharedApplication] openURL:[navigationAction.request URL]];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - [WKScriptMessageHandler]

- (void)userContentController:(WKUserContentController*)userContentController didReceiveScriptMessage:(WKScriptMessage*)message {
    if ([message.body isKindOfClass:[NSDictionary class]]) {
        NSString* name          = [message.body objectForKey:TKBLMessageNameKey];
        NSDictionary* params    = [message.body objectForKey:TKBLMessageDataKey];
        if (name) {
            [self notifyMessage:name withParams:params sender:message.webView];
            [self proccessMessage:name withParams:params sender:message.webView];
        }
    }
}

#pragma mark - [Private]

- (BOOL)isAnchorNavigation:(NSURL*)currentURL to:(NSURL*)requestedURL {
    return [[self urlStringWithoutAnchor:currentURL] isEqualToString:[self urlStringWithoutAnchor:requestedURL]];
}

- (NSString*)urlStringWithoutAnchor:(NSURL*)url {
    NSString* anchor = [NSString stringWithFormat:@"#%@", url.fragment];
    return [url.absoluteString stringByReplacingOccurrencesOfString:anchor withString:@""];
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
    
    if ([SLComposeViewController class] == nil) {
        TKBLLog(@"Social.framework is not added to your project. Check http://docs.talkable.com/ios_sdk/getting_started.html for more details.", nil);
        [self publishFeaturesInfo:sender];
        return;
    }

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
            NSString* script = [NSString stringWithFormat:@"Talkable.shareSucceeded('%@');", channel];
            [(WKWebView*)sender evaluateJavaScript:script completionHandler:nil];
        }
    }];
    
    [[UIViewController currentViewController] presentViewController:shareController animated:YES completion:nil];
    
}

- (void)publishFeaturesInfo:(id)sender {
    NSDictionary* info = [TKBLHelper featuresInfo];
    NSData* data = [NSJSONSerialization dataWithJSONObject:info options:0 error:nil];
    NSString* json =  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString* script = [NSString stringWithFormat:@"Talkable.publish('native_support', %@)", json];
    [(WKWebView*)sender evaluateJavaScript:script completionHandler:nil];
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
        NSString* script = [NSString stringWithFormat:@"Talkable.shareSucceeded('%@');", TKBLShareChannelOther];
        [(WKWebView*)sender evaluateJavaScript:script completionHandler:nil];
        
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
