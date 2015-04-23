//
//  TKBLSmsWhatcher.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 22.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import "TKBLSmsWatcher.h"

@implementation TKBLSmsWatcher {
    __strong TKBLSmsWatcher* _retained;
}

@synthesize successCompletionHandler = _successCompletionHandler;

-(id)init {
    self = [super init];
    if (self) {
        _retained = self;
    }
    return self;
}

#pragma mark - [MFMessageComposeViewControllerDelegate]

- (void)messageComposeViewController:(MFMessageComposeViewController*)controller
                 didFinishWithResult:(MessageComposeResult)result {
    if (MessageComposeResultSent == result) {
        _successCompletionHandler();
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
    _retained = nil;
}

@end
