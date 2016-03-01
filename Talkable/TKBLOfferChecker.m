//
//  TKBLOfferChecker.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 01.03.16.
//  Copyright © 2016 Talkable. All rights reserved.
//

#import "TKBLOfferChecker.h"

@implementation TKBLOfferChecker {
    NSMutableDictionary*    _callbacks;
    NSMutableArray*         _webViewHolder;
}

- (void)performWithContent:(NSData*)contentData MIMEType:(NSString*)MIMEType textEncodingName:(NSString*)textEncodingName baseURL:(NSURL*)baseURL callback:(TKBLOfferExistingHandler)callback {
    UIWebView* webView = [[UIWebView alloc] init];
    [webView setDelegate:self];
    [self assignCallback:callback toWebView:webView];
    [self retainWebView:webView];
    [webView loadData:contentData MIMEType:MIMEType textEncodingName:textEncodingName baseURL:baseURL];
}

#pragma mark - [Private]

- (void)assignCallback:(TKBLOfferExistingHandler)callback toWebView:(UIWebView*)webView {
    if (!_callbacks) {
        _callbacks = [NSMutableDictionary dictionary];
    }
    NSValue* key = [NSValue valueWithNonretainedObject:webView];
    [_callbacks setObject:callback forKey:key];
}

- (TKBLOfferExistingHandler)callbackForWebView:(UIWebView*)webView {
    NSValue* key = [NSValue valueWithNonretainedObject:webView];
    return [_callbacks objectForKey:key];
}

- (void)removeCallbackForWebView:(UIWebView*)webView {
    NSValue* key = [NSValue valueWithNonretainedObject:webView];
    [_callbacks removeObjectForKey:key];
}

- (void)retainWebView:(UIWebView*)webView {
    if (!_webViewHolder) {
        _webViewHolder = [NSMutableArray array];
    }
    [_webViewHolder addObject:webView];
}

- (void)releaseWebView:(UIWebView*)webView {
    [_webViewHolder removeObject:webView];
}

#pragma mark - [UIWebViewDelegate]

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError*)error {
    TKBLOfferExistingHandler callback = [self callbackForWebView: webView];
    if (callback) {
        callback(NO, error.localizedDescription);
    }
    [self releaseWebView:webView];
    [self removeCallbackForWebView:webView];
}

- (void)webViewDidFinishLoad:(UIWebView*)webView {
    TKBLOfferExistingHandler callback = [self callbackForWebView: webView];
    if (callback) {
        NSString* offerShortCode = [webView stringByEvaluatingJavaScriptFromString:@"Talkable.configuration('offer_short_code');"];
        if ([offerShortCode length] > 0) {
            callback(YES, nil);
        } else {
            NSString* errorMessage = [webView stringByEvaluatingJavaScriptFromString:@"Talkable.configuration('error_message');"];
            callback(NO, NSLocalizedString(errorMessage, nil));
        }
        
    }
    [self releaseWebView:webView];
    [self removeCallbackForWebView:webView];
}

@end
