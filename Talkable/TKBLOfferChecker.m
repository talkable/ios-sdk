//
//  TKBLOfferChecker.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 01.03.16.
//  Copyright © 2016 Talkable. All rights reserved.
//

#import "TKBLOfferChecker.h"
#import "Talkable.h"

@implementation TKBLOfferChecker

- (void)performWithHTMLString:(NSString*)htmlString encoding:(NSStringEncoding)encoding callback:(TKBLOfferExistingHandler)callback {
    
    if (!callback) return;
    
    NSRange searchedRange = NSMakeRange(0, [htmlString length]);
    NSString* pattern = @"Talkable.configure\\((.*)\\);";
    NSError* patternError = nil;
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&patternError];
    if (patternError) {
        callback(NO, patternError.localizedDescription);
        return;
    }
    NSTextCheckingResult* match = [regex firstMatchInString:htmlString options:0 range:searchedRange];
    if ([match numberOfRanges] != 2) {
        callback(NO, NSLocalizedString(@"Incompatible response. Unable to locate view configuration.", nil));
        return;
    }
    NSRange configurationRange = [match rangeAtIndex:1];
        
        
    NSError* jsonError = nil;
    NSData* jsonData = [[htmlString substringWithRange:configurationRange] dataUsingEncoding:encoding];
    NSDictionary* configuration = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                  options:NSJSONReadingMutableContainers
                                                                    error:&jsonError];
    if (jsonError) {
        NSLog(@"%@", [htmlString substringWithRange:configurationRange]);
        callback(NO, jsonError.localizedDescription);
        return;
    }
    
    if ([[configuration objectForKey:@"offer_short_code"] length] > 0) {
        callback(YES, nil);
    } else {
        NSString* errorMessage = [configuration objectForKey:@"error_message"];
        callback(NO, NSLocalizedString(errorMessage, nil));
    }
}

@end
