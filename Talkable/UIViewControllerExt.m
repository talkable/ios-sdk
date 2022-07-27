//
//  UIViewControllerExt.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 06.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import "UIViewControllerExt.h"
#import "TKBLHelper.h"

@implementation UIViewController (TKBLExtension)

+ (nullable UIViewController*)currentViewController {
    UIWindow* keyWindow = [TKBLHelper keyWindow];
    if (!keyWindow) {
        return nil;
    }

	UIViewController* rootViewController = [keyWindow rootViewController];
	
	UINavigationController* navigationController = [rootViewController isKindOfClass:[UINavigationController class]]
		? (UINavigationController*)rootViewController
		: rootViewController.navigationController;
	
	UIViewController* visibleViewController = navigationController ? [navigationController visibleViewController] : rootViewController;
	
	UIViewController* presentedViewController = [visibleViewController respondsToSelector:@selector(presentedViewController)]
		? [visibleViewController presentedViewController]
		: nil;
	
	return presentedViewController ? presentedViewController : visibleViewController;
}

@end

@implementation UIViewController (TKBLExtensionActivityIndicator)

- (void)startFullViewActivity {
	UIView*	activityView = [self.view viewWithTag:VIEW_CONTROLLER_ACTIVITY_VIEW_TAG];
	if (!activityView) {
		activityView = [[UIView alloc] initWithFrame:self.view.bounds];
		activityView.tag = VIEW_CONTROLLER_ACTIVITY_VIEW_TAG;
		activityView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
		activityView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
        UIActivityIndicatorView* activityIndicator = nil;
        if (@available(iOS 13, *)) {
            activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
            activityIndicator.color = [UIColor whiteColor];
        } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_13_0
            activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
#endif  // __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_13_0
        }

		activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		activityIndicator.center = CGPointMake(CGRectGetMidX(activityView.bounds), CGRectGetMidY(activityView.bounds));
		[activityView addSubview:activityIndicator];
		[activityIndicator startAnimating];
	}
	[activityView setFrame:self.view.bounds];
	[self.view addSubview:activityView];
}

- (void)stopFullViewActivity {
	UIView*	activityView = [self.view viewWithTag:VIEW_CONTROLLER_ACTIVITY_VIEW_TAG];
	[activityView removeFromSuperview];
}

- (void)validateFullViewActivity {
	if ([self needsFullViewActivity]) {
		[self startFullViewActivity];
	}
	else {
		[self stopFullViewActivity];
	}
}

- (BOOL)needsFullViewActivity {
	return NO;
}

@end
