//
//  Talkable.m
//  TalkableSDK
//
//  Created by Vitalik Danchenko on 06.04.15.
//  Copyright (c) 2015 Talkable. All rights reserved.
//

#import "Talkable.h"
#import "UIViewControllerExt.h"
#import "TalkableOfferViewController.h"

#import "AFNetworking.h"

#ifndef TKBL_API_VERSION
    #define TKBL_API_VERSION    @"v2"
#endif

#ifndef TKBL_DEFAULT_SERVER
    #define TKBL_DEFAULT_SERVER @"https://www.talkable.com"
#endif

NSString*   TKBLApiKey              = @"api_key";
NSString*   TKBLSiteSlug            = @"site_slug";

@implementation Talkable {
    AFHTTPRequestOperationManager*  _networkClient;
    NSString*                       _originalUserAgent;
    NSMutableSet*                   _uuidRequests;
}

@synthesize apiKey, siteSlug, delegate, server = _server, debug;

#pragma mark - [Singleton]

+ (Talkable*)sharedInstance {
    static Talkable* _sharedInstance = nil;
    if (_sharedInstance == nil) {
        @synchronized(self) {
            if (_sharedInstance == nil) {
                _sharedInstance = [[super allocWithZone:NULL] init];
            }
        }
    }
    return _sharedInstance;
}

+ (id)allocWithZone:(NSZone*)zone {
    [NSException raise:NSInternalInconsistencyException
                format:@"[%@ %@] cannot be called; use +[%@ %@] instead",
     NSStringFromClass(self), NSStringFromSelector(_cmd),
     NSStringFromClass(self),
     NSStringFromSelector(@selector(sharedInstance))];
    return nil;
}

- (id)init {
    if (self = [super init]) {
        _uuidRequests = [[NSMutableSet alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shareActionNotification:) name:TKBLOfferDidSendShareActionNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

# pragma mark - [Setters and Getters]

- (void)setServer:(NSString*)server {
    _server = server;
    [self visitorUUID]; // make sure visitor UUID for new server created
}

# pragma mark - [Public]

- (void)setApiKey:(NSString*)aApiKey andSiteSlug:(NSString*)aSiteSlug server:(NSString*)aServer {
    if (!aApiKey || !aSiteSlug) {
        [self raiseInvalidArgumentException:@"You can not use nil for apiKey and siteSlug"];
    }
    
    self.apiKey     = aApiKey;
    self.siteSlug   = aSiteSlug;
    self.server     = aServer ? aServer : TKBL_DEFAULT_SERVER;
}

- (void)setApiKey:(NSString*)aApiKey andSiteSlug:(NSString*)aSiteSlug {
    [self setApiKey:aApiKey andSiteSlug:aSiteSlug server:TKBL_DEFAULT_SERVER];
}

- (NSString*)visitorUUID {
    NSDictionary* uuids = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"talkable-visitor-uuids"];
    NSString* uuid = [uuids objectForKey:self.server];
    
    if (uuid)
        return uuid;
    
    uuid = [self requestVisitorUUID];
    if (uuid) {
        NSMutableDictionary* _uuids = [NSMutableDictionary dictionaryWithDictionary:uuids];
        [_uuids setObject:uuid forKey:self.server];
        [[NSUserDefaults standardUserDefaults] setValue:_uuids forKey:@"talkable-visitor-uuids"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return uuid;
}

#pragma mark - [Integration]

- (void)registerOrigin:(TKBLOriginType)type params:(NSDictionary*)params {
    [self verifyApiKeyAndSiteSlug];
    
    NSMutableDictionary* talkableParams = [NSMutableDictionary dictionaryWithDictionary:params];
    NSString* uuid = [self visitorUUID];
    if (uuid) {
        [talkableParams setObject:uuid forKey:@"current_visitor_uuid"];
    }
    
    NSURLRequest* serverRequest = [self serverRequest:type params:talkableParams];
    [self notifyOriginDidRegister:type withURL:[serverRequest URL]];
    
    TalkableOfferViewController* controller = [[TalkableOfferViewController alloc] init];
    
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
    
    [webView loadRequest: serverRequest];
    [self restoreUserAgent];
}


#pragma mark - [API]

- (void)createOrigin:(NSDictionary*)params withHandler:(TKBLCompletionHandler)handler {
    NSMutableDictionary* parameters = [self paramsForAPI:params];
    NSMutableDictionary* data = [NSMutableDictionary dictionaryWithDictionary:[params objectForKey:@"data"]];
    
    NSString* uuid = [self visitorUUID];
    if (![data objectForKey:TKBLOriginUUIDKey] && uuid) {
        [data setObject:uuid forKey:TKBLOriginUUIDKey];
    }
    [data setObject:@"current" forKey:@"ip_address"];
    
    [parameters setObject:data forKey:@"data"];
    
    [[self networkClient] POST:[self urlForAPI:@"/origins"] parameters:parameters success:^(AFHTTPRequestOperation*operation, id responseObject) {
        [self processSuccessfulResponse:responseObject withHandler:handler];
    } failure:^(AFHTTPRequestOperation* operation, NSError* networkError) {
        [self processFailedResponse:operation.responseObject
                   withNetworkError:networkError
                     andWithHandler:handler];
    }];
}

- (void)retrieveRewards:(NSDictionary*)params withHandler:(TKBLCompletionHandler)handler {
    [[self networkClient] GET:[self urlForAPI:@"/rewards"] parameters:[self paramsForAPI:params] success:^(AFHTTPRequestOperation* operation, id responseObject) {
        [self processSuccessfulResponse:responseObject withHandler:handler];
    } failure:^(AFHTTPRequestOperation* operation, NSError* networkError) {
        [self processFailedResponse:operation.responseObject
                   withNetworkError:networkError
                     andWithHandler:handler];
    }];
}

- (void)retrieveOffer:(NSDictionary*)params withHandler:(TKBLCompletionHandler)handler {
    NSString* shortUrlCode = [params objectForKey:TKBLOfferShortUrlCodeKey];
    NSString* path = [NSString stringWithFormat:@"/offers/%@", shortUrlCode];
    
    [[self networkClient] GET:[self urlForAPI:path] parameters:[self paramsForAPI:params] success:^(AFHTTPRequestOperation* operation, id responseObject) {
        [self processSuccessfulResponse:responseObject withHandler:handler];
    } failure:^(AFHTTPRequestOperation* operation, NSError* networkError) {
        [self processFailedResponse:operation.responseObject
                   withNetworkError:networkError
                     andWithHandler:handler];
    }];
}

- (void)createShare:(NSDictionary*)params withHandler:(TKBLCompletionHandler)handler {
    NSString* shortUrlCode = [params objectForKey:TKBLOfferShortUrlCodeKey];
    NSString* path = [NSString stringWithFormat:@"/offers/%@/shares", shortUrlCode];
    
    [[self networkClient] POST:[self urlForAPI:path] parameters:[self paramsForAPI:params] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self processSuccessfulResponse:responseObject withHandler:handler];
    } failure:^(AFHTTPRequestOperation* operation, NSError* networkError) {
        [self processFailedResponse:operation.responseObject
                   withNetworkError:networkError
                     andWithHandler:handler];
    }];
}

#pragma mark - [Sharing]


- (SLComposeViewController*)socialShare:(NSDictionary*)params {
    NSString* channel = [self mapChanel:[params objectForKey:TKBLShareChannel]];
    
    if (!channel) {
        TKBLLog(@"Using default chanel - %@", TKBLShareChannelFacebook);
        channel = SLServiceTypeFacebook;
    }
    
    SLComposeViewController* controller = [SLComposeViewController composeViewControllerForServiceType:channel];
    
    id claimURL = [params objectForKey:TKBLOfferClaimUrlKey];
    if ([claimURL isKindOfClass:[NSString class]]) {
        [controller addURL:[NSURL URLWithString:claimURL]];
    } else if ([claimURL isKindOfClass:[NSURL class]]) {
        [controller addURL:claimURL];
    }
    
    NSString* title = [params objectForKey:TKBLShareTitle];
    if (title) {
        [controller setInitialText:title];
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
                [self createShare:@{TKBLOfferShortUrlCodeKey: offerShortUrlCode, TKBLShareChannel: channel} withHandler:nil];
            }
        }];
    } else {
        TKBLLog(@"Specify %@ key or create share manually.", TKBLOfferShortUrlCodeKey);
    }
    
    return controller;
}

- (UIActivityViewController*)nativeShare:(NSDictionary*)params {
    id claimURL = [params objectForKey:TKBLOfferClaimUrlKey];
    if (!claimURL || ![claimURL isKindOfClass:[NSURL class]]) {
        TKBLLog(@"Specify %@ key as NSURL object", TKBLOfferClaimUrlKey);
        return nil;
    }
    
    UIActivityViewController* controller = [[UIActivityViewController alloc] initWithActivityItems:@[claimURL] applicationActivities:nil];
    
    NSString* offerShortUrlCode = [params objectForKey:TKBLOfferShortUrlCodeKey];
    if (offerShortUrlCode) {
        [controller setCompletionWithItemsHandler:^(NSString* activityType, BOOL completed, NSArray* returnedItems, NSError*activityError) {
            if (!completed) return;
            [self createShare:@{TKBLOfferShortUrlCodeKey: offerShortUrlCode, TKBLShareChannel: [self mapActivityType:activityType]} withHandler:nil];
        }];
    } else {
        TKBLLog(@"Specify %@ key or create share manually.", TKBLOfferShortUrlCodeKey);
    }

    return controller;
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

- (NSString*)requestVisitorUUID {
    NSString* params = [NSString stringWithFormat:@"%@=%@&%@=%@", TKBLApiKey, self.apiKey, TKBLSiteSlug, self.siteSlug];
    NSString* path = [NSString stringWithFormat:@"/visitors?%@", params];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self urlForAPI:path]]];
    [request setHTTPMethod:@"POST"];
    
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    if (!responseData)
        return nil;
    
    NSDictionary* response = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
    
    return [[response objectForKey:@"result"] objectForKey:@"uuid"];
}

- (void)requestVisitorUUIDAsync {
    if ([_uuidRequests containsObject:self.server])
        return;

    [_uuidRequests addObject:self.server];

    [[self networkClient] POST:[self urlForAPI:@"/visitors"] parameters:[self paramsForAPI:nil] success:
     ^(AFHTTPRequestOperation* operation, id responseObject) {
         NSMutableDictionary* uuids = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"talkable-visitor-uuids"]];
         NSString* uuid = [[(NSDictionary*)responseObject valueForKey:@"result"] objectForKey:@"uuid"];
         [uuids setObject:uuid forKey:self.server];
         [[NSUserDefaults standardUserDefaults] setValue:uuids forKey:@"talkable-visitor-uuids"];
         [[NSUserDefaults standardUserDefaults] synchronize];
         [_uuidRequests removeObject:self.server];
     } failure:
     ^(AFHTTPRequestOperation* operation, NSError* error) {
         [_uuidRequests removeObject:self.server];
     }];
}

- (UIWebView*)buildWebView {
    [self registerCustomUserAgent];
    UIWebView* webView = [[UIWebView alloc] init];
    webView.scalesPageToFit = YES;
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    webView.delegate = self;
    return webView;
}

- (void)presentOfferViewController:(TalkableOfferViewController*)viewController {
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

- (NSURLRequest*)serverRequest:(TKBLOriginType)type params:(NSDictionary*)params {
    NSURLComponents* components = [NSURLComponents componentsWithString:self.server];
    NSString* action = @"create";
    if (type == TKBLAffiliateMember && (![params objectForKey:@"affiliate_member"] || ![[params objectForKey:@"affiliate_member"] objectForKey:@"email"])) {
        action = @"new";
    }
    components.path = [NSString stringWithFormat:@"/public/%@/%@/%@", self.siteSlug, [self pathForType:type], action] ;
    components.queryItems = [self buildQueryItemsFromDictonary:params andPrefix:nil];
    
    NSURL* url = components.URL;
    
    return [NSURLRequest requestWithURL: url];
}

- (void)registerCustomUserAgent {
    if (!_originalUserAgent) {
        _originalUserAgent = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserAgent"];
    }
    NSString* userAgent = _originalUserAgent;
    if (!userAgent) {
        UIWebView*  webView = [[UIWebView alloc] init];
        userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    }
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent": [NSString stringWithFormat:@"%@;%@", userAgent, [self userAgent]]}];
}

- (void)restoreUserAgent {
    if (_originalUserAgent) {
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent": _originalUserAgent}];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"UserAgent"];
    }
}

- (NSString*)userAgent {
    return [NSString stringWithFormat:@"Talkable iOS/%@", TKBLVersion];
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
            [self raiseInvalidArgumentException:[NSString stringWithFormat:@"Unknown origin type - %lu", (unsigned long)type]];
            break;
    }
}

- (NSArray*)buildQueryItemsFromDictonary:(NSDictionary*)params andPrefix:(NSString*)prefix {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:[params count]];
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop) {
        if (![key isKindOfClass:[NSString class]]) {
            [self raiseInvalidArgumentException:[NSString stringWithFormat:@"Key %@ should be NSString class", key]];
        }
        NSString* keyName = prefix ? [NSString stringWithFormat:@"%@[%@]", prefix, key] : key;
        [self addKeyName:keyName value:value toArray:items];
    }];
    return [NSArray arrayWithArray:items];
}

- (NSArray*)buildQueryItemsFromArray:(NSArray*)params andPrefix:(NSString*)prefix {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:[params count]];
    [params enumerateObjectsUsingBlock:^(id value, NSUInteger idx, BOOL* stop) {
        NSString* keyName = prefix ?
        [NSString stringWithFormat:@"%@[%lu]", prefix, (unsigned long)idx] :
        [NSString stringWithFormat:@"%lu", (unsigned long)idx];
        [self addKeyName:keyName value:value toArray:items];
    }];
    return [NSArray arrayWithArray:items];
}

- (void)addKeyName:(NSString*)keyName value:(id)value toArray:(NSMutableArray*)items {
    if ([value isKindOfClass:[NSString class]]) {
        [items addObject:[NSURLQueryItem queryItemWithName: keyName value:value]];
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        [items addObjectsFromArray:[self buildQueryItemsFromDictonary:value andPrefix:keyName]];
    } else if ([value isKindOfClass:[NSArray class]]) {
        [items addObjectsFromArray:[self buildQueryItemsFromArray:value andPrefix:keyName]];
    }
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
    } else if (UIActivityTypePostToTwitter) {
        return TKBLShareChannelTwitter;
    } else {
        return TKBLShareChannelOther;
    }
}

- (void)verifyApiKeyAndSiteSlug {
    if (!self.apiKey || !self.siteSlug ||
        (self.apiKey && [self.apiKey length] == 0) ||
        (self.siteSlug && [self.siteSlug length] == 0)) {
        [self raiseInvalidArgumentException:@"Specify correct apiKey and siteSlug"];
    }
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

- (void)raiseInvalidArgumentException:(NSString*)msg {
    [NSException raise:NSInvalidArgumentException format:@"[Talkable]: %@", msg];
}

- (void)notifyOriginDidRegister:(TKBLOriginType)type withURL:(NSURL*)url {
    if ([self.delegate respondsToSelector:@selector(didRegisterOrigin:withURL:)]) {
        [self.delegate didRegisterOrigin:type withURL:url];
    }
}

- (void)notifyOriginDidRegister:(TKBLOriginType)type withWebView:(UIWebView*)webView {
    if ([self.delegate respondsToSelector:@selector(didRegisterOrigin:withWebView:)]) {
        [self.delegate didRegisterOrigin:type withWebView:webView];
    }
}

#pragma mark - [Notifications]

- (void)shareActionNotification:(NSNotification*)ntf {
    SLComposeViewController* shareController = [[Talkable sharedInstance] socialShare:ntf.userInfo];
    
    NSString* channel = [ntf.userInfo objectForKey:TKBLShareChannel];
    if (channel && [[ntf object] isKindOfClass:[UIWebView class]]) {
        [shareController setCompletionHandler:^(SLComposeViewControllerResult result) {
            if (result == SLComposeViewControllerResultDone) {
                [[ntf object] stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Talkable.shareSucceeded('%@');", channel]];
            }
        }];
    }
    
    [[UIViewController currentViewController] presentViewController:shareController animated:YES completion:nil];
}

@end
