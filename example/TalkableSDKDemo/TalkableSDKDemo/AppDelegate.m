//
//  AppDelegate.m
//  TalkableDemo
//
//  Created by Vitalik Danchenko on 06.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import "AppDelegate.h"
#import <TalkableSDK/Talkable.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [Talkable manager].debug = YES;
    //[[Talkable manager] setApiKey:@"8L6Kcf9DEIGQQHLDf8i" andSiteSlug:@"demo-ios-integration"];
    //[[Talkable manager] setApiKey:@"8L6Kcf9DEIGQQHLDf8i" andSiteSlug:@"talkable-ios-demo"]; // shopify
    [[Talkable manager] setApiKey:@"FOuTgIbxpbOGP4LeDS6F" andSiteSlug:@"demo-ios-integration" server:@"http://10.0.1.4:3000"];
    //[[Talkable manager] setApiKey:@"WCHpvYrQK8ABhBpA8JnN" andSiteSlug:@"demo-ios-integration" server:@"http://10.0.1.2:3000"];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
    
    [[Talkable manager] handleOpenURL:url];
    
    return YES;
}

@end
