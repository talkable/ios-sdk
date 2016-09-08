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

- (void)performWithHTMLString:(NSString*)htmlString baseURL:(NSURL*)baseURL callback:(TKBLOfferExistingHandler)callback {
    WKWebView* webView = [[WKWebView alloc] init];
    webView.navigationDelegate = self;
    
    [self assignCallback:callback toWebView:webView];
    [self retainWebView:webView];
    
    [webView loadHTMLString:htmlString baseURL:baseURL];
}

#pragma mark - [Private]

- (void)assignCallback:(TKBLOfferExistingHandler)callback toWebView:(WKWebView*)webView {
    
    if (!_callbacks) {
        _callbacks = [NSMutableDictionary dictionary];
    }
    NSValue* key = [NSValue valueWithNonretainedObject:webView];
    [_callbacks setObject:callback forKey:key];
}

- (TKBLOfferExistingHandler)callbackForWebView:(WKWebView*)webView {
    NSValue* key = [NSValue valueWithNonretainedObject:webView];
    return [_callbacks objectForKey:key];
}

- (void)removeCallbackForWebView:(WKWebView*)webView {
    NSValue* key = [NSValue valueWithNonretainedObject:webView];
    [_callbacks removeObjectForKey:key];
}

- (void)retainWebView:(WKWebView*)webView {
    if (!_webViewHolder) {
        _webViewHolder = [NSMutableArray array];
    }
    [_webViewHolder addObject:webView];
}

- (void)releaseWebView:(WKWebView*)webView {
    [_webViewHolder removeObject:webView];
}

- (void)webView:(WKWebView*)webView didFailRequestWithError:(NSError*)error {
    TKBLOfferExistingHandler callback = [self callbackForWebView:webView];
    if (callback) {
        callback(NO, error.localizedDescription);
    }
    [self releaseWebView:webView];
    [self removeCallbackForWebView:webView];
}

- (void)webViewDidSuccessRequest:(WKWebView*)webView {
    TKBLOfferExistingHandler callback = [self callbackForWebView: webView];
    if (callback) {
        [webView evaluateJavaScript:@"Talkable.configuration('offer_short_code');" completionHandler:^(NSString* offerShortCode, NSError* error) {
            if (!error) {
                if ([offerShortCode length] > 0) {
                    callback(YES, nil);
                } else {
                    [webView evaluateJavaScript:@"Talkable.configuration('error_message');" completionHandler:^(NSString* errorMessage, NSError* error) {
                        if (error) {
                            callback(NO, error.localizedDescription);
                        } else {
                            callback(NO, NSLocalizedString(errorMessage, nil));
                        }
                    }];
                }
            }
        }];
    }
    [self releaseWebView:webView];
    [self removeCallbackForWebView:webView];
}

#pragma mark - [WKNavigationDelegate]

- (void)webView:(WKWebView*)webView didFailNavigation:(WKNavigation*)navigation withError:(NSError*)error {
    [self webView:webView didFailRequestWithError:error];
}

- (void)webView:(WKWebView*)webView didFailProvisionalNavigation:(WKNavigation*)navigation withError:(NSError*)error {
    [self webView:webView didFailRequestWithError:error];
}

- (void)webView:(WKWebView*)webView didFinishNavigation:(WKNavigation*)navigation {
    [self webViewDidSuccessRequest:webView];
}

@end
