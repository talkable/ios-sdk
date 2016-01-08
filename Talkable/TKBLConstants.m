//
//  TKBLConstants.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 09.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import "TKBLConstants.h"

NSString* TKBLVersion                                   = @"1.2.2";

NSString* TKBLErrorDomain                               = @"com.talkable.ios-sdk";

NSString* TKBLConfigurationException                    = @"TKBLConfigurationExceptionName";

NSString* TKBLDidPublishMessageNotification             = @"TKBLDidPublishMessageNotificationName";
NSString* TKBLMessageNameKey                            = @"name";
NSString* TKBLMessageParamsKey                          = @"params";
NSString* TKBLMessageDataKey                            = @"data";
NSString* TKBLMessageOfferLoaded                        = @"offer_loaded";
NSString* TKBLMessageOfferClose                         = @"offer_close";
NSString* TKBLMessageCouponIssued                       = @"coupon_issued";

NSString* TKBLDidReceiveCouponCode                      = @"TKBLDidReceiveCouponCodeNotificationName";

NSString* TKBLOriginKey                                 = @"o";
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
NSString* TKBLClipboardTextKey                             = @"text";

NSString* TKBLVisitorUUID                               = @"visitor_uuid";

NSString* TKBLShareChannel                              = @"channel";
NSString* TKBLShareChannelFacebook                      = @"facebook";
NSString* TKBLShareChannelTwitter                       = @"twitter";
NSString* TKBLShareChannelOther                         = @"other";
NSString* TKBLShareMessage                              = @"message";
NSString* TKBLShareRecipients                           = @"recipients";
NSString* TKBLShareImage                                = @"image";