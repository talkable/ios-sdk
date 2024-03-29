//
//  TKBLHelper.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 29.07.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import <Social/Social.h>

#import "Talkable.h"
#import "TKBLHelper.h"
#import "TKBLConstants.h"

NSString*   TKBLInstallRegisteredKey    = @"tkbl_install_registered";

@implementation TKBLHelper

+ (NSString* _Nullable)currentAppVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

+ (BOOL)wasAppUpdated {
    NSFileManager* manager = [NSFileManager defaultManager];
    NSURL *documentsDirRoot = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSDictionary* documentsDirAttributes = [manager attributesOfItemAtPath:documentsDirRoot.path error:nil];
    NSDate* creationDate = [documentsDirAttributes fileCreationDate];

    NSString* bundleRoot = [[NSBundle mainBundle] bundlePath];
    NSDictionary* bundleAttributes = [manager attributesOfItemAtPath:bundleRoot error:nil];
    NSDate* modificationDate = [bundleAttributes fileModificationDate];

    return ABS([modificationDate timeIntervalSinceDate:creationDate]) > 60;
}

+ (void)registerInstall {
    NSUserDefaults* pref = [NSUserDefaults standardUserDefaults];
    [pref setBool:YES forKey:TKBLInstallRegisteredKey];
    [pref synchronize];
}

+ (BOOL)installRegistered {
    NSUserDefaults* pref = [NSUserDefaults standardUserDefaults];
    return [pref boolForKey:TKBLInstallRegisteredKey];
}

+ (NSDictionary* _Nonnull)featuresInfo {
    return @{
        @"send_sms":                        [NSNumber numberWithBool:[self canSendSMS]],
        @"copy_to_clipboard":               [NSNumber numberWithBool:YES],
        @"share_via_native_mail":           [NSNumber numberWithBool:[self canSendNativeMail]],
        @"share_via_facebook":              [NSNumber numberWithBool:[self canShareViaFacebook]],
        @"share_via_twitter":               [NSNumber numberWithBool:[self isTwitterSharingImplemented]],
        @"share_via_facebook_messenger":    [NSNumber numberWithBool:[self isFacebookMessengerInstalled]],
        @"share_via_whatsapp":              [NSNumber numberWithBool:[self isWhatsAppInstalled]],
        @"sdk_version":                     TKBLVersion,
    };
}

+ (BOOL)isFacebookMessengerInstalled {
    UIApplication* app = [UIApplication sharedApplication];
    // In iOS 9 you must whitelist any URL schemes your App wants to query in Info.plist under the LSApplicationQueriesSchemes
    return [app canOpenURL:[NSURL URLWithString:@"fb-messenger://share"]];
}

+ (BOOL)isWhatsAppInstalled {
    UIApplication* app = [UIApplication sharedApplication];
    // In iOS 9 you must whitelist any URL schemes your App wants to query in Info.plist under the LSApplicationQueriesSchemes
    return [app canOpenURL:[NSURL URLWithString:@"whatsapp://send"]];
}

+ (BOOL)isFacebookSharingUsingSocialFrameworkAvailable {
    // [SLComposeViewController isAvailableForServiceType:] always returns false
    // but Facebook sharing still works if Facebook app is installed
    return [SLComposeViewController class] != nil &&
        [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fbauth2://"]];;
}

+ (UIViewController* _Nullable)topMostController {
    UIWindow *keyWindow = [self keyWindow];
    if (!keyWindow) {
        return nil;
    }

    UIViewController *topController = keyWindow.rootViewController;
    if (!topController) {
        return nil;
    }

    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }

    return topController;
}

+ (UIWindow* _Nullable)keyWindow {
    if (@available(iOS 15, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]] &&
                scene.activationState == UISceneActivationStateForegroundActive) {
                return ((UIWindowScene *)scene).keyWindow;
            }
        }
    } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_15_0
        if (@available(iOS 13, *)) {
            for (UIWindow *window in UIApplication.sharedApplication.windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
        } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_13_0
          return UIApplication.sharedApplication.keyWindow;
#endif  // __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_13_0
      }
#endif  // __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_15_0
    }
    TKBLLog(@"Unable to get keyWindow", nil);
    return nil;
}

+ (void)openURL:(NSURL* _Nonnull)url {
    if (@available(iOS 10, *)) {
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
    } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_10_0
        [UIApplication.sharedApplication openURL:url];
#endif  // __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_10_0
    }
}

#pragma mark - [Private]

+ (BOOL)canSendSMS {
    return [MFMessageComposeViewController class] != nil && [MFMessageComposeViewController canSendText];
}

+ (BOOL)canShareViaFacebook {
    return [self isFacebookSharingImplemented] || [self isFacebookSharingUsingSocialFrameworkAvailable];
}

+ (BOOL)isFacebookSharingImplemented {
    return [[Talkable manager].delegate respondsToSelector:@selector(showFacebookShareDialogWithParams:completion:)] ||
    [[Talkable manager].delegate respondsToSelector:@selector(showFacebookShareDialogWithParams:delegate:)];
}

+ (BOOL)isTwitterSharingImplemented {
    return [[Talkable manager].delegate respondsToSelector:@selector(showTwitterShareDialogWithParams:completion:)];
}

+ (BOOL)canSendNativeMail {
    return [MFMailComposeViewController class] != nil && [MFMailComposeViewController canSendMail];
}

@end
