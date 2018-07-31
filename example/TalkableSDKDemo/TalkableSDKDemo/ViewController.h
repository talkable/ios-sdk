//
//  ViewController.h
//  TalkableDemo
//
//  Created by Vitalik Danchenko on 06.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TalkableSDK/Talkable.h>

@interface ViewController : UIViewController <TalkableDelegate, UITextFieldDelegate>

@property(nonatomic) IBOutlet UITextField*  emailField;
@property(nonatomic) IBOutlet UITextField*  subjectField;
@property(nonatomic) IBOutlet UITextField*  messageField;
@property(nonatomic) IBOutlet UITextField*  orderNumberField;
@property(nonatomic) IBOutlet UITextField*  couponField;
@property(nonatomic) IBOutlet UITextField*  subtotalField;
@property(nonatomic) IBOutlet UITextField*  webUUIDField;
@property(nonatomic) IBOutlet UITextField*  visitorOfferIDField;


- (IBAction)testAffiliateMember:(id)sender;
- (IBAction)testAffiliateMemberWithEmail:(id)sender;
- (IBAction)testPurchase:(id)sender;
- (IBAction)testEvent:(id)sender;
- (IBAction)testFacebookShare:(id)sender;

- (IBAction)testAPI:(id)sender;

- (IBAction)testDeepLinking:(id)sender;

@end

