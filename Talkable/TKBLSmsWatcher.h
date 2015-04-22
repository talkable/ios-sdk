//
//  TKBLSmsWhatcher.h
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 22.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

typedef void (^TKBLSmsWhatcherSuccessCompletionHandler)(void);

@interface TKBLSmsWatcher : NSObject <MFMessageComposeViewControllerDelegate>

@property(nonatomic, copy) TKBLSmsWhatcherSuccessCompletionHandler successCompletionHandler;

@end
