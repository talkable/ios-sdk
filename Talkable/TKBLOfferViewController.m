//
//  TKBLOfferViewController.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 07.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import "TKBLOfferViewController.h"
#import "TKBLOfferTarget.h"
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

#pragma mark - [UIWebViewDelegate]

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    return [super webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
}

- (void)webViewDidStartLoad:(UIWebView*)webView {
    [self validateFullViewActivity];
}

- (void)webViewDidFinishLoad:(UIWebView*)webView; {
    _requestCompleted = YES;
    [self validateFullViewActivity];
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
    if (!_requestCompleted) {
        TKBLLog(@"Request has failed with error - %@", error);
        [self close:webView];
    }
    _requestCompleted = YES;
    [self validateFullViewActivity];
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
            UIWebView* webView = (UIWebView*)ntf.object;
            NSString* title = [webView stringByEvaluatingJavaScriptFromString:@"Talkable.configuration('page_title');"];
            [self setTitle: title];
        }
    }
}

@end
