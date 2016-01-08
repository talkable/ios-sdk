//
//  TKBLUUIDExtractor.h
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 06.01.16.
//  Copyright © 2016 Talkable. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SafariServices/SafariServices.h>

@interface TKBLUUIDExtractor : NSObject <SFSafariViewControllerDelegate>

+ (instancetype)extractor;

- (void)extractFromServer:(NSString*)server withAppSchema:(NSString*)string;

@end
