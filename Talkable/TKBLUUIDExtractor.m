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
    
    static NSTimeInterval lastExtrated;
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (now - lastExtrated < TKBLUUIDExtractorIntervalThreshold) return;
    lastExtrated = now;
    
    NSString* path = [NSString stringWithFormat:@"%@/public/%@/extract_uuid/%@.html", server, siteSlug, appSchema];
    NSURL* url = [NSURL URLWithString:path];
    
    SFSafariViewController* safariVC = [[SFSafariViewController alloc] initWithURL:url];
    safariVC.delegate = self;
    safariVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    safariVC.view.alpha = 0.0;
    
    [self incRetain]; // make object as delegate be alive unless safariVC dismissed
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIViewController currentViewController] presentViewController:safariVC animated:NO completion:nil];
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
    [safariVC dismissViewControllerAnimated:NO completion:nil];
    [self decRetain];
}

#pragma mark - [SFSafariViewControllerDelegate]

- (void)safariViewController:(SFSafariViewController*)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully {
    [self performSelector:@selector(dismissSafariViewController:) withObject:controller afterDelay:0.0];
}

@end
