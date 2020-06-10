//
//  TLKBContactsLoader.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 21.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

#import "TKBLContactsLoader.h"
#import "Talkable.h"

NSString* TKBLContactFirstNameKey       = @"first_name";
NSString* TKBLContactLastNameKey        = @"last_name";
NSString* TKBLContactFullNameKey        = @"full_name";
NSString* TKBLContactEmailKey           = @"email";
NSString* TKBLContactPhoneNumberKey     = @"phone_number";

@implementation TKBLContactsLoader

+ (instancetype)loader {
    return [[self alloc] init];
}

- (void)loadContactsWithComplitionHandler:(void(^)(NSArray* contactList))complitionHandler {
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    if (status == kABAuthorizationStatusDenied || status == kABAuthorizationStatusRestricted) {
        [self notifyNeedPermissions];
        return;
    }
    CFErrorRef error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    
    if (!addressBook) {
        TKBLLog(@"error while loading contacts - %@", CFBridgingRelease(error));
        return;
    }
    
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        if (error)
            TKBLLog(@"error while loading contacts - %@", CFBridgingRelease(error));

        if (granted) {
            NSArray* contacts = [self grabContactsFromAdressBook:addressBook];
            dispatch_async(dispatch_get_main_queue(), ^{
                complitionHandler(contacts);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self notifyNeedPermissions];
            });
        }
        CFRelease(addressBook);
    });
}

#pragma mark - [Private]

- (void)notifyNeedPermissions {
    NSString* message = NSLocalizedString(@"This app requires access to your contacts to function properly. Please visit to the Privacy section in the Settings app.", nil);
    [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    return;
}

- (NSArray*)grabContactsFromAdressBook:(ABAddressBookRef)addressBook {
    NSMutableArray* contacts = [NSMutableArray array];
    
    NSArray* abContacts = CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBook));
    for (int i = 0; i < [abContacts count]; i++) {
        ABRecordRef abContact = (__bridge ABRecordRef)abContacts[i];
        
        NSString* firstName = CFBridgingRelease(ABRecordCopyValue(abContact, kABPersonFirstNameProperty));
        NSString* lastName  = CFBridgingRelease(ABRecordCopyValue(abContact, kABPersonLastNameProperty));
        NSString *fullName = firstName ? [[NSArray arrayWithObjects:firstName, lastName, nil] componentsJoinedByString:@" "] : [lastName copy];
        
        NSMutableArray* phoneNumbers = [NSMutableArray array];
        ABMultiValueRef abPhoneNumbers = ABRecordCopyValue(abContact, kABPersonPhoneProperty);
        for (CFIndex phone_idx = 0; phone_idx < ABMultiValueGetCount(abPhoneNumbers); phone_idx++) {
            NSString* phoneNumber = CFBridgingRelease(ABMultiValueCopyValueAtIndex(abPhoneNumbers, phone_idx));
            [phoneNumbers addObject:phoneNumber];
            
        }
        CFRelease(abPhoneNumbers);
        
        NSMutableArray* emails = [NSMutableArray array];
        ABMultiValueRef abEmails = ABRecordCopyValue(abContact, kABPersonEmailProperty);
        for (CFIndex email_idx = 0; email_idx < ABMultiValueGetCount(abEmails); email_idx++) {
            NSString* email = CFBridgingRelease(ABMultiValueCopyValueAtIndex(abEmails, email_idx));
            [emails addObject:email];
        }
        CFRelease(abEmails);
        
        
        [contacts addObject:@{
            TKBLContactFirstNameKey: firstName ? firstName : [NSNull null],
            TKBLContactLastNameKey: lastName ? lastName : [NSNull null],
            TKBLContactFullNameKey: fullName ? fullName : [NSNull null],
            TKBLContactEmailKey: emails,
            TKBLContactPhoneNumberKey: phoneNumbers
        }];
    }
    return [NSArray arrayWithArray:contacts];
}


@end
