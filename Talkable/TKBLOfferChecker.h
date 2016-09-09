//
//  TKBLOfferChecker.h
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 01.03.16.
//  Copyright © 2016 Talkable. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^TKBLOfferExistingHandler)(BOOL isExist, NSString* localizedErrorMessage);

@interface TKBLOfferChecker : NSObject

- (void)performWithHTMLString:(NSString*)htmlString encoding:(NSStringEncoding)encoding callback:(TKBLOfferExistingHandler)callback;

@end
