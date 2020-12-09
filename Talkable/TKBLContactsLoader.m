//
//  TLKBContactsLoader.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 21.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Contacts/Contacts.h>

#import "TKBLContactsLoader.h"
#import "Talkable.h"
#import "TKBLHelper.h"

NSString* TKBLContactFirstNameKey       = @"first_name";
NSString* TKBLContactLastNameKey        = @"last_name";
NSString* TKBLContactFullNameKey        = @"full_name";
NSString* TKBLContactEmailKey           = @"email";
NSString* TKBLContactPhoneNumberKey     = @"phone_number";

@implementation TKBLContactsLoader

- (void)loadContactsWithCompletionHandler:(void(^)(NSArray* contacts))completionHandler {
    [self requestForAccessWithCompletion:^(BOOL granted) {
        if (granted) {
            NSArray *contacts = [self grabContacts];
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(contacts);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentPermissionAlert];
            });
        }
    }];
}

- (void)presentPermissionAlert {
    NSString *message = NSLocalizedString(@"This app requires access to your contacts to function properly. Please visit the Privacy section in the Settings app.", nil);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];

    [alert addAction:action];
    
    [[TKBLHelper topMostController] presentViewController:alert animated:YES completion:nil];
}

- (NSArray*)grabContacts {
    NSArray *keys = @[CNContactFamilyNameKey,
                      CNContactGivenNameKey,
                      CNContactPhoneNumbersKey,
                      CNContactEmailAddressesKey];
    CNContactStore *store = [[CNContactStore alloc] init];
    CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
    NSError *error;
    NSMutableArray* contacts = [NSMutableArray array];
    
    [store enumerateContactsWithFetchRequest:request error:&error usingBlock:^(CNContact * __nonnull contact, BOOL * __nonnull stop) {
        if (error) {
            TKBLLog(@"error while loading contacts - %@", [error localizedDescription]);
        } else {
            NSString *fullName;
            NSString *firstName = contact.givenName;
            NSString *lastName = contact.familyName;
            NSMutableArray *phoneNumbers = [NSMutableArray new];
            NSMutableArray *emailAddresses = [NSMutableArray new];

            if (firstName != nil && lastName != nil) {
                fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
            } else if (firstName != nil) {
                fullName = [NSString stringWithFormat:@"%@", firstName];
            } else if (lastName != nil) {
                fullName = [NSString stringWithFormat:@"%@", lastName];
            }

            for (CNLabeledValue *label in contact.phoneNumbers) {
                NSString *phone = [label.value stringValue];
                if ([phone length] > 0) {
                    [phoneNumbers addObject:phone];
                }
            }
            
            for (CNLabeledValue *label in contact.emailAddresses) {
                NSString *email = label.value;
                if ([email length] > 0) {
                    [emailAddresses addObject:email];
                }
            }
            
            [contacts addObject:@{TKBLContactFirstNameKey: firstName ? firstName : [NSNull null],
                                  TKBLContactLastNameKey: lastName ? lastName : [NSNull null],
                                  TKBLContactFullNameKey: fullName ? fullName  : [NSNull null],
                                  TKBLContactEmailKey: emailAddresses,
                                  TKBLContactPhoneNumberKey: phoneNumbers}];
        }
    }];
    
    return [NSArray arrayWithArray:contacts];
}

- (void)requestForAccessWithCompletion:(void(^)(BOOL granted))completionHandler {
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    CNContactStore *store = [[CNContactStore alloc] init];
    
    switch (status) {
        case CNAuthorizationStatusAuthorized:
            completionHandler(YES);
            
            break;
        case CNAuthorizationStatusRestricted:
        case CNAuthorizationStatusDenied:
        case CNAuthorizationStatusNotDetermined:
            [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if (error) {
                    TKBLLog(@"error while loading contacts - %@", [error localizedDescription]);
                }
                
                completionHandler(granted);
            }];
            
            break;
    }
}

@end
