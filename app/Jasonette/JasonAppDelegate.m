//
//  JasonAppDelegate.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonAppDelegate.h"

@interface JasonAppDelegate ()

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

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if (!url) return NO;
    return [self openURL:url type: @"go"];
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
#pragma mark - Remote Notification Delegate below iOS 9
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    NSString *device_token = [[NSString alloc]initWithFormat:@"%@",[[[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""]];
    NSLog(@"Device Token = %@",device_token);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"onRemoteNotificationDeviceRegistered" object:nil userInfo:@{@"token": device_token}];
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"onRemoteNotification" object:nil userInfo:userInfo];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Error = %@",error);
}
#endif

@end
