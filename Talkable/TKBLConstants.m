//
//  TKBLConstants.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 09.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import "TKBLConstants.h"

NSString* TKBLVersion                                   = @"1.4.10";

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
NSString* TKBLDidReceiveReward                          = @"TKBLDidReceiveRewordNotificationName";

NSString* TKBLOriginKey                                 = @"o";
NSString* TKBLOriginTypeKey                             = @"type";
NSString* TKBLOriginDataKey                             = @"data";
NSString* TKBLOriginUUIDKey                             = @"uuid";
NSString* TKBLOriginTypeAffiliateMember                 = @"AffiliateMember";
NSString* TKBLOriginTypePurchase                        = @"Purchase";
NSString* TKBLOriginTypeEvent                           = @"Event";
NSString* TKBLOriginTrafficSourceKey                    = @"traffic_source";

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
NSString* TKBLPurchasePersonCustomPropertiesKey         = @"person_custom_properties";
NSString* TKBLPurchasePersonCustomPropertiesKeyKey      = @"person_custom_properties"; // legacy typo

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
NSString* TKBLEventEmailKey                             = @"email";
NSString* TKBLEventSubtotalKey                          = @"subtotal";
NSString* TKBLEventTrafficSourceKey                     = @"traffic_source";
NSString* TKBLEventPersonCustomPropertiesKey            = @"person_custom_properties";

NSString* TKBLCampaignTags                              = @"campaign_tags[]";

NSString* TKBLOfferKey                                  = @"offer";
NSString* TKBLOfferShortUrlCodeKey                      = @"short_url_code";
NSString* TKBLOfferClaimUrlKey                          = @"claim_url";
NSString* TKBLClipboardTextKey                          = @"text";

NSString* TKBLVisitorUUID                               = @"visitor_uuid";

NSString* TKBLShareChannel                              = @"channel";
NSString* TKBLShareChannelFacebook                      = @"facebook";
NSString* TKBLShareChannelFacebookMessage               = @"facebook_message";
NSString* TKBLShareChannelTwitter                       = @"twitter";
NSString* TKBLShareChannelWhatsApp                      = @"whatsapp";
NSString* TKBLShareChannelSMS                           = @"sms";
NSString* TKBLShareChannelOther                         = @"other";
NSString* TKBLShareChannelNativeMail                    = @"direct_email_native";
NSString* TKBLShareMessage                              = @"message";
NSString* TKBLShareRecipients                           = @"recipients";
NSString* TKBLShareImage                                = @"image";

NSString* TKBLProductKey                                = @"product";
