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
    UIButton*   _closeButton;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setTitle: NSLocalizedString(@"Talkable Offer", nil)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeActionNotification:) name:TKBLOfferDidSendCloseActionNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.view addSubview:[self closeBotton]];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[self closeBotton] removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TKBLOfferDidSendCloseActionNotification object:nil];
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

- (UIButton*)closeBotton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_closeButton setTitle:@"Dismiss Offer" forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
        
        [_closeButton sizeToFit];
        CGRect frame = _closeButton.frame;
        frame.origin = CGPointMake(self.view.bounds.size.width - frame.size.width - 12, 12);
        _closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        _closeButton.frame = frame;
    }
    return _closeButton;
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

- (void)closeActionNotification:(NSNotificationCenter*)ntf {
    [self close:nil];
}

@end
