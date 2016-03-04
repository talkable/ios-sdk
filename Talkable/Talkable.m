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
#import "TKBLUUIDExtractor.h"
#import "TKBLOfferChecker.h"
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

NSString*   TKBLApiKey              = @"api_key";
NSString*   TKBLSiteSlug            = @"site_slug";
NSString*   TKBLVisitorOfferKey     = @"visitor_offer_id";
NSString*   TKBLVisitorWebUUIDKey   = @"current_visitor_uuid";
NSString*   TKBLCouponKey           = @"coupon";

@implementation Talkable {
    AFHTTPRequestOperationManager*  _networkClient;
    NSString*                       _userAgent;
    NSString*                       _originalUserAgent;
    NSArray* __strong               _couponCodeParams;
    NSString*                       _uuid;
    NSString*                       _appURLSchema;
    TKBLOfferChecker*               _offerChecker;
}

@synthesize apiKey, siteSlug, delegate, server = _server, debug;

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
    if (NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_7_0) {
        NSLog(@"TalkableSDK suports iOS7.0 and later.");
        return NO;
    }
    TKBLObjCChecker* checker = [[TKBLObjCChecker alloc] init];
    if (![checker flagExist]) {
        NSLog(@"Add -ObjC to Other Linker Flags to use TalkableSDK. More details at https://developer.apple.com/library/ios/qa/qa1490/_index.html");
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
    
    if (!_uuid) _uuid = [self uuidFromKeychain];
    if (!_uuid) _uuid = [self uuidFromPref];
    if (!_uuid) _uuid = [self uuidFromServer];
    if (_uuid) [self syncUUID:_uuid];
    
    return _uuid;
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
    _appURLSchema = urlScheme;
    [self extractWebUUID];
}

#pragma make - [Handlers]

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

#pragma mark - [Integration]

- (void)registerOrigin:(TKBLOriginType)type params:(NSDictionary*)params {
    [self verifyApiKeyAndSiteSlug];
    
    NSMutableDictionary* talkableParams = [NSMutableDictionary dictionaryWithDictionary:params];
    NSString* uuid = [self visitorUUID];
    if (uuid) {
        [talkableParams setObject:uuid forKey:@"current_visitor_uuid"];
    }
    
    NSString* webUUID = [self webUUID];
    if (webUUID) {
        NSArray* originKeys = @[TKBLOriginKey, TKBLAffiliateMemberKey, TKBLPurchaseKey, TKBLEventKey];
        NSArray* filtered = [talkableParams objectsForKeys:originKeys notFoundMarker:[NSNull null]];
        NSUInteger idx = [filtered indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj isKindOfClass:[NSDictionary class]];
        }];
        NSMutableDictionary* originParams = nil;
        if (idx != NSNotFound) {
            originParams = [NSMutableDictionary dictionaryWithDictionary:[filtered objectAtIndex:idx]];
            [originParams setObject:webUUID forKey:@"alternative_visitor_uuid"];
            [talkableParams setObject:originParams forKey:[originKeys objectAtIndex:idx]];
        } else {
            originParams = [NSMutableDictionary dictionaryWithObject:webUUID forKey:@"alternative_visitor_uuid"];
            [talkableParams setObject:originParams forKey:TKBLOriginKey];
        }
    }
    
    if (![talkableParams objectForKey:TKBLCampaignTags]) {
        if (TKBLAffiliateMember == type) {
            [talkableParams setObject:@"invite" forKey:TKBLCampaignTags];
        } else if (TKBLPurchase == type) {
            [talkableParams setObject:@"post-purchase" forKey:TKBLCampaignTags];
        }
    }
    
    NSURL* requestURL = [self requestURL:type params:talkableParams];
    if (![self shouldRegisterOrigin:type withURL:requestURL]) return;
    
    NSMutableURLRequest* request = [self serverRequest:requestURL];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:
     ^(NSURLResponse* response, NSData* responseData, NSError* networkError) {
         NSInteger errorCode = 0;
         NSString* errorLocalizedDescription = nil;
         if (networkError || ![response isKindOfClass: [NSHTTPURLResponse class]]) {
             errorCode = TKBLNetworkError;
             errorLocalizedDescription = networkError ? networkError.localizedDescription : @"Invalid Response";
         } else {
             NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
             if (httpResponse.statusCode >= 500) {
                 errorCode = TKBLApiError;
                 errorLocalizedDescription = NSLocalizedString(@"Trouble reaching Talkable servers, please try again later", nil);
             } else if (httpResponse.statusCode >= 400) {
                 errorCode = TKBLRequestError;
                 errorLocalizedDescription = NSLocalizedString(@"Request can't be processed", nil);
             }
         }
         
         if (errorLocalizedDescription) {
             TKBLLog(@"%@", errorLocalizedDescription);
             NSError* error = [NSError errorWithDomain:TKBLErrorDomain
                                                  code:errorCode
                                              userInfo:@{NSLocalizedDescriptionKey: errorLocalizedDescription}];
             [self notifyRegisterOrigin:type didFailWithError:error];
             return;
         }
         
         [[self offerChecker] performWithContent:responseData MIMEType:response.MIMEType textEncodingName:response.textEncodingName baseURL:requestURL callback:^(BOOL isExist, NSString* localizedErrorMessage) {
             if (!isExist) {
                 TKBLLog(@"%@", localizedErrorMessage);
                 NSError* error = [NSError errorWithDomain:TKBLErrorDomain
                                                      code:TKBLCampaignError
                                                  userInfo:@{NSLocalizedDescriptionKey: localizedErrorMessage}];
                 [self notifyRegisterOrigin:type didFailWithError:error];
             } else {
                 TKBLOfferViewController* controller = [[TKBLOfferViewController alloc] init];
                 
                 UIWebView* webView = [self buildWebView];
                 [self notifyOriginDidRegister:type withWebView:webView];
                 
                 BOOL shouldPresent = YES;
                 if ([self.delegate respondsToSelector:@selector(shouldPresentTalkableOfferViewController:)]) {
                     shouldPresent = [self.delegate shouldPresentTalkableOfferViewController:controller];
                 }
                 
                 if (shouldPresent) {
                     [webView setDelegate:controller];
                     CGRect frame = webView.frame;
                     frame = controller.view.bounds;
                     webView.frame = frame;
                     [controller.view addSubview:webView];
                     [self presentOfferViewController:controller];
                 }
                 
                 [webView loadData:responseData MIMEType:response.MIMEType textEncodingName:response.textEncodingName baseURL:requestURL];
             }
         }];
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
    [self createShare:shortUrlCode channel:channel withParams:nil andHandler:handler];
}

- (void)createShare:(NSString*)shortUrlCode channel:(NSString*)channel withParams:(NSDictionary *)params andHandler:(TKBLCompletionHandler)handler{
    NSString* path = [NSString stringWithFormat:@"/offers/%@/shares", shortUrlCode];
    NSMutableDictionary* parameters = [self paramsForAPI:params];
    [parameters setObject:channel forKey:TKBLShareChannel];
    
    NSString* urlString = [self urlForAPI:path];
    [self logAPIRequest:urlString withMethod:@"GET" andParameters:parameters];
    [[self networkClient] POST:[self urlForAPI:path] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
        serviceType = SLServiceTypeFacebook,
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
                [self createShare:offerShortUrlCode channel:channel withHandler:nil];
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
            [self createShare:offerShortUrlCode channel:[self mapActivityType:activityType] withHandler:nil];
        }];
    } else {
        TKBLLog(@"Specify %@ key or create share manually.", TKBLOfferShortUrlCodeKey);
    }

    return controller;
}

#pragma mark - [UUID]

- (void)syncUUID:(NSString*)uuid {
    [self storeUUIDToKeychain:uuid];
    [self storeUUIDToPref:uuid];
}

- (void)storeUUIDToKeychain:(NSString*)uuid {
    NSMutableDictionary* keychainItem = [self keychainItem];
    SecItemDelete((__bridge CFDictionaryRef)keychainItem);
    keychainItem[(__bridge id)kSecValueData] = [uuid dataUsingEncoding:NSUTF8StringEncoding];
    SecItemAdd((__bridge CFDictionaryRef)keychainItem, NULL);
}

- (NSString*)uuidFromKeychain {
    OSStatus status;
    NSMutableDictionary* keychainQueryItem = [self keychainItem];
    keychainQueryItem[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    keychainQueryItem[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
    keychainQueryItem[(__bridge id)kSecReturnAttributes] = (__bridge id)kCFBooleanTrue;
    CFDictionaryRef resultItem = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)keychainQueryItem, (CFTypeRef*)&resultItem);
    if (status != noErr) {
        return nil;
    }
    NSDictionary* resultDict = (__bridge_transfer NSDictionary*)resultItem;
    NSData* data = resultDict[(__bridge id)kSecValueData];
    if (!data) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSMutableDictionary*)keychainItem {
    NSMutableDictionary* keychainItem = [[NSMutableDictionary alloc] init];
    keychainItem[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    keychainItem[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAlways;
    keychainItem[(__bridge id)kSecAttrAccount] = @"tkbl_uuid";
    keychainItem[(__bridge id)kSecAttrService] = self.server;
    return keychainItem;
}

- (void)storeUUIDToPref:(NSString*)uuid {
    NSMutableDictionary* uuids = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"tkbl_uuids"] mutableCopy];
    [uuids setObject:uuid forKey:self.server];
    [[NSUserDefaults standardUserDefaults] setValue:uuids forKey:@"tkbl_uuids"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

- (NSString*)uuidFromPref {
    return [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"tkbl_uuids"] objectForKey:self.server];
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
    if ([TKBLHelper installRegistered]) return;
    if ([TKBLHelper wasAppUpdated]) return;
    if (![self visitorUUID] || ![self webUUID]) {
        [self retryRegisterInstall];
        return;
    }
    
    NSDictionary* originParams = @{
        TKBLOriginTypeKey: TKBLOriginTypeEvent,
        TKBLOriginDataKey: @{
            TKBLEventCategoryKey: @"app-installed",
            TKBLEventNumberKey: [[[[UIDevice currentDevice] identifierForVendor] UUIDString] lowercaseString]
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

- (AFHTTPRequestOperationManager*)networkClient {
    if (!_networkClient) {
        _networkClient = [[AFHTTPRequestOperationManager alloc] init];
        [_networkClient.requestSerializer setValue:[self userAgent] forHTTPHeaderField:@"User-Agent"];
    }
    return _networkClient;
}

- (NSString*)urlForAPI:(NSString*)path {
    return[NSString stringWithFormat:@"%@/api/%@%@", self.server, TKBL_API_VERSION, path];
}

- (NSMutableDictionary*)paramsForAPI:(NSDictionary*)params {
    NSMutableDictionary* paramsForAPI = [NSMutableDictionary dictionaryWithDictionary:params];
    [paramsForAPI setValue:self.apiKey forKey:TKBLApiKey];
    [paramsForAPI setValue:self.siteSlug forKey:TKBLSiteSlug];
    return paramsForAPI;
}

- (void)logAPIRequest:(NSString*)urlString withMethod:(NSString*)method andParameters:(id)parameters {
    TKBLLog(@"%@ request to %@ with parameters: %@", method, urlString, parameters);
}

- (NSString*)uuidFromServer {
    NSString* params = [NSString stringWithFormat:@"%@=%@&%@=%@", TKBLApiKey, self.apiKey, TKBLSiteSlug, self.siteSlug];
    NSString* path = [NSString stringWithFormat:@"/visitors?%@", params];
    
    
    NSMutableURLRequest* request = [self serverRequest:[NSURL URLWithString:[self urlForAPI:path]] withHttpMethod:@"POST"];
    
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    if (!responseData)
        return nil;
    
    NSDictionary* response = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
    
    return [[response objectForKey:@"result"] objectForKey:@"uuid"];
}

- (void)extractWebUUID {
    if ([SFSafariViewController class] != nil && _appURLSchema && self.server && self.siteSlug) {
        if (UIApplicationStateActive == [[UIApplication sharedApplication] applicationState]) {
            [[TKBLUUIDExtractor extractor] extractFromServer:self.server withSiteSlug:self.siteSlug andAppSchema:_appURLSchema];
        }
    }
}

- (UIWebView*)buildWebView {
    [self registerCustomUserAgent];
    UIWebView* webView = [[UIWebView alloc] init];
    webView.scalesPageToFit = YES;
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    webView.delegate = self;
    [self restoreOriginalUserAgent];
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

- (NSURL*)requestURL:(TKBLOriginType)type params:(NSDictionary*)params {
    NSURLComponents* components = [NSURLComponents componentsWithString:self.server];
    NSString* action = @"create";
    if (type == TKBLAffiliateMember && (![params objectForKey:@"affiliate_member"] || ![[params objectForKey:@"affiliate_member"] objectForKey:@"email"])) {
        action = @"new";
    }
    components.path = [NSString stringWithFormat:@"/public/%@/%@/%@", self.siteSlug, [self pathForType:type], action] ;
    
    NSString* query = [self buildQueryFromDictonary:params andPrefix:nil];
    NSString* percentEncodedQuery = [[query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    components.percentEncodedQuery = percentEncodedQuery;

    return components.URL;
}

- (NSMutableURLRequest*)serverRequest:(NSURL*)url {
    return [self serverRequest:url withHttpMethod:@"GET"];
}

- (NSMutableURLRequest*)serverRequest:(NSURL*)url withHttpMethod:(NSString*)httpMethod {
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:httpMethod];
    [request setValue:[self userAgent] forHTTPHeaderField:@"User-Agent"];
    return request;
}

- (NSString*)originalUserAgent {
    if (!_originalUserAgent) {
        _originalUserAgent = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserAgent"];
    }
    return _originalUserAgent;
}

- (void)registerCustomUserAgent {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent": [self userAgent]}];
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
            UIWebView*  webView = [[UIWebView alloc] init];
            userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        }
        NSString* userAgentSufix = [NSString stringWithFormat:@"Talkable iOS/%@", TKBLVersion];
        _userAgent = [NSString stringWithFormat:@"%@;%@", userAgent, userAgentSufix];
    }
    return _userAgent;
}

- (TKBLOfferChecker*)offerChecker {
    if (!_offerChecker) {
        _offerChecker = [[TKBLOfferChecker alloc] init];
    }
    return _offerChecker;
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

- (NSString*)buildQueryFromDictonary:(NSDictionary*)params andPrefix:(NSString*)prefix {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:[params count]];
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop) {
        if (![key isKindOfClass:[NSString class]]) {
            [self raiseException:NSInvalidArgumentException withMessage:[NSString stringWithFormat:@"Key %@ should be NSString class", key]];
        }
        NSString* keyName = prefix ? [NSString stringWithFormat:@"%@[%@]", prefix, key] : key;
        [self addKeyName:keyName value:value toArray:items];
    }];
    return [items componentsJoinedByString:@"&"];
}

- (NSString*)buildQueryFromArray:(NSArray*)params andPrefix:(NSString*)prefix {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:[params count]];
    [params enumerateObjectsUsingBlock:^(id value, NSUInteger idx, BOOL* stop) {
        NSString* keyName = prefix ?
        [NSString stringWithFormat:@"%@[%lu]", prefix, (unsigned long)idx] :
        [NSString stringWithFormat:@"%lu", (unsigned long)idx];
        [self addKeyName:keyName value:value toArray:items];
    }];
    return [items componentsJoinedByString:@"&"];
}

- (void)addKeyName:(NSString*)keyName value:(id)value toArray:(NSMutableArray*)items {
    if ([value isKindOfClass:[NSDictionary class]]) {
        [items addObject:[self buildQueryFromDictonary:value andPrefix:keyName]];
    } else if ([value isKindOfClass:[NSArray class]]) {
        [items addObject:[self buildQueryFromArray:value andPrefix:keyName]];
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

- (void)notifyOriginDidRegister:(TKBLOriginType)type withWebView:(UIWebView*)webView {
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
    [self extractWebUUID];
    [self scheduleRegisterInstall:0.0];
    [self scheduleRetrieveRewards:0.0];
}

@end
