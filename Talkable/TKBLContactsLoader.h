//
//  TLKBContactsLoader.h
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 21.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString* TKBLContactFirstNameKey;
FOUNDATION_EXPORT NSString* TKBLContactLastNameKey;
FOUNDATION_EXPORT NSString* TKBLContactFullNameKey;
FOUNDATION_EXPORT NSString* TKBLContactEmailKey;
FOUNDATION_EXPORT NSString* TKBLContactPhoneNumberKey;

@interface TKBLContactsLoader : NSObject

- (void)loadContactsWithcompletionHandler:(void(^)(NSArray* contacts))completionHandler;

@end
