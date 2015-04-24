//
//  TKBLObjCChecker.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 24.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import "TKBLObjCChecker.h"
#import "TKBLObjCCheckerExt.h"

@implementation TKBLObjCChecker

- (BOOL)flagExist {
    return [self respondsToSelector:@selector(categoryLoaded)];
}

@end
