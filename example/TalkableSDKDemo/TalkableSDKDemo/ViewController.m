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
    
    self.subjectField.delegate          = self;
    self.emailField.delegate            = self;
    self.messageField.delegate          = self;
    self.orderNumberField.delegate      = self;
    self.couponField.delegate           = self;
    self.subtotalField.delegate         = self;
    self.webUUIDField.delegate          = self;
    self.visitorOfferIDField.delegate   = self;
    
    double subtotal = (((double) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * 40) + 10;
    [self.subtotalField setText: [NSString stringWithFormat:@"%.02f", subtotal]];
    
    NSString* alphabet  = @"0123456789";
    NSMutableString* orderNumber = [NSMutableString stringWithString:@"121-"];
    for (int i = 0; i < 5; i++) {
        u_int32_t idx = arc4random() % [alphabet length];
        unichar c = [alphabet characterAtIndex:idx];
        [orderNumber appendFormat:@"%C", c];
    }
    [self.orderNumberField setText:orderNumber];
    
    [self updateCoupon];
    
    [[Talkable manager] setDelegate:self];
    NSLog(@"UUID = %@", [[Talkable manager] visitorUUID]);
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(couponReceived:) name:TKBLDidReceiveCouponCode object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TKBLDidReceiveCouponCode object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - [Private]

- (void)updateCoupon {
    NSString* coupon = [[Talkable manager] coupon];
    if (coupon) [self.couponField setText:coupon];
}

#pragma mark - [IBActions]

- (IBAction)testAffiliateMember:(id)sender {
    [[Talkable manager] registerOrigin:TKBLAffiliateMember params:nil];
}

- (IBAction)testAffiliateMemberWithEmail:(id)sender {
    NSDictionary* params =
    @{
        TKBLAffiliateMemberKey: @{
            TKBLAffiliateMemberEmailKey: self.emailField.text,
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
        TKBLEventNumberKey: self.orderNumberField.text,
        }
    };
    [[Talkable manager] registerOrigin:TKBLEvent params:params];
}

- (IBAction)testAPI:(id)sender {
    [self testCreateOrigin];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Talkable" message:@"Check console output for details" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

- (IBAction)testFacebookShare:(id)sender {
    NSDictionary* originParams = @{
                                   TKBLOriginTypeKey: TKBLOriginTypePurchase,
                                   TKBLOriginDataKey: @{
                                           TKBLPurchaseEmailKey: @"test5@example.com",
                                           TKBLPurchaseSubtotalKey: @"17.43",
                                           TKBLPurchaseOrderNumberKey: @"100125",
                                           @"campaign_tags": @"post-purchase"
                                           }
                                   };
    
    [[Talkable manager] createOrigin:originParams withHandler:^(NSDictionary* response, NSError* error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            NSString* shortUrlCode  = [[response objectForKey:TKBLOfferKey] objectForKey:TKBLOfferShortUrlCodeKey];
            [[Talkable manager] retrieveOffer:shortUrlCode withHandler:^(NSDictionary* response, NSError* error) {
                if (error) {
                    NSLog(@"Error: %@", error);
                } else {
                    NSString* shortUrlCode  = [[response objectForKey:TKBLOfferKey] objectForKey:TKBLOfferShortUrlCodeKey];
                    SLComposeViewController* sheet = [[Talkable manager] socialShare:@{
                                                      TKBLShareChannel: TKBLShareChannelFacebook,
                                                      TKBLOfferClaimUrlKey: [[response objectForKey:TKBLOfferKey] objectForKey:TKBLOfferClaimUrlKey],
                                                      TKBLShareMessage: self.messageField.text,
                                                      TKBLOfferShortUrlCodeKey: shortUrlCode
                                                      }];
                    [self presentViewController:sheet animated:YES completion:^{}];
                }
            }];

        }
    }];
}

- (IBAction)testDeepLinking:(id)sender {
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    if (self.webUUIDField.text && self.webUUIDField.text.length > 0) {
        params[@"talkable_visitor_uuid"] = self.webUUIDField.text;
    }
    if (self.visitorOfferIDField.text && self.visitorOfferIDField.text.length > 0) {
        params[@"talkable_visitor_offer_id"] = self.visitorOfferIDField.text;
    }
    if ([params count] > 0) {
        [[Talkable manager] handleURLParams:params];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Talkable" message:@"Deep linking params were handled. Check console for details." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }
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
            @"campaign_tags": @"post-purchase"
        }
    };

//    NSDictionary* originParams = @{
//        TKBLOriginTypeKey: TKBLOriginTypeEvent,
//        TKBLOriginDataKey: @{
//            TKBLEventCategoryKey: @"sample",
//            TKBLEventNumberKey: [[Talkable manager] deviceIdentifier]
//        }
//    };
    
    [[Talkable manager] createOrigin:originParams withHandler:^(NSDictionary* response, NSError* error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            NSString* shortUrlCode  = [[response objectForKey:TKBLOfferKey] objectForKey:TKBLOfferShortUrlCodeKey];
            [self testRetriveOffer:shortUrlCode];
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
    // Share offer link using one of available social network channels (e.g. facebook, twitter, whatsapp, other)
    [[Talkable manager] createSocialShare:shortUrlCode channel:TKBLShareChannelOther withHandler:^(NSDictionary* response, NSError* error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            [self testRetrieveRewards:[[Talkable manager] visitorUUID]];
        }
    }];
    
    NSString* recipients = self.emailField.text;
    NSDictionary* emailShareParams = @{
                                       @"subject": self.subjectField.text,
                                       @"body": self.messageField.text,
                                       @"reminder": @YES
                                       };
    
    // Share offer link using e-mail to one or more comma separated recipients (e.g. @"customer@example.com,elon@musk.com")
    // Additional params allow for custom subject and personalized message in body
    // Pass {@"reminder": @YES} to enable e-mail reminder
    [[Talkable manager] createEmailShare:shortUrlCode recipients:recipients withParams:emailShareParams andHandler:^(NSDictionary* response, NSError* error) {
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
    return YES;
}

#pragma mark - [TalkableDelegate]

- (BOOL)shouldRegisterOrigin:(TKBLOriginType)type withURL:(NSURL*)url {
    NSLog(@"URL: %@", url);
    return YES;
}

- (void)didRegisterOrigin:(TKBLOriginType)type withWebView:(UIWebView*)webView {
    NSLog(@"didRegisterOrigin");
}

- (void)registerOrigin:(TKBLOriginType)type didFailWithError:(NSError*)error {
    NSLog(@"registerOrigindidFailWithError - %@", [error localizedDescription]);
}

- (UIViewController*)viewControllerForPresentingTalkableOfferViewController {
    return self;
}

- (BOOL)shouldPresentTalkableOfferViewController:(UIViewController *)controller {
    return YES;
}

#pragma mark - [Notifications]

-(void)couponReceived:(NSNotification*)ntf {
    [self updateCoupon];
}

@end
