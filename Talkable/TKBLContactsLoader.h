//
//  TLKBContactsLoader.h
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 21.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TKBLContactsLoader : NSObject

+ (instancetype)loader;

- (void)loadContactsWithComplitionHandler:(void(^)(NSArray* contactList))complitionHandler;

@end
