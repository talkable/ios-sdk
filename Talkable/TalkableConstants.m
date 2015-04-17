//
//  TalkableConstants.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 09.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import "TalkableConstants.h"

NSString* TKBLVersion                                   = @"1.0.0";

NSString* TKBLErrorDomain                               = @"com.talkable.ios-sdk";

NSString* TKBLOfferDidSendCloseActionNotification       = @"TKBLOfferDidSendCloseActionNotificationName";
NSString* TKBLOfferDidSendShareActionNotification       = @"TKBLOfferDidSendShareActionNotificationName";

NSString* TKBLOriginTypeKey                             = @"type";
NSString* TKBLOriginDataKey                             = @"data";
NSString* TKBLOriginUUIDKey                             = @"uuid";
NSString* TKBLOriginTypeAffiliateMember                 = @"AffiliateMember";
NSString* TKBLOriginTypePurchase                        = @"Purchase";
NSString* TKBLOriginTypeEvent                           = @"Event";

NSString* TKBLAffiliateMemberKey                        = @"affiliate_member";
NSString* TKBLAffiliateMemberEmailKey                   = @"email";
NSString* TKBLAffiliateMemberFirstNameKey               = @"first_name";
NSString* TKBLAffiliateMemberLastNameKey                = @"last_name";
NSString* TKBLAffiliateMemberGenderKey                  = @"gender";
NSString* TKBLAffiliateMemberCustomerIDKey              = @"customer_id";
NSString* TKBLAffiliateMemberIPAddressKey               = @"ip_address";
NSString* TKBLAffiliateMemberTrafficSourceKey           = @"traffic_source";
NSString* TKBLAffiliateMemberPersonCustomPropertiesKey  = @"person_custom_properties";

NSString* TKBLPurchaseKey                               = @"p";
NSString* TKBLPurchaseOrderNumberKey                    = @"order_number";
NSString* TKBLPurchaseOrderDateKey                      = @"order_date";
NSString* TKBLPurchaseCouponCodeKey                     = @"coupon_code";
NSString* TKBLPurchaseSubtotalKey                       = @"subtotal";
NSString* TKBLPurchaseEmailKey                          = @"email";
NSString* TKBLPurchaseFirstNameKey                      = @"first_name";
NSString* TKBLPurchaseLastNameKey                       = @"last_name";
NSString* TKBLPurchaseCustomerIDKey                     = @"customer_id";
NSString* TKBLPurchaseIPAddressKey                      = @"ip_address";
NSString* TKBLPurchaseTrafficSourceKey                  = @"traffic_source";
NSString* TKBLPurchasePersonCustomPropertiesKeyKey      = @"person_custom_properties";

NSString* TKBLPurchaseOrderItemsKey                     = @"i";
NSString* TKBLPurchaseOrderItemProductIDKey             = @"product_id";
NSString* TKBLPurchaseOrderItemPriceKey                 = @"price";
NSString* TKBLPurchaseOrderItemQuantityKey              = @"quantity";
NSString* TKBLPurchaseOrderItemTitleKey                 = @"title";
NSString* TKBLPurchaseOrderItemUrlKey                   = @"url";
NSString* TKBLPurchaseOrderItemImageUrlKey              = @"image_url";

NSString* TKBLEventKey                                  = @"event";
NSString* TKBLEventCategoryKey                          = @"event_category";
NSString* TKBLEventNumberKey                            = @"event_number";

NSString* TKBLOfferKey                                  = @"offer";
NSString* TKBLOfferShortUrlCodeKey                      = @"short_url_code";
NSString* TKBLOfferClaimUrlKey                          = @"claim_url";

NSString* TKBLVisitorUUID                               = @"visitor_uuid";

NSString* TKBLShareChannel                              = @"channel";
NSString* TKBLShareChannelFacebook                      = @"facebook";
NSString* TKBLShareChannelTwitter                       = @"twitter";
NSString* TKBLShareChannelOther                         = @"other";
NSString* TKBLShareTitle                                = @"title";
NSString* TKBLShareImage                                = @"image";