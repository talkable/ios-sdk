//
//  TKBLKeychainHelper.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 29.02.16.
//  Copyright © 2016 Talkable. All rights reserved.
//

#import "TKBLKeychainHelper.h"

@implementation TKBLKeychainHelper {
    NSString*   _serviceName;
}

- (id)init {
    return [self initWithService:@"DefaultTalkableService"];
}

- (id)initWithService:(NSString*)serviceName {
    if (self = [super init]) {
        _serviceName = serviceName;
    }
    return self;
}

#pragma mark - [Public]

- (void)storeData:(NSData*)data forKey:(NSString*)key {
    NSMutableDictionary* keychainItem = [self keychainItem:key];
    SecItemDelete((__bridge CFDictionaryRef)keychainItem);
    keychainItem[(__bridge id)kSecValueData] = data;
    SecItemAdd((__bridge CFDictionaryRef)keychainItem, NULL);
}

- (NSData*)dataForKey:(NSString*)key {
    OSStatus status;
    NSMutableDictionary* keychainQueryItem = [self keychainItem:key];
    keychainQueryItem[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    keychainQueryItem[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
    keychainQueryItem[(__bridge id)kSecReturnAttributes] = (__bridge id)kCFBooleanTrue;
    CFDictionaryRef resultItem = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)keychainQueryItem, (CFTypeRef*)&resultItem);
    if (status != noErr) {
        return nil;
    }
    NSDictionary* resultDict = (__bridge_transfer NSDictionary*)resultItem;
    return resultDict[(__bridge id)kSecValueData];
}

#pragma mark - [Private]

- (NSMutableDictionary*)keychainItem:(NSString*)key {
    NSMutableDictionary* keychainItem = [[NSMutableDictionary alloc] init];
    keychainItem[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    keychainItem[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlock;
    keychainItem[(__bridge id)kSecAttrAccount] = key;
    keychainItem[(__bridge id)kSecAttrService] = _serviceName;
    return keychainItem;
}

@end
