//
//  TKBLKeychainHelper.h
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 29.02.16.
//  Copyright © 2016 Talkable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TKBLKeychainHelper : NSObject

- (id)initWithService:(NSString*)serviceName;

- (void)storeData:(NSData*)data forKey:(NSString*)key;
- (NSData*)dataForKey:(NSString*)key;

@end
