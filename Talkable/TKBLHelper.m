//
//  TKBLHelper.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 29.07.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import "TKBLHelper.h"

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

@end
