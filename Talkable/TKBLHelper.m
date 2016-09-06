//
//  TKBLHelper.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 29.07.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import <Social/Social.h>

#import "TKBLHelper.h"
#import "TKBLConstants.h"

NSString*   TKBLInstallRegisteredKey    = @"tkbl_install_registered";

@implementation TKBLHelper

+ (NSString*)currentAppVersion {
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

+ (NSDictionary*)featuresInfo {
    return @{
        @"send_sms":            [NSNumber numberWithBool:[self canSendSMS]],
        @"copy_to_clipboard":   [NSNumber numberWithBool:YES],
        @"share_via_facebook":  [NSNumber numberWithBool:[self canShareVia:SLServiceTypeFacebook]],
        @"share_via_twitter":   [NSNumber numberWithBool:[self canShareVia:SLServiceTypeTwitter]],
        @"share_via_facebook_messenger":  [NSNumber numberWithBool:[self isFacebookMessangerInstalled]],
        @"sdk_version":         TKBLVersion,
    };
}

+ (BOOL)isFacebookMessangerInstalled {
    UIApplication* app = [UIApplication sharedApplication];
    // In iOS 9 you must whitelist any URL schemes your App wants to query in Info.plist under the LSApplicationQueriesSchemes
    return [app canOpenURL:[NSURL URLWithString:@"fb-messenger://share"]];
}

#pragma mark - [Private]

+ (BOOL)canSendSMS {
    return [MFMessageComposeViewController class] != nil && [MFMessageComposeViewController canSendText];
}

+ (BOOL)canShareVia:()channel {
    return [SLComposeViewController class] != nil && [SLComposeViewController isAvailableForServiceType:channel];
}


@end
