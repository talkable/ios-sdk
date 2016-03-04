//
//  TKBLOfferChecker.h
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 01.03.16.
//  Copyright © 2016 Talkable. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^TKBLOfferExistingHandler)(BOOL isExist, NSString* localizedErrorMessage);

@interface TKBLOfferChecker : NSObject <UIWebViewDelegate>

- (void)performWithContent:(NSData*)contentData MIMEType:(NSString*)MIMEType textEncodingName:(NSString*)textEncodingName baseURL:(NSURL*)baseURL callback:(TKBLOfferExistingHandler)callback;

@end
