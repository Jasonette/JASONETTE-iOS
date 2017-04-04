//
//  JasonAppDelegate.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonAppDelegate.h"

@interface JasonAppDelegate ()

@end

#define SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@implementation JasonAppDelegate

- (void)init_extensions{
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
            Class ExtensionClass = NSClassFromString(json[@"classname"]);
            [ExtensionClass performSelector: @selector(initialize)];
        }
    }
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:@"_UIConstraintBasedLayoutLogUnsatisfiable"];
    
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024 diskCapacity:20 * 1024 * 1024 diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];

    // Run "initialize" method for all extensions
    [self init_extensions];
    
#ifdef PUSH
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"registerNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(registerNotification) name:@"registerNotification" object:nil];
#else
    NSLog(@"Push notification turned off by default. If you'd like to suport push, uncomment the #define statement in Constants.h and turn on the push notification feature from the capabilities tab.");
#endif
    
    if(launchOptions && launchOptions.count > 0 && launchOptions[UIApplicationLaunchOptionsURLKey]){
        // launched with url. so wait until openURL is called.
        
#ifdef PUSH
    } else if(launchOptions && launchOptions.count > 0 && [launchOptions objectForKey: UIApplicationLaunchOptionsRemoteNotificationKey]){
        UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if(notification){
            if(notification.userInfo && notification.userInfo[@"href"]){
                [[Jason client] go:notification.userInfo[@"href"]];
            }
        }
#endif
        
        
    } else {
        [[Jason client] start:nil];
    }
    return YES;
}
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
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
        
        [[Jason client] go:href];
    } else {
        // Only start if we're not going through an oauth auth process
        [[Jason client] start:nil];
    }
    return YES;
}







// PUSH RELATED
// The "PUSH" constant is defined in Constants.h
// By default PUSH is disabled. To turn it on, go to Constants.h and uncomment the #define statement, and then go to the capabilities tab and switch the push notification feature on.

#ifdef PUSH

- (void)registerNotification {
    if(SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(@"10.0")) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error){
            if( !error ){
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            }
        }];
    }
    else {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

#pragma mark - Remote Notification Delegate below iOS 9

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    NSString *device_token = [[NSString alloc]initWithFormat:@"%@",[[[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""]];
    NSLog(@"Device Token = %@",device_token);
    [[Jason client] onRemoteNotificationDeviceRegistered: device_token];
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[Jason client] onRemoteNotification:userInfo];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Error = %@",error);
}

#pragma mark - UNUserNotificationCenter Delegate above iOS 10

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
    
    [[Jason client] onRemoteNotification:notification.request.content.userInfo];
    
    completionHandler(UNNotificationPresentationOptionNone);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler{
    
    if(response.notification.request.content.userInfo && response.notification.request.content.userInfo[@"href"]){
        [[Jason client] go:response.notification.request.content.userInfo[@"href"]];
    }
    
    completionHandler();
}
#endif

@end
