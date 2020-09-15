//
//  Talkable.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 06.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import "Talkable.h"
#import "TKBLOfferViewController.h"
#import "UIViewControllerExt.h"
#import "TKBLKeychainHelper.h"
#import "TKBLOfferTarget.h"
#import "TKBLObjCChecker.h"
#import "TKBLHelper.h"

#import "AFNetworking.h"

#ifndef TKBL_API_VERSION
    #define TKBL_API_VERSION    @"v2"
#endif

#ifndef TKBL_DEFAULT_SERVER
    #define TKBL_DEFAULT_SERVER @"https://www.talkable.com"
#endif

NSString*   TKBLApiKey                                  = @"api_key";
NSString*   TKBLSiteSlug                                = @"site_slug";
NSString*   TKBLVisitorOfferKey                         = @"talkable_visitor_offer_id";
NSString*   TKBLVisitorWebUUIDKey                       = @"talkable_visitor_uuid";
NSString*   TKBLCouponKey                               = @"coupon";

NSString*   TKBLHeaderErrorCode                         = @"X-Talkable-Error-Code";
NSString*   TKBLHeaderErrorMessage                      = @"X-Talkable-Error-Message";

NSString*   TKBLFailureReasonRequestError               = @"REQUEST_ERROR";
NSString*   TKBLFailureReasonSiteNotFound               = @"SITE_NOT_FOUND";
NSString*   TKBLFailureReasonCampaignNotFound           = @"CAMPAIGN_NOT_FOUND";
NSString*   TKBLFailureReasonOriginAlreadyExists        = @"ORIGIN_ALREADY_EXISTS";
NSString*   TKBLFailureReasonOriginInvalidAttributes    = @"ORIGIN_INVALID_ATTRIBUTES";

@implementation Talkable {
    AFHTTPRequestOperationManager*  _networkClient;
    NSString*                       _userAgent;
    NSString*                       _apiUserAgent;
    NSString*                       _originalUserAgent;
    NSString*                       _featuresJsonString;
    NSArray* __strong               _couponCodeParams;
    NSMutableArray* __strong        _offerTargets;
    NSString*                       _uuid;
    NSString*                       _deviceIdentifier;
    TKBLKeychainHelper*             _keychain;
}

@synthesize apiKey, siteSlug = _siteSlug, delegate, server = _server, debug, skipFirstInstallCheck, skipReinstallCheck, ignoreStoredDeviceIdentity;

#pragma mark - [Singleton]

+ (Talkable*)manager {
    if (![self talkableSupported]) return nil;
    
    static Talkable* sharedManager = nil;
    if (sharedManager == nil) {
        @synchronized(self) {
            if (sharedManager == nil) {
                sharedManager = [[super allocWithZone:NULL] init];
            }
        }
    }
    return sharedManager;
}

+ (BOOL)talkableSupported {
    if (NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_9_0) {
        NSLog(@"TalkableSDK suports iOS9.0 and later.");
        return NO;
    }
    
    TKBLObjCChecker* checker = [[TKBLObjCChecker alloc] init];
    if (![checker flagExist]) {
        NSLog(@"Add -ObjC to Other Linker Flags to use TalkableSDK. More details at https://developer.apple.com/library/ios/qa/qa1490/_index.html");
        return NO;
    }
    
    if ([WKWebView class] == nil) {
        NSLog(@"TalkableSDK needs WebKit.framework. It is not added to your project. Check http://docs.talkable.com/ios_sdk/getting_started.html for more details.");
        return NO;
    }
    
    return YES;
}

+ (id)allocWithZone:(NSZone*)zone {
    [NSException raise:NSInternalInconsistencyException
                format:@"[%@ %@] cannot be called; use +[%@ %@] instead",
     NSStringFromClass(self), NSStringFromSelector(_cmd),
     NSStringFromClass(self),
     NSStringFromSelector(@selector(manager))];
    return nil;
}

- (id)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

# pragma mark - [Setters and Getters]

- (void)setServer:(NSString*)server {
    _server = server;
    [self visitorUUID]; // make sure visitor UUID for new server created
}

- (void)setSiteSlug:(NSString*)siteSlug {
    _siteSlug = siteSlug;
    [self checkUrlScheme];
}

# pragma mark - [Public]

- (void)setApiKey:(NSString*)aApiKey andSiteSlug:(NSString*)aSiteSlug server:(NSString*)aServer {
    if (!aApiKey || !aSiteSlug) {
        [self raiseException:NSInvalidArgumentException withMessage:@"You can not use nil for apiKey and siteSlug"];
    }
    
    self.apiKey     = aApiKey;
    self.siteSlug   = aSiteSlug;
    self.server     = aServer ? aServer : TKBL_DEFAULT_SERVER;
}

- (void)setApiKey:(NSString*)aApiKey andSiteSlug:(NSString*)aSiteSlug {
    [self setApiKey:aApiKey andSiteSlug:aSiteSlug server:TKBL_DEFAULT_SERVER];
}

- (NSString*)visitorUUID {
    if (_uuid) return _uuid;
    
    if (!_uuid) _uuid = [self uuidFromKeychain:@"tkbl_uuid"];
    if (!_uuid) _uuid = [self uuidFromPref:@"tkbl_uuid"];
    if (!_uuid) _uuid = [self generateUUID];
    if (_uuid) [self syncUUID:_uuid forKey:@"tkbl_uuid"];
    
    return _uuid;
}

- (NSString*)deviceIdentifier {
    if (_deviceIdentifier) return _deviceIdentifier;
    
    if (!_deviceIdentifier) _deviceIdentifier = [self uuidFromKeychain:@"tkbl_device_id"];
    if (!_deviceIdentifier) _deviceIdentifier = [self uuidFromPref:@"tkbl_device_id"];
    if (!_deviceIdentifier) _deviceIdentifier = [self generateUUID];
    if (_deviceIdentifier) [self syncUUID:_deviceIdentifier forKey:@"tkbl_device_id"];
    
    return _deviceIdentifier;
}

- (void)registerCoupon:(NSString*)coupon {
    [self storeObject:coupon forKey:TKBLCouponKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:TKBLDidReceiveCouponCode object:self userInfo:@{
        TKBLCouponKey: coupon
    }];
}

- (NSString*)coupon {
    return [self storedObjectForKey:TKBLCouponKey];
}

- (void)registerURLScheme:(NSString*)urlScheme {
    TKBLLog(@"Method %@ is deprecated and has no affect at all.", NSStringFromSelector(_cmd));
}

#pragma mark - [Handlers]

- (BOOL)handleOpenURL:(NSURL*)url {
    __block BOOL handled = NO;
    [[url.query componentsSeparatedByString:@"&"] enumerateObjectsUsingBlock:^(NSString* pair, NSUInteger idx, BOOL* stop){
        if (pair) {
            NSArray* pairComponents = [pair componentsSeparatedByString:@"="];
            NSString* name = [[pairComponents firstObject] stringByRemovingPercentEncoding];
            NSString* value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
            handled = handled || [self handleUrlParam:name withValue:value];
        }
    }];
    return handled;
}

- (BOOL)handleURLParams:(NSDictionary* _Nonnull)urlParams {
    __block BOOL handled = NO;
    [urlParams enumerateKeysAndObjectsUsingBlock:^(NSString* _Nonnull key, NSString* _Nonnull obj, BOOL * _Nonnull stop) {
        handled = [self handleUrlParam:key withValue:obj] || handled;
    }];
    return handled;
}

#pragma mark - [Integration]

- (void)registerOrigin:(TKBLOriginType)type params:(NSDictionary*)params {
    [self verifyApiKeyAndSiteSlug];
    
    NSMutableDictionary* talkableParams = [NSMutableDictionary dictionaryWithDictionary:params];
    NSString* uuid = [self visitorUUID];
    if (uuid) {
        [talkableParams setObject:uuid forKey:@"current_visitor_uuid"];
    }
    
    NSArray* originKeys = @[TKBLOriginKey, TKBLAffiliateMemberKey, TKBLPurchaseKey, TKBLEventKey];
    NSArray* filtered = [talkableParams objectsForKeys:originKeys notFoundMarker:[NSNull null]];
    NSUInteger idx = [filtered indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj isKindOfClass:[NSDictionary class]];
    }];
    NSMutableDictionary* originParams = [NSMutableDictionary dictionary];
    if (idx != NSNotFound) {
        originParams = [NSMutableDictionary dictionaryWithDictionary:[filtered objectAtIndex:idx]];
        if (originParams[TKBLPurchaseOrderItemsKey]) {
            [originParams[TKBLPurchaseOrderItemsKey] enumerateObjectsUsingBlock:^(NSDictionary* obj,
                                                                                  NSUInteger idx,
                                                                                  BOOL * _Nonnull stop) {
                if (obj[TKBLPurchaseOrderItemProductIDKey] &&
                    (obj[TKBLPurchaseOrderItemUrlKey] ||
                     obj[TKBLPurchaseOrderItemImageUrlKey] ||
                     obj[TKBLPurchaseOrderItemTitleKey])
                ) {
                    [self registerProduct:[obj dictionaryWithValuesForKeys:@[
                        TKBLPurchaseOrderItemProductIDKey,
                        TKBLPurchaseOrderItemUrlKey,
                        TKBLPurchaseOrderItemImageUrlKey,
                        TKBLPurchaseOrderItemTitleKey,
                        TKBLPurchaseOrderItemPriceKey
                    ]]];
                }
            }];
        }
    }
    [talkableParams setObject:originParams forKey:TKBLOriginKey];
    
    NSString* webUUID = [self webUUID];
    if (webUUID) {
        [originParams setObject:webUUID forKey:@"alternative_visitor_uuid"];
    }
    
    if (![originParams objectForKey:TKBLOriginTrafficSourceKey]) {
        [originParams setObject:@"ios" forKey:TKBLOriginTrafficSourceKey];
    }
    
    if (![talkableParams objectForKey:TKBLCampaignTags]) {
        if (TKBLAffiliateMember == type) {
            [talkableParams setObject:@"ios-invite" forKey:TKBLCampaignTags];
        } else if (TKBLPurchase == type) {
            [talkableParams setObject:@"ios-post-purchase" forKey:TKBLCampaignTags];
        }
    }
    
    NSURL* requestURL = [self requestURL:type params:talkableParams excludingKeys: @[
                                                                                     TKBLPurchaseOrderItemTitleKey,
                                                                                     TKBLPurchaseOrderItemUrlKey,
                                                                                     TKBLPurchaseOrderItemImageUrlKey
                                                                                     ]];
    if (![self shouldRegisterOrigin:type withURL:requestURL]) return;
    
    NSMutableURLRequest* request = [self serverRequest:requestURL];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:
     ^(NSURLResponse* response, NSData* responseData, NSError* networkError) {
         NSInteger errorCode = 0;
         NSString* errorLocalizedDescription = nil;
         NSString* errorFailureReason = TKBLFailureReasonRequestError;
         if (networkError || ![response isKindOfClass: [NSHTTPURLResponse class]]) {
             errorCode = TKBLNetworkError;
             errorLocalizedDescription = networkError ? networkError.localizedDescription : @"Invalid Response";
         } else {
             NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
             if (httpResponse.allHeaderFields[TKBLHeaderErrorCode]) {
                 errorFailureReason = httpResponse.allHeaderFields[TKBLHeaderErrorCode];
             }
             if (httpResponse.statusCode >= 500) {
                 errorCode = TKBLApiError;
                 errorLocalizedDescription = NSLocalizedString(@"Trouble reaching Talkable servers, please try again later", nil);
             } else if (httpResponse.statusCode >= 400) {
                 errorCode = TKBLRequestError;
                 errorLocalizedDescription = NSLocalizedString(@"Request can't be processed", nil);
             } else if (errorFailureReason != TKBLFailureReasonRequestError) {
                 if (errorFailureReason == TKBLFailureReasonSiteNotFound) {
                     errorCode = TKBLRequestError;
                 } else {
                     errorCode = TKBLCampaignError;
                 }
                 NSData* errorMsgDecodedData = [[NSData alloc] initWithBase64EncodedString:httpResponse.allHeaderFields[TKBLHeaderErrorMessage] ?: @""
                                                                                   options:NSDataBase64DecodingIgnoreUnknownCharacters];
                 errorLocalizedDescription = NSLocalizedString([[NSString alloc] initWithData:errorMsgDecodedData encoding:NSUTF8StringEncoding], nil);
             }
         }
         
         if (errorCode) {
             TKBLLog(@"%@: %@", errorFailureReason, errorLocalizedDescription);
             NSError* error = [NSError errorWithDomain:TKBLErrorDomain
                                                  code:errorCode
                                              userInfo:@{
                                                         NSLocalizedDescriptionKey: errorLocalizedDescription,
                                                         NSLocalizedFailureReasonErrorKey: errorFailureReason
                                                         }];
             [self notifyRegisterOrigin:type didFailWithError:error];
         } else {
             TKBLOfferViewController* controller = [[TKBLOfferViewController alloc] init];
             
             WKWebView* webView = [self buildWebView];
             [self notifyOriginDidRegister:type withWebView:webView];
             
             BOOL shouldPresent = YES;
             if ([self.delegate respondsToSelector:@selector(shouldPresentTalkableOfferViewController:)]) {
                 shouldPresent = [self.delegate shouldPresentTalkableOfferViewController:controller];
             }
             
             if (shouldPresent) {
                 [webView setNavigationDelegate:controller];
                 CGRect frame = webView.frame;
                 frame = controller.view.bounds;
                 webView.frame = frame;
                 [controller.view addSubview:webView];
                 [self presentOfferViewController:controller];
             }
             
             NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)response.textEncodingName));
             [webView loadHTMLString:[[NSString alloc] initWithData:responseData encoding:encoding] baseURL:requestURL];
         }
     }];
}

- (void)registerProduct:(NSDictionary*)productParams {
    NSURL* url = [self createProductRequestURLWithParams:productParams];
    [NSURLConnection sendAsynchronousRequest:[self serverRequest:url]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse * _Nullable response,
                                               NSData * _Nullable data,
                                               NSError * _Nullable connectionError) {
       NSString* resultDescription = [NSString new];
       if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
           NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
           resultDescription = [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode];
       } else {
           resultDescription = connectionError ? connectionError.localizedDescription : @"Invalid Response";
       }
       TKBLLog(@"Create product request resulted in: `%@` to URL: %@",
               resultDescription,
               url.absoluteString);
   }];
}

#pragma mark - [API]

- (void)createOrigin:(NSDictionary*)params withHandler:(TKBLCompletionHandler)handler {
    NSMutableDictionary* parameters = [self paramsForAPI:params];
    NSMutableDictionary* data = [NSMutableDictionary dictionaryWithDictionary:[params objectForKey:TKBLOriginDataKey]];
    
    NSString* uuid = [self visitorUUID];
    if (![data objectForKey:TKBLOriginUUIDKey] && uuid) {
        [data setObject:uuid forKey:TKBLOriginUUIDKey];
    }
    
    if (![data objectForKey:TKBLOriginTrafficSourceKey]) {
        [data setObject:@"ios" forKey:TKBLOriginTrafficSourceKey];
    }
    
    NSString* webUUID = [self webUUID];
    if (webUUID) {
        [data setObject:webUUID forKey:@"alternative_visitor_uuid"];
    }
    
    [data setObject:@"current" forKey:@"ip_address"];
    
    [parameters setObject:data forKey:TKBLOriginDataKey];
    
    NSString* urlString = [self urlForAPI:@"/origins"];
    [self logAPIRequest:urlString withMethod:@"POST" andParameters:parameters];
    [[self networkClient] POST:urlString parameters:parameters success:^(AFHTTPRequestOperation*operation, id responseObject) {
        [self processSuccessfulResponse:responseObject withHandler:handler];
    } failure:^(AFHTTPRequestOperation* operation, NSError* networkError) {
        [self processFailedResponse:operation.responseObject
                   withNetworkError:networkError
                     andWithHandler:handler];
    }];
}

- (void)retrieveRewardsWithHandler:(TKBLCompletionHandler)handler {
    [self retrieveRewards:nil withHandler:handler];
}

- (void)retrieveRewards:(NSDictionary*)params withHandler:(TKBLCompletionHandler)handler {
    NSMutableDictionary* parameters = [self paramsForAPI:params];
    
    NSString* uuid = [self visitorUUID];
    if (![parameters objectForKey:TKBLVisitorUUID] && uuid) {
        [parameters setObject:uuid forKey:TKBLVisitorUUID];
    }
    
    NSString* urlString = [self urlForAPI:@"/rewards"];
    [self logAPIRequest:urlString withMethod:@"GET" andParameters:parameters];
    [[self networkClient] GET:urlString parameters:parameters success:^(AFHTTPRequestOperation* operation, id responseObject) {
        [self processSuccessfulResponse:responseObject withHandler:handler];
    } failure:^(AFHTTPRequestOperation* operation, NSError* networkError) {
        [self processFailedResponse:operation.responseObject
                   withNetworkError:networkError
                     andWithHandler:handler];
    }];
}

- (void)retrieveOffer:(NSString*)shortUrlCode withHandler:(TKBLCompletionHandler)handler {
    [self retrieveOffer:shortUrlCode withParams:nil andHandler:handler];
}

- (void)retrieveOffer:(NSString*)shortUrlCode withParams:(NSDictionary*)params andHandler:(TKBLCompletionHandler)handler {
    NSString* path = [NSString stringWithFormat:@"/offers/%@", shortUrlCode];
    NSDictionary* parameters = [self paramsForAPI:params];
    
    NSString* urlString = [self urlForAPI:path];
    [self logAPIRequest:urlString withMethod:@"GET" andParameters:parameters];
    [[self networkClient] GET:urlString parameters:parameters success:^(AFHTTPRequestOperation* operation, id responseObject) {
        [self processSuccessfulResponse:responseObject withHandler:handler];
    } failure:^(AFHTTPRequestOperation* operation, NSError* networkError) {
        [self processFailedResponse:operation.responseObject
                   withNetworkError:networkError
                     andWithHandler:handler];
    }];
}

- (void)createShare:(NSString*)shortUrlCode channel:(NSString*)channel withHandler:(TKBLCompletionHandler)handler {
    [self createSocialShare:shortUrlCode channel:channel withParams:nil andHandler:handler];
}

- (void)createShare:(NSString*)shortUrlCode channel:(NSString*)channel withParams:(NSDictionary *)params andHandler:(TKBLCompletionHandler)handler{
    [self createSocialShare:shortUrlCode channel:channel withParams:params andHandler:handler];
}

- (void)createSocialShare:(NSString*)shortUrlCode channel:(NSString*)channel withHandler:(TKBLCompletionHandler)handler{
    [self createSocialShare:shortUrlCode channel:channel withParams:nil andHandler:handler];
}

- (void)createSocialShare:(NSString*)shortUrlCode channel:(NSString*)channel withParams:(NSDictionary *)params andHandler:(TKBLCompletionHandler)handler{
    NSString* path = [NSString stringWithFormat:@"/offers/%@/shares/social", shortUrlCode];
    NSMutableDictionary* parameters = [self paramsForAPI:params];
    [parameters setObject:channel forKey:TKBLShareChannel];
    
    NSString* urlString = [self urlForAPI:path];
    [self logAPIRequest:urlString withMethod:@"POST" andParameters:parameters];
    [[self networkClient] POST:urlString parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self processSuccessfulResponse:responseObject withHandler:handler];
    } failure:^(AFHTTPRequestOperation* operation, NSError* networkError) {
        [self processFailedResponse:operation.responseObject
                   withNetworkError:networkError
                     andWithHandler:handler];
    }];
}

- (void)createEmailShare:(NSString*)shortUrlCode recipients:(NSString *)recipients withHandler:(TKBLCompletionHandler)handler {
    [self createEmailShare:shortUrlCode recipients:recipients withParams:nil andHandler:handler];
}

- (void)createEmailShare:(NSString*)shortUrlCode recipients:(NSString*)recipients withParams:(NSDictionary*)params andHandler:(TKBLCompletionHandler)handler {
    NSString* path = [NSString stringWithFormat:@"/offers/%@/shares/email", shortUrlCode];
    NSMutableDictionary* parameters = [self paramsForAPI:params];
    [parameters setObject:recipients forKey:TKBLShareRecipients];
    
    NSString* urlString = [self urlForAPI:path];
    [self logAPIRequest:urlString withMethod:@"POST" andParameters:parameters];
    [[self networkClient] POST:urlString parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self processSuccessfulResponse:responseObject withHandler:handler];
    } failure:^(AFHTTPRequestOperation* operation, NSError* networkError) {
        [self processFailedResponse:operation.responseObject
                   withNetworkError:networkError
                     andWithHandler:handler];
    }];
}

#pragma mark - [Sharing]

- (SLComposeViewController*)socialShare:(NSDictionary*)params {
    NSString* channel = [params objectForKey:TKBLShareChannel];
    NSString* serviceType = [self mapChanel:channel];
    
    if (!serviceType) {
        TKBLLog(@"Using default chanel - %@", TKBLShareChannelFacebook);
        (void)(serviceType = SLServiceTypeFacebook),
        channel = TKBLShareChannelFacebook;
    }
    
    SLComposeViewController* controller = [SLComposeViewController composeViewControllerForServiceType:serviceType];
    
    id claimURL = [params objectForKey:TKBLOfferClaimUrlKey];
    if ([claimURL isKindOfClass:[NSString class]]) {
        [controller addURL:[NSURL URLWithString:claimURL]];
    } else if ([claimURL isKindOfClass:[NSURL class]]) {
        [controller addURL:claimURL];
    }
    
    NSString* message = [params objectForKey:TKBLShareMessage];
    if (message) {
        [controller setInitialText:message];
    }
    
    id image = [params objectForKey:TKBLShareImage];
    if ([image isKindOfClass:[UIImage class]]) {
        [controller addImage:image];
    } else if ([image isKindOfClass:[NSString class]]) {
        NSData* imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:image]];
        UIImage* requestedImage = [UIImage imageWithData:imageData];
        if (requestedImage)
            [controller addImage:requestedImage];
    }
    
    NSString* offerShortUrlCode = [params objectForKey:TKBLOfferShortUrlCodeKey];
    if (offerShortUrlCode) {
        [controller setCompletionHandler:^(SLComposeViewControllerResult result){
            if (result == SLComposeViewControllerResultDone) {
                [self createSocialShare:offerShortUrlCode channel:channel withHandler:nil];
            }
        }];
    } else {
        TKBLLog(@"Specify %@ key or create share manually.", TKBLOfferShortUrlCodeKey);
    }
    
    return controller;
}

- (UIActivityViewController*)nativeShare:(NSDictionary*)params {
    NSURL* url;
    id claimURL = [params objectForKey:TKBLOfferClaimUrlKey];
    if ([claimURL isKindOfClass:[NSString class]]) {
        url = [NSURL URLWithString:claimURL];
    } else if ([claimURL isKindOfClass:[NSURL class]]) {
        url = claimURL;
    }
    
    if (!url) {
        TKBLLog(@"Specify %@ key as NSURL object", TKBLOfferClaimUrlKey);
        return nil;
    }
    
    UIActivityViewController* controller = [[UIActivityViewController alloc] initWithActivityItems:@[claimURL] applicationActivities:nil];
    
    NSString* offerShortUrlCode = [params objectForKey:TKBLOfferShortUrlCodeKey];
    if (offerShortUrlCode) {
        [controller setCompletionWithItemsHandler:^(NSString* activityType, BOOL completed, NSArray* returnedItems, NSError*activityError) {
            if (!completed) return;
            [self createSocialShare:offerShortUrlCode channel:[self mapActivityType:activityType] withHandler:nil];
        }];
    } else {
        TKBLLog(@"Specify %@ key or create share manually.", TKBLOfferShortUrlCodeKey);
    }

    return controller;
}

#pragma mark - [UUID]

- (NSString*)generateUUID {
    return [[[NSUUID UUID] UUIDString] lowercaseString];
}

- (void)syncUUID:(NSString*)uuid forKey:(NSString*)key {
    [self storeUUID:uuid toKeychain:key];
    [self storeUUID:uuid toPref:key];
}

- (void)storeUUID:(NSString*)uuid toKeychain:(NSString*)key {
    NSData* data = [uuid dataUsingEncoding:NSUTF8StringEncoding];
    [[self keychain] storeData:data forKey:key];
}

- (NSString*)uuidFromKeychain:(NSString*)key; {
    if (self.debug && self.ignoreStoredDeviceIdentity) return nil;
    NSData* data = [[self keychain] dataForKey:key];
    return data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
}

- (void)storeUUID:(NSString*)uuid toPref:(NSString*)key {
    NSMutableDictionary* uuids = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:key] mutableCopy];
    [uuids setObject:uuid forKey:self.server];
    [[NSUserDefaults standardUserDefaults] setValue:uuids forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

- (NSString*)uuidFromPref:(NSString*)key {
    if (self.debug && self.ignoreStoredDeviceIdentity) return nil;
    return [[[NSUserDefaults standardUserDefaults] dictionaryForKey:key] objectForKey:self.server];
}

- (void)storeWebUUID:(NSString*)uuid {
    TKBLLog(@"Web UUID: %@", uuid);
    [[NSUserDefaults standardUserDefaults] setValue:uuid forKey:@"tkbl_web_uuid"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString*)webUUID {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"tkbl_web_uuid"];
}

#pragma mark - [Installed Event]

- (void)registerInstallIfNeeded {
    if (!(self.debug && self.skipFirstInstallCheck) && [TKBLHelper installRegistered]) return;
    if (!(self.debug && self.skipReinstallCheck) && [TKBLHelper wasAppUpdated]) return;
    if (![self visitorUUID] || ![self webUUID]) {
        [self retryRegisterInstall];
        return;
    }
    
    NSDictionary* originParams = @{
        TKBLOriginTypeKey: TKBLOriginTypeEvent,
        TKBLOriginDataKey: @{
            TKBLEventCategoryKey: @"ios_app_installed",
            TKBLEventNumberKey: [self deviceIdentifier]
        }
    };
    
    [self createOrigin:originParams withHandler:^(NSDictionary* response, NSError* error) {
        if (error) {
            [self retryRegisterInstall];
        } else {
            [TKBLHelper registerInstall];
            [self scheduleRetrieveRewards:0.0];
        }
    }];
}

- (void)retryRegisterInstall {
    [self scheduleRegisterInstall:30];
}

- (void)scheduleRegisterInstall:(NSTimeInterval)delay {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(registerInstallIfNeeded) object:nil];
    [self performSelector:@selector(registerInstallIfNeeded) withObject:nil afterDelay:delay];
}

#pragma mark - [Retrieve Rewards]

- (void)retrieveRewardsIfNeeded {
    [self retrieveRewardsWithHandler:^(NSDictionary* response, NSError* error) {
        if (error) {
            TKBLLog(@"%@", error.localizedDescription);
        } else {
            NSArray *rewards = (NSArray *)[response objectForKey:@"rewards"];
            if ([rewards count] > 0) {
                [rewards enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:TKBLDidReceiveReward object:self userInfo:(NSDictionary*)obj];
                }];
            }
        }
    }];
}

- (void)scheduleRetrieveRewards:(NSTimeInterval)delay {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(retrieveRewardsIfNeeded) object:nil];
    [self performSelector:@selector(retrieveRewardsIfNeeded) withObject:nil afterDelay:delay];
}

#pragma mark - [Private]

- (NSString*)applicationURLScheme {
    return [NSString stringWithFormat:@"tkbl-%@", _siteSlug];
}

- (void)checkUrlScheme {
    NSString* scheme = [self applicationURLScheme];
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://", scheme]];
    UIApplication* app = [UIApplication sharedApplication];
    if (![app canOpenURL:url]) {
        NSString* message = [NSString stringWithFormat:@"Please set up custom URL scheme `%@` in your application. Check http://docs.talkable.com/ios_sdk/getting_started.html#configuration for more details.", scheme];
        [self raiseException:NSObjectNotAvailableException withMessage:message];
    }
}

- (AFHTTPRequestOperationManager*)networkClient {
    if (!_networkClient) {
        _networkClient = [[AFHTTPRequestOperationManager alloc] init];
        [_networkClient.requestSerializer setValue:[self apiUserAgent] forHTTPHeaderField:@"User-Agent"];
        [_networkClient.requestSerializer setValue:[[NSString alloc] initWithFormat:@"Bearer %@", self.apiKey]
                                          forHTTPHeaderField:@"Authorization"];
    }
    return _networkClient;
}

- (NSString*)urlForAPI:(NSString*)path {
    return[NSString stringWithFormat:@"%@/api/%@%@", self.server, TKBL_API_VERSION, path];
}

- (NSMutableDictionary*)paramsForAPI:(NSDictionary*)params {
    NSMutableDictionary* paramsForAPI = [NSMutableDictionary dictionaryWithDictionary:params];
    [paramsForAPI setValue:self.siteSlug forKey:TKBLSiteSlug];
    return paramsForAPI;
}

- (void)logAPIRequest:(NSString*)urlString withMethod:(NSString*)method andParameters:(id)parameters {
    TKBLLog(@"%@ request to %@ with parameters: %@", method, urlString, parameters);
}

- (void)trackVisit:(NSString*)visitorOfferId {
    NSMutableDictionary* parameters = [self paramsForAPI:nil];
    NSString* path = [NSString stringWithFormat:@"/visitor_offers/%@/track_visit", visitorOfferId];
    NSString* urlString = [self urlForAPI:path];
    
    [[self networkClient] PUT:urlString parameters:parameters success:nil failure:nil];
}

- (WKWebView*)buildWebView {
    [self registerCustomUserAgent];
    
    WKWebViewConfiguration* webConfig = [[WKWebViewConfiguration alloc] init];
    WKUserContentController* contentController = [[WKUserContentController alloc] init];
    WKWebView* webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:webConfig];
    [webConfig setUserContentController:contentController];
    
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [self restoreOriginalUserAgent];
    
    TKBLOfferTarget* target = [self offerTargetFor:webView];
    [webView.configuration.userContentController addScriptMessageHandler:target name:@"talkableiOSHub"];
    
    return webView;
}

- (void)presentOfferViewController:(TKBLOfferViewController*)viewController {
    UIViewController* topViewController = nil;
    if ([self.delegate respondsToSelector:@selector(viewControllerForPresentingTalkableOfferViewController)]) {
        topViewController = [self.delegate viewControllerForPresentingTalkableOfferViewController];
    }
    if (!topViewController) {
        topViewController = [UIViewController currentViewController];
    }
    if ([topViewController isKindOfClass:[UINavigationController class]]) {
        [(UINavigationController*)topViewController pushViewController:viewController animated:YES];
    } else if (topViewController.navigationController) {
        [topViewController.navigationController pushViewController:viewController animated:YES];
    } else {
        [topViewController presentViewController:viewController animated:YES completion:nil];
    }
}

- (NSURL*)createProductRequestURLWithParams:(NSDictionary*)params {
    NSURLComponents* components = [NSURLComponents componentsWithString:self.server];
    components.path = [NSString stringWithFormat:@"/public/%@/%@/%@", self.siteSlug, @"products", @"create"];
    NSString* query = [self buildQueryFromDictonary:@{TKBLProductKey: params} andPrefix:nil];
    NSString* percentEncodedQuery = [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    components.percentEncodedQuery = percentEncodedQuery;
    return components.URL;
}

- (NSURL*)requestURL:(TKBLOriginType)type params:(NSDictionary*)params excludingKeys:(NSArray*)excludedKeys {
    NSURLComponents* components = [NSURLComponents componentsWithString:self.server];
    NSString* action = @"create";
    if (type == TKBLAffiliateMember && (![params objectForKey:@"affiliate_member"] || ![[params objectForKey:@"affiliate_member"] objectForKey:@"email"])) {
        action = @"new";
    }
    components.path = [NSString stringWithFormat:@"/public/%@/%@/%@", self.siteSlug, [self pathForType:type], action] ;
    
    NSString* query = [self buildQueryFromDictonary:params andPrefix:nil excludingKeys:excludedKeys];
    NSString* percentEncodedQuery = [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    components.percentEncodedQuery = percentEncodedQuery;
    
    return components.URL;
}

- (NSURL*)requestURL:(TKBLOriginType)type params:(NSDictionary*)params {
    return [self requestURL:type params:params excludingKeys:nil];
}

- (NSMutableURLRequest*)serverRequest:(NSURL*)url {
    return [self serverRequest:url withHttpMethod:@"GET" userAgent:[self userAgent]];
}

- (NSMutableURLRequest*)serverRequest:(NSURL*)url withHttpMethod:(NSString*)httpMethod userAgent:(NSString*)userAgent{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:httpMethod];
    [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    
    if ([self featuresJsonString]) {
        [request setValue:[self featuresJsonString] forHTTPHeaderField:@"X-Talkable-Native-Features"];
    }
    
    return request;
}

- (NSString*)featuresJsonString {
    if (!_featuresJsonString) {
        NSError* error = nil;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:[TKBLHelper featuresInfo] options:0 error:&error];
        if  (!error) {
            _featuresJsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
    }
    return _featuresJsonString;
}

- (NSString*)originalUserAgent {
    if (!_originalUserAgent) {
        _originalUserAgent = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserAgent"];
    }
    return _originalUserAgent;
}

- (void)registerCustomUserAgent {
    NSString* userAgent = [self userAgent];
    if (userAgent) {
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent": userAgent}];
    }
}

- (void)restoreOriginalUserAgent {
    if (_originalUserAgent) {
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent": _originalUserAgent}];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"UserAgent"];
    }
}

- (NSString*)userAgent {
    if (!_userAgent) {
        NSString* userAgent = [self originalUserAgent];
        if (!userAgent) {
            NSString* systemName = [[UIDevice currentDevice] model];
            NSString* systemVersion = [[UIDevice currentDevice] systemVersion];
            systemVersion = [systemVersion stringByReplacingOccurrencesOfString:@"." withString:@"_"];
            userAgent = [NSString stringWithFormat:@"%@ OS %@ webview", systemName, systemVersion];
        }
        if (userAgent) {
            NSString* userAgentSufix = [NSString stringWithFormat:@"Talkable iOS/%@", TKBLVersion];
            _userAgent = [NSString stringWithFormat:@"%@;%@", userAgent, userAgentSufix];
        }
    }
    return _userAgent;
}

- (NSString*)apiUserAgent {
    if (!_apiUserAgent) {
        _apiUserAgent = [NSString stringWithFormat:@"Talkable iOS SDK v%@", TKBLVersion];
    }
    return _apiUserAgent;
}

- (TKBLKeychainHelper*)keychain {
    if (!_keychain) {
        _keychain = [[TKBLKeychainHelper alloc] initWithService:self.server];
    }
    return _keychain;
}

- (NSString*)pathForType:(TKBLOriginType)type {
    switch (type) {
        case TKBLAffiliateMember:
            return @"affiliate_members";
        case TKBLPurchase:
            return @"purchases";
        case TKBLEvent:
            return @"events";
        default:
            [self raiseException:NSInvalidArgumentException withMessage:[NSString stringWithFormat:@"Unknown origin type - %lu", (unsigned long)type]];
            break;
    }
}

- (NSString*)buildQueryFromDictonary:(NSDictionary*)params andPrefix:(NSString*)prefix excludingKeys:(NSArray*)excludedKeys {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:[params count]];
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop) {
        if (![key isKindOfClass:[NSString class]]) {
            [self raiseException:NSInvalidArgumentException withMessage:[NSString stringWithFormat:@"Key %@ should be NSString class", key]];
        }
        if (![excludedKeys containsObject:key]) {
            NSString* keyName = prefix ? [NSString stringWithFormat:@"%@[%@]", prefix, key] : key;
            [self addKeyName:keyName value:value toArray:items excludingKeys:excludedKeys];
        }
    }];
    return [items componentsJoinedByString:@"&"];
}

- (NSString*)buildQueryFromDictonary:(NSDictionary*)params andPrefix:(NSString*)prefix {
    return [self buildQueryFromDictonary:params andPrefix:prefix excludingKeys:nil];
}

- (NSString*)buildQueryFromArray:(NSArray*)params andPrefix:(NSString*)prefix excludingNestedDictionaryKeys:(NSArray*)excludedKeys {
    if (!prefix.length) {
        [self raiseException:NSInvalidArgumentException withMessage:@"Prefix should be non-empty string"];
    }
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:[params count]];
    NSString* keyName = [NSString stringWithFormat:@"%@[]", prefix];
    [params enumerateObjectsUsingBlock:^(id value, NSUInteger idx, BOOL* stop) {
        [self addKeyName:keyName value:value toArray:items excludingKeys:excludedKeys];
    }];
    return [items componentsJoinedByString:@"&"];
}

- (NSString*)buildQueryFromArray:(NSArray*)params andPrefix:(NSString*)prefix {
    return [self buildQueryFromArray:params andPrefix:prefix excludingNestedDictionaryKeys:nil];
}

- (void)addKeyName:(NSString*)keyName value:(id)value toArray:(NSMutableArray*)items excludingKeys:(NSArray*)excludedKeys {
    if ([value isKindOfClass:[NSDictionary class]]) {
        [items addObject:[self buildQueryFromDictonary:value andPrefix:keyName excludingKeys:excludedKeys]];
    } else if ([value isKindOfClass:[NSArray class]]) {
        [items addObject:[self buildQueryFromArray:value andPrefix:keyName excludingNestedDictionaryKeys:excludedKeys]];
    } else {
        [items addObject:[NSString stringWithFormat:@"%@=%@", keyName, [self stringFromValue:value]]];
    }
}

- (NSString*)stringFromValue:(id)value {
    NSString* stringValue = nil;
    if ([value isKindOfClass:[NSString class]]) {
        stringValue = value;
    } else if ([value isKindOfClass:[NSNumber class]]) {
        stringValue = [value stringValue];
    } else if ([value isKindOfClass:[NSURL class]]) {
        stringValue = [value absoluteString];
    } else if ([value isKindOfClass:[NSDate class]]) {
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        NSLocale* enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setLocale:enUSPOSIXLocale];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
        
        stringValue = [dateFormatter stringFromDate:value]; // iso8601
    } else {
        [self raiseException:NSInvalidArgumentException withMessage:[NSString stringWithFormat:@"Invalid class %@ for parameter value.", NSStringFromClass([value class])]];
    }
    return stringValue;
}

- (NSDictionary*)channelMap {
    return @{TKBLShareChannelTwitter: SLServiceTypeTwitter, TKBLShareChannelFacebook: SLServiceTypeFacebook};
}

- (NSString*)mapChanel:(NSString*)channel {
    return [[self channelMap] objectForKey:channel];
}

- (NSString*)mapActivityType:(NSString*)activityType {
    if ([activityType isEqualToString:UIActivityTypePostToFacebook]) {
        return TKBLShareChannelFacebook;
    } else if ([activityType isEqualToString:UIActivityTypePostToTwitter]) {
        return TKBLShareChannelTwitter;
    } else {
        return TKBLShareChannelOther;
    }
}

- (void)verifyApiKeyAndSiteSlug {
    if (!self.apiKey || !self.siteSlug ||
        (self.apiKey && [self.apiKey length] == 0) ||
        (self.siteSlug && [self.siteSlug length] == 0)) {
        [self raiseException:TKBLConfigurationException withMessage:@"Specify correct apiKey and siteSlug"];
    }
}

- (BOOL)handleUrlParam:(NSString*)param withValue:(NSString*)value {
    BOOL handled = NO;
    
    // Visitor Offer
    if ([[param lowercaseString] isEqualToString:TKBLVisitorOfferKey]) {
        [self storeObject:value forKey:TKBLVisitorOfferKey];
        [self trackVisit:value];
        handled = YES;
    }
    
    // Visitor Web UUID
    if ([[param lowercaseString] isEqualToString:TKBLVisitorWebUUIDKey]) {
        [self storeWebUUID:value];
        handled = YES;
        [self scheduleRegisterInstall:0.0];
    }
    
    // Coupon
    NSCharacterSet* charactersToRemove = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    NSString* trimedParam = [[param componentsSeparatedByCharactersInSet:charactersToRemove] componentsJoinedByString:@""];
    if ([[self couponCodeParams] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return (BOOL)([obj caseInsensitiveCompare:trimedParam] == NSOrderedSame);
    }] != NSNotFound) {
        [self registerCoupon:value];
        handled = YES;
    }
    
    return handled;
}

- (NSArray*)couponCodeParams {
    if (!_couponCodeParams) {
        _couponCodeParams = @[@"coupon", @"couponcode", @"discount"];
    }
    return _couponCodeParams;
}

- (TKBLOfferTarget*)offerTargetFor:(WKWebView*) webView {
    if (!_offerTargets) {
        _offerTargets = [NSMutableArray new];
    }
    for (TKBLOfferTarget* target in _offerTargets) {
        if (![target isUsed])
            [_offerTargets removeObject:target];
    }
    TKBLOfferTarget* target = [[TKBLOfferTarget alloc] initWithWebView:webView];
    [_offerTargets addObject:target];
    return target;
}

- (void)storeObject:(id)anObject forKey:(id<NSCopying>)key {
    NSString* prefKey = [self buildPreferenceKey:key];
    if (anObject) {
        [[NSUserDefaults standardUserDefaults] setObject:anObject forKey:prefKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:prefKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id)storedObjectForKey:(id<NSCopying>)key {
    NSString* prefKey = [self buildPreferenceKey:key];
    return [[NSUserDefaults standardUserDefaults] objectForKey:prefKey];
}

- (NSString*)buildPreferenceKey:(id<NSCopying>)key {
    return [NSString stringWithFormat:@"%@-%@", self.siteSlug, key];
}

- (void)processSuccessfulResponse:(id)response withHandler:(TKBLCompletionHandler)handler {
    TKBLLog(@"Response: %@", response);
    if (handler)
        handler([(NSDictionary*)response valueForKey:@"result"], nil);
}

- (void)processFailedResponse:(id)response withNetworkError:(NSError*)networkError andWithHandler:(TKBLCompletionHandler)handler {
    TKBLLog(@"Response: %@", response);
    NSError* error = [NSError errorWithDomain:TKBLErrorDomain
                                         code:response ? TKBLApiError : TKBLNetworkError
                                     userInfo:@{NSLocalizedDescriptionKey: networkError.localizedDescription}];
    if (handler)
        handler((NSDictionary*)response, error);
}

- (void)raiseException:(NSString*)name withMessage:(NSString*)msg {
    [NSException raise:name format:@"[Talkable]: %@", msg];
}

- (BOOL)shouldRegisterOrigin:(TKBLOriginType)type withURL:(NSURL*)url {
    if ([self.delegate respondsToSelector:@selector(shouldRegisterOrigin:withURL:)]) {
        return [self.delegate shouldRegisterOrigin:type withURL:url];
    }
    return YES;
}

- (void)notifyOriginDidRegister:(TKBLOriginType)type withWebView:(WKWebView*)webView {
    if ([self.delegate respondsToSelector:@selector(didRegisterOrigin:withWebView:)]) {
        [self.delegate didRegisterOrigin:type withWebView:webView];
    }
}

- (void)notifyRegisterOrigin:(TKBLOriginType)type didFailWithError:(NSError*)error {
    if ([self.delegate respondsToSelector:@selector(registerOrigin:didFailWithError:)]) {
        [self.delegate registerOrigin:type didFailWithError:error];
    }
}

- (void)applicationDidBecomeActive:(NSNotification*)ntf {
    [self scheduleRetrieveRewards:0.0];
}

@end
