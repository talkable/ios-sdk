//
//  TKBLFBSharingWatcher.m
//  TalkableSDK
//
//  Created by Michael Gryshchenko on 7/24/19.
//  Copyright © 2019 Talkable. All rights reserved.
//

#import "TKBLFBSharingWatcher.h"

@implementation TKBLFBSharingWatcher {
    __strong TKBLFBSharingWatcher*  _retained;
}

@synthesize successCompletionHandler = successCompletionHandler;

-(instancetype)init {
    self = [super init];
    if (self) {
        _retained = self;
    }
    return self;
}

- (void)sharer:(id)sharer didCompleteWithResults:(NSDictionary<NSString *, id> *)results {
    successCompletionHandler();
    _retained = nil;
}

- (void)sharer:(id)sharer didFailWithError:(NSError *)error {
    _retained = nil;
}

- (void)sharerDidCancel:(id)sharer {
    _retained = nil;
}

@end
