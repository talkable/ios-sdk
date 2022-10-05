//
//  TKBLOfferViewController.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 07.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import "TKBLOfferViewController.h"
#import "TKBLOfferTarget.h"
#import "TKBLHelper.h"
#import "UIViewControllerExt.h"

@implementation TKBLOfferViewController {
    BOOL        _requestCompleted;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([[Talkable manager].delegate respondsToSelector:@selector(titleForTalkableOfferViewController:)]) {
        [self setTitle: [[Talkable manager].delegate titleForTalkableOfferViewController:self]];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publishMessageNotification:) name:TKBLDidPublishMessageNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TKBLDidPublishMessageNotification object:nil];
    [super viewDidDisappear:animated];
}

#pragma mark - [IBActions]

- (IBAction)close:(id)sender {
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - [Private]

- (BOOL)needsFullViewActivity {
    return !_requestCompleted;
}

- (void)didFailNavigation:(WKWebView*)webView withError:(NSError*)error {
    if (!_requestCompleted) {
        TKBLLog(@"Request has failed with error - %@", error);
        [self close:webView];
    }
    _requestCompleted = YES;
    [self validateFullViewActivity];
}

#pragma mark - [WKNavigationDelegate]

- (void)webView:(WKWebView*)webView didStartProvisionalNavigation:(WKNavigation*)navigation {
    [self validateFullViewActivity];
}

- (void)webView:(WKWebView*)webView didFailProvisionalNavigation:(WKNavigation*)navigation withError:(NSError*)error {
    [self didFailNavigation:webView withError:error];    
}

- (void)webView:(WKWebView*)webView didFinishNavigation:(WKNavigation*)navigation {
    _requestCompleted = YES;
    [self validateFullViewActivity];
}

- (void)webView:(WKWebView*)webView didFailNavigation:(WKNavigation*)navigation withError:(NSError*)error {
    [self didFailNavigation:webView withError:error];
}

- (void)webView:(WKWebView*)webView decidePolicyForNavigationAction:(WKNavigationAction*)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        NSURL *url = navigationAction.request.URL;
        UIApplication *app = [UIApplication sharedApplication];
        if (![self isAnchorNavigation:webView.URL to:url] && [app canOpenURL:url]) {
            [TKBLHelper openURL:url];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - [Notifications]

- (void)publishMessageNotification:(NSNotification*)ntf {
    if ([[[ntf userInfo] objectForKey:TKBLMessageNameKey] isEqualToString:TKBLMessageOfferClose]) {
        [self close:nil];
    }
    if ([[[ntf userInfo] objectForKey:TKBLMessageNameKey] isEqualToString:TKBLMessageOfferLoaded]) {
        if ([[Talkable manager].delegate respondsToSelector:@selector(titleForTalkableOfferViewController:)]) {
            [self setTitle: [[Talkable manager].delegate titleForTalkableOfferViewController:self]];
        } else {
            WKWebView* webView = (WKWebView*)ntf.object;
            [webView evaluateJavaScript:@"Talkable.configuration('page_title');" completionHandler:^(NSString* title, NSError* error) {
                if (!error) {
                    [self setTitle: title];
                }
            }];
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

@end
