//
//  JasonAppDelegate.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonAppDelegate.h"
#import "JasonLogger.h"

@interface JasonAppDelegate ()
// need to globally define webview or else javascript evaluation fails from objective c dropping it out of scope
@property(strong,nonatomic) WKWebView *webView;
@end


@implementation JasonAppDelegate

- (void)init_extensions: (NSDictionary *)launchOptions{
    // 1. Find json files that start with $
    // 2. For each file, see if the class contains an "initialize" class method
    // 3. If so, run them one by one.
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourcePath error:nil];
    NSArray *jrs = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(self ENDSWITH[c] '.json') AND (self BEGINSWITH[c] '$')"]];
    
    NSError *error = nil;
    for(int i = 0 ; i < jrs.count; i++){
        NSString *filename = jrs[i];
        NSString *absolute_path = [NSString stringWithFormat:@"%@/%@", resourcePath, filename];
        NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:absolute_path];
        [inputStream open];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithStream: inputStream options:kNilOptions error:&error];
        [inputStream close];
        if(json[@"classname"]){
            [self init_class:json[@"classname"] withLaunchOptions:launchOptions];
        }
    }
    
    
}
- (void) init_class: (NSString *)className withLaunchOptions: (NSDictionary *)launchOptions{
    Class ActionClass = NSClassFromString(className);
    id service;
    
    if([Jason client].services && [Jason client].services[className]){
        service = [Jason client].services[className];
    } else {
        service = [[ActionClass alloc] init];
        [Jason client].services[className] = service;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [service performSelector: @selector(initialize:) withObject: launchOptions];
#pragma clang diagnostic pop
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:@"_UIConstraintBasedLayoutLogUnsatisfiable"];

    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024 diskCapacity:20 * 1024 * 1024 diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];
    
    // # initialize
    // Run "initialize" for built-in daemon type actions
    NSArray *native_daemon_actions = @[@"JasonPushService", @"JasonVisionService", @"JasonWebsocketService", @"JasonAgentService"];
    for(NSString *action in native_daemon_actions) {
        [self init_class:action withLaunchOptions:launchOptions];
    }
    // Run "initialize" method for all extensions
    [self init_extensions: launchOptions];

    // Appending custom string on user agent so we can identify when we're using a webview embedded in the app
    _webView = [[WKWebView alloc] initWithFrame:CGRectZero];

    [_webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if (error) {
            DTLogWarning(@"Missing User Agent%@", error);
        } else {
            NSString *userAgent = result;
            NSString *agent = [NSString stringWithFormat:@"%@ Finalsite-App/%@ Safari", userAgent, [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];

            NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:agent, @"UserAgent", nil];
            [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
        }
    }];

    if(launchOptions && launchOptions.count > 0 && launchOptions[UIApplicationLaunchOptionsURLKey]){
        // launched with url. so wait until openURL is called.
        self.launchURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
        
    } else if(launchOptions && launchOptions.count > 0 && [launchOptions objectForKey: UIApplicationLaunchOptionsRemoteNotificationKey]){
        // launched with push notification.
        [[Jason client] start: nil];
    } else {
        [[Jason client] start:nil];
    }

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (self.launchURL) {
        [self openURL:self.launchURL type: @"start"];
        self.launchURL = nil;
    }
}

- (BOOL) openURL: (NSURL *) url type: (NSString *) type{
    if([[url absoluteString] containsString:@"://oauth"]){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"oauth_callback" object:nil userInfo:@{@"url": url}];
    } else if ([[url absoluteString] containsString:@"://href?"]){
        NSString *u = [url absoluteString];
        NSString *href_url = [JasonHelper getParamValueFor:@"url" fromUrl:u];
        NSString *href_view = [JasonHelper getParamValueFor:@"view" fromUrl:u];
        NSString *href_transition = [JasonHelper getParamValueFor:@"transition" fromUrl:u];
        
        NSMutableDictionary *href = [[NSMutableDictionary alloc] init];
        if(href_url && href_url.length > 0) href[@"url"] = href_url;
        if(href_view && href_view.length > 0) href[@"view"] = href_view;
        if(href_transition && href_transition.length > 0) {
            href[@"transition"] = href_transition;
        } else {
            // Default is modal
            href[@"transition"] = @"modal";
        }
        if([type isEqualToString:@"go"]) {
            [[Jason client] go:href];
        } else {
            [[Jason client] start:href];
        }
    } else {
        // Only start if we're not going through an oauth auth process
        [[Jason client] start:nil];
    }
    return YES;
}


#ifdef PUSH
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"onRemoteNotificationDeviceRegistered" object:nil userInfo:@{@"token": [self hexadecimalStringFromData:deviceToken]}];
}

- (NSString *)hexadecimalStringFromData:(NSData *)data
{
  NSUInteger dataLength = data.length;
  if (dataLength == 0) {
    return nil;
  }

  const unsigned char *dataBuffer = (const unsigned char *)data.bytes;
  NSMutableString *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
  for (int i = 0; i < dataLength; ++i) {
    [hexString appendFormat:@"%02x", dataBuffer[i]];
  }
  return [hexString copy];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"Error = %@",error);
#endif
}
#endif

@end
