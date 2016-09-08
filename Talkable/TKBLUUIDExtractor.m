//
//  TKBLUUIDExtractor.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 06.01.16.
//  Copyright © 2016 Talkable. All rights reserved.
//

#import "TKBLUUIDExtractor.h"
#import "UIViewControllerExt.h"

NSTimeInterval const TKBLUUIDExtractorIntervalThreshold = 60.0;

@implementation TKBLUUIDExtractor {
    __strong NSMutableArray* _retaines;
}

+ (instancetype)extractor {
    return [[self alloc] init];
}

- (void)extractFromServer:(NSString*)server withSiteSlug:(NSString*)siteSlug andAppSchema:(NSString*)appSchema {
    // This method just makes initial request
    // uuid will be handled by [Talkable handleOpenURL:]
    
    if (![SFSafariViewController class]) {
        return; // SFSafariViewController supports starting from from iOS 9.0
    }
    
    static NSTimeInterval lastExtrated;
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (now - lastExtrated < TKBLUUIDExtractorIntervalThreshold) return;
    lastExtrated = now;
    
    NSString* path = [NSString stringWithFormat:@"%@/public/%@/extract_uuid/%@.html", server, siteSlug, appSchema];
    NSURL* url = [NSURL URLWithString:path];
    
    SFSafariViewController* safariVC = [[SFSafariViewController alloc] initWithURL:url];
    safariVC.delegate = self;
    safariVC.view.userInteractionEnabled = NO;
    safariVC.view.alpha = 0.0;
    
    [self incRetain]; // make object as delegate be alive unless safariVC dismissed
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController* currentController = [UIViewController currentViewController];
        [currentController addChildViewController: safariVC];
        [currentController.view addSubview: safariVC.view];
        [safariVC didMoveToParentViewController:currentController];
        safariVC.view.frame = CGRectZero;
    });
}

#pragma mark - [Private]

- (void)incRetain {
    if (!_retaines) {
        _retaines = [[NSMutableArray alloc] init];
    }
    [_retaines addObject:self];
}

- (void)decRetain {
    if ([_retaines count] > 0) {
        [_retaines removeObjectAtIndex:0];
    }
    if ([_retaines count] == 0) {
        _retaines = nil;
    }
}

- (void)dismissSafariViewController:(SFSafariViewController*)safariVC {
    [safariVC willMoveToParentViewController: nil];
    [safariVC.view removeFromSuperview];
    [safariVC removeFromParentViewController];
    [self decRetain];
}

#pragma mark - [SFSafariViewControllerDelegate]

- (void)safariViewController:(SFSafariViewController*)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully {
    [self performSelector:@selector(dismissSafariViewController:) withObject:controller afterDelay:0.0];
}

@end
