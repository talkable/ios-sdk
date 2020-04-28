//
//  UIViewControllerExt.h
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 07.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import <UIKit/UIKit.h>

#define VIEW_CONTROLLER_ACTIVITY_VIEW_TAG	73197

@interface UIViewController (TKBLExtension)

+ (UIViewController*)currentViewController;

@end


@interface UIViewController (TKBLExtensionActivityIndicator)

// Start and stop full view activity indicator manually.
- (void)startFullViewActivity;
- (void)stopFullViewActivity;

- (void)validateFullViewActivity;	// Uses needsFullViewActivity to determine is full view activity needed.
- (BOOL)needsFullViewActivity;		// Override to validate full view activity. Default implementation returns NO.

@end
