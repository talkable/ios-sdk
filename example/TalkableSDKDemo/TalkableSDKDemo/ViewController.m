//
//  ViewController.m
//  TalkableDemo
//
//  Created by Vitalik Danchenko on 06.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import <Social/Social.h>
#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setTitle:@"iOS Demo Integration"];
    
    self.emailField.delegate        = self;
    self.orderNumberField.delegate  = self;
    self.couponField.delegate       = self;
    self.subtotalField.delegate     = self;
    
    double subtotal = (((double) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * 40) + 10;
    [self.subtotalField setText: [NSString stringWithFormat:@"%.02f", subtotal]];
    
    NSString* alphabet  = @"0123456789";
    NSMutableString* orderNumber = [NSMutableString stringWithString:@"102"];
    for (int i = 0; i < 3; i++) {
        u_int32_t idx = arc4random() % [alphabet length];
        unichar c = [alphabet characterAtIndex:idx];
        [orderNumber appendFormat:@"%C", c];
    }
    [self.orderNumberField setText:orderNumber];
    
    NSString* coupon = [[NSUserDefaults standardUserDefaults] objectForKey:@"tmp-coupon-code"];
    if (coupon) [self.couponField setText:coupon];
    
    [[Talkable manager] setDelegate:self];
    NSLog(@"UUID = %@", [[Talkable manager] visitorUUID]);
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(couponReceived:) name:@"COUPONCODE_RECEIVED" object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"COUPONCODE_RECEIVED" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - [IBActions]

- (IBAction)testAffiliateMember:(id)sender {
    [[Talkable manager] registerOrigin:TKBLAffiliateMember params:nil];
}

- (IBAction)testAffiliateMemberWithEmail:(id)sender {
    NSDictionary* params =
    @{
        TKBLAffiliateMemberKey: @{
            TKBLAffiliateMemberEmailKey: @"customer@example.com",
            TKBLAffiliateMemberFirstNameKey: @"John",
            TKBLAffiliateMemberLastNameKey: @"Smith",
            TKBLAffiliateMemberPersonCustomPropertiesKey: @{
                @"eye_color": @"green"
            }
        }
    };
    [[Talkable manager] registerOrigin:TKBLAffiliateMember params:params];
}

- (IBAction)testPurchase:(id)sender {
    NSDictionary* params = @{TKBLPurchaseKey: @{
      TKBLPurchaseOrderNumberKey: self.orderNumberField.text,  //@"100130", // REQUIRED - Order number
      TKBLPurchaseOrderDateKey: [NSDate date], // REQUIRED - Order Date and Time (ISO 8601 formatted datetime)
      TKBLPurchaseEmailKey: self.emailField.text, //@"customer@example.com", // REQUIRED - Customer Email Address
      TKBLPurchaseSubtotalKey: [NSNumber numberWithDouble:[self.subtotalField.text doubleValue]], //[NSNumber numberWithDouble:22.33], // REQUIRED - Purchase Subtotal
      TKBLPurchaseCouponCodeKey: self.couponField.text, //@"", // REQUIRED - Coupon code used at checkout, multiple coupons allowed as array: @[@"SAVE20", @"FREE-SHIPPING"]. Pass @"" if there is no coupon code.
      TKBLPurchaseOrderItemsKey:@[
        @{
            TKBLPurchaseOrderItemProductIDKey: @"sku3", /* Item Product ID */
            TKBLPurchaseOrderItemPriceKey: [NSNumber numberWithDouble:4.99], /* Item Unit Price */
            TKBLPurchaseOrderItemQuantityKey: [NSNumber numberWithUnsignedInt:5], /* Item Quantity */
//            TKBLPurchaseOrderItemTitleKey: @"Amazing Product 3", /* Name of product */
//            TKBLPurchaseOrderItemUrlKey: @"http://www.store.com/product2", /* URL for product */
//            TKBLPurchaseOrderItemImageUrlKey: @"http://www.store.com/product2/image.jpg"
        }
        ]
      }
    };

    [[Talkable manager] registerOrigin:TKBLPurchase params:params];
}

- (IBAction)testEvent:(id)sender {
    NSDictionary* params = @{TKBLEventKey:@{
        TKBLEventCategoryKey: @"sample",
        TKBLEventNumberKey: @"0001",
        }
    };
    [[Talkable manager] registerOrigin:TKBLEvent params:params];
}

- (IBAction)testAPI:(id)sender {
    [self testCreateOrigin];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Talkable" message:@"Check console output for details" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

- (void)testCreateOrigin {
//    NSDictionary* originParams = @{
//        TKBLOriginTypeKey: TKBLOriginTypeAffiliateMember,
//        TKBLOriginDataKey: @{
//            TKBLAffiliateMemberEmailKey: @"test2@example.com"
//        }
//    };
    
    NSDictionary* originParams = @{
        TKBLOriginTypeKey: TKBLOriginTypePurchase,
        TKBLOriginDataKey: @{
            TKBLPurchaseEmailKey: @"test5@example.com",
            TKBLPurchaseSubtotalKey: @"17.43",
            TKBLPurchaseOrderNumberKey: @"100125",
        }
    };

//    NSDictionary* originParams = @{
//        TKBLOriginTypeKey: TKBLOriginTypeEvent,
//        TKBLOriginDataKey: @{
//            TKBLEventCategoryKey: @"sample",
//            TKBLEventNumberKey: [[[[UIDevice currentDevice] identifierForVendor] UUIDString] lowercaseString]
//        }
//    };
    
    [[Talkable manager] createOrigin:originParams withHandler:^(NSDictionary* response, NSError* error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            NSString* shortUrlCode  = [[response objectForKey:TKBLOfferKey] objectForKey:TKBLOfferShortUrlCodeKey];
            [self testRetriveOffer: shortUrlCode];
        }
    }];
}

- (void)testRetriveOffer:(NSString*)shortUrlCode {
    [[Talkable manager] retrieveOffer:shortUrlCode withHandler:^(NSDictionary* response, NSError* error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            NSString* shortUrlCode  = [[response objectForKey:TKBLOfferKey] objectForKey:TKBLOfferShortUrlCodeKey];
            [self testCreateShare:shortUrlCode];
        }
    }];
}

- (void)testCreateShare:(NSString*)shortUrlCode {
    [[Talkable manager] createShare:shortUrlCode channel:TKBLShareChannelOther withHandler:^(NSDictionary* response, NSError* error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            [self testRetrieveRewards:[[Talkable manager] visitorUUID]];
        }
    }];
}

- (void)testRetrieveRewards:(NSString*)uuid {
    [[Talkable manager] retrieveRewardsWithHandler:^(NSDictionary* response, NSError* error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"%@", response);
        }
    }];
}

#pragma mark - [UITextFieldDelegate]

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    [textField resignFirstResponder];
    if (textField == self.emailField) {
        [self.orderNumberField becomeFirstResponder];
    } else if (textField == self.orderNumberField) {
        [self.couponField becomeFirstResponder];
    } else if (textField == self.couponField) {
        [self.subtotalField becomeFirstResponder];
    }
    return YES;
}

#pragma mark - [TalkableDelegate]

- (void)didRegisterOrigin:(TKBLOriginType)type withURL:(NSURL*)url {
    NSLog(@"URL: %@", url);
}

- (void)didRegisterOrigin:(TKBLOriginType)type withWebView:(UIWebView*)webView {

}

- (UIViewController*)viewControllerForPresentingTalkableOfferViewController {
    return self;
}

#pragma mark - [Notifications]

-(void)couponReceived:(NSNotification*)ntf {
    NSString* coupon = [[NSUserDefaults standardUserDefaults] objectForKey:@"tmp-coupon-code"];
    if (coupon) [self.couponField setText:coupon];
}

@end
