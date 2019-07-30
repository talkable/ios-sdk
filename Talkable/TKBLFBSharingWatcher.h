//
//  TKBLFBSharingWatcher.h
//  TalkableSDK
//
//  Created by Michael Gryshchenko on 7/24/19.
//  Copyright © 2019 Talkable. All rights reserved.
//

#import "Talkable.h"
#import "TKBLOfferTarget.h"
#import <UIKit/UIKit.h>

#ifndef TKBLFBSharingWatcher_h
#define TKBLFBSharingWatcher_h

@interface TKBLFBSharingWatcher : NSObject

@property (nonatomic, copy, nonnull) void (^successCompletionHandler)(void);

/**
 Sent to the delegate when the share completes without error or cancellation.
 @param sharer The FBSDKSharing that completed.
 @param results The results from the sharer.  This may be nil or empty.
 */
- (void)sharer:(id)sharer didCompleteWithResults:(NSDictionary<NSString *, id> *)results;

/**
 Sent to the delegate when the sharer encounters an error.
 @param sharer The FBSDKSharing that completed.
 @param error The error.
 */
- (void)sharer:(id)sharer didFailWithError:(NSError *)error;

/**
 Sent to the delegate when the sharer is cancelled.
 @param sharer The FBSDKSharing that completed.
 */
- (void)sharerDidCancel:(id)sharer;

@end

#endif /* TKBLFBSharingWatcher_h */
