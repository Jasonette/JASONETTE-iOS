//
//  JasonAppDelegate.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonAppDelegate.h"
#import "JasonLogger.h"

@interface JasonAppDelegate ()

@end


@implementation JasonAppDelegate

- (void) init_extensions: (NSDictionary *) launchOptions
{
    // 1. Find json files that start with $
    // 2. For each file, see if the class contains an "initialize" class method
    // 3. If so, run them one by one.
    NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
    
    NSArray * dirFiles = [[NSFileManager defaultManager]
                          contentsOfDirectoryAtPath:resourcePath
                          error:nil];
    
    NSArray * jrs = [dirFiles filteredArrayUsingPredicate:
                     [NSPredicate
                      predicateWithFormat:@"(self ENDSWITH[c] '.json') AND (self BEGINSWITH[c] '$')"]];
    
    NSError * error = nil;
    for(int i = 0 ; i < jrs.count; i++)
    {
        NSString * filename = jrs[i];
        NSString * absolute_path = [NSString stringWithFormat:@"%@/%@", resourcePath, filename];
        
        NSInputStream * inputStream = [[NSInputStream alloc] initWithFileAtPath:absolute_path];
        [inputStream open];
        
        NSDictionary * json = [NSJSONSerialization
                               JSONObjectWithStream: inputStream
                               options:kNilOptions
                               error:&error];
        [inputStream close];
        
        if(json[@"classname"])
        {
            [self init_class:json[@"classname"]
                withLaunchOptions:launchOptions];
        }
    }
}

- (void) init_class: (NSString *) className
  withLaunchOptions: (NSDictionary *) launchOptions
{
    // TODO: Include something for Swift code detection on NSClassFromString returning nil
    Class ActionClass = NSClassFromString(className);
    id service;
    
    if([Jason client].services && [Jason client].services[className])
    {
        service = [Jason client].services[className];
    }
    else
    {
        service = [[ActionClass alloc] init];
        [Jason client].services[className] = service;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [service performSelector: @selector(initialize:)
                  withObject: launchOptions];
#pragma clang diagnostic pop
}

- (BOOL) application: (UIApplication *) application
    didFinishLaunchingWithOptions:(NSDictionary *) launchOptions
{
    
#if DEBUG
    [JasonLogger setupWithLogLevelDebug];
#else
    [JasonLogger setupWithLogLevelError];
#endif
    
    DTLogInfo(@"Begin Bootstrapping Jasonette");
    
    [[NSUserDefaults standardUserDefaults]
     setValue:@(NO)
     forKey:@"_UIConstraintBasedLayoutLogUnsatisfiable"];
    
    NSURLCache * URLCache = [[NSURLCache alloc]
                            initWithMemoryCapacity:4 * 1024 * 1024
                            diskCapacity:20 * 1024 * 1024
                            diskPath:nil];
    
    [NSURLCache setSharedURLCache:URLCache];
    
    
    // # initialize
    // Run "initialize" for built-in daemon type actions
    NSArray *native_daemon_actions = @[@"JasonPushService", @"JasonVisionService", @"JasonWebsocketService", @"JasonAgentService"];
    for(NSString *action in native_daemon_actions)
    {
        [self init_class:action withLaunchOptions:launchOptions];
    }
    
    // Run "initialize" method for all extensions
    [self init_extensions: launchOptions];
    
    if(launchOptions && launchOptions.count > 0 && launchOptions[UIApplicationLaunchOptionsURLKey])
    {
        // launched with url. so wait until openURL is called.
        self.launchURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
        
    }
    else if(launchOptions && launchOptions.count > 0 && [launchOptions
                                                         objectForKey: UIApplicationLaunchOptionsRemoteNotificationKey])
    {
        // launched with push notification.
        [[Jason client] start: nil];
    }
    else
    {
        [[Jason client] start:nil];
    }
    
    DTLogInfo(@"Jasonette Bootstraped");
    return YES;
}

- (void) applicationDidBecomeActive: (UIApplication *) application
{
    DTLogInfo(@"Application Did Become Active");
    if (self.launchURL)
    {
        DTLogInfo(@"Launch URL Detected");
        [self openURL:self.launchURL type: @"start"];
        self.launchURL = nil;
    }
}

- (BOOL)application: (UIApplication *) application
            openURL: (NSURL *) url
  sourceApplication: (NSString *) sourceApplication
         annotation: (id) annotation
{
    if (!url) return NO;
    DTLogInfo(@"Received Application openURL");
    return [self openURL:url type: @"go"];
}

- (BOOL) openURL: (NSURL *) url
            type: (NSString *) type
{
    DTLogInfo(@"OpenURL Triggered");
    DTLogDebug(@"Opening Url %@ Type %@", [url absoluteString], type);
    
    if([[url absoluteString] containsString:@"://oauth"])
    {
        DTLogInfo(@"://oauth call detected");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"oauth_callback" object:nil userInfo:@{@"url": url}];
        return YES;
    }
    
    if ([[url absoluteString] containsString:@"://href?"])
    {
        DTLogInfo(@"://href? call detected");
        
        NSString * u = [url absoluteString];
        NSString * href_url = [JasonHelper getParamValueFor:@"url" fromUrl:u];
        NSString * href_view = [JasonHelper getParamValueFor:@"view" fromUrl:u];
        NSString * href_transition = [JasonHelper getParamValueFor:@"transition" fromUrl:u];
        
        DTLogInfo(@"Checking href config");
        NSMutableDictionary * href = [@{} mutableCopy];
        if(href_url && href_url.length > 0)
        {
            DTLogDebug(@"href url %@", href_url);
            href[@"url"] = href_url;
        }
        
        if(href_view && href_view.length > 0)
        {
            DTLogDebug(@"href view %@", href_view);
            href[@"view"] = href_view;
        }
        
        href[@"transition"] = @"modal";
        if(href_transition && href_transition.length > 0)
        {
            DTLogDebug(@"href transition %@", href_transition);
            href[@"transition"] = href_transition;
        }
        
        if([type isEqualToString:@"go"])
        {
            DTLogInfo(@"Type is Go");
            [[Jason client] go:href];
            return YES;
        }
        
        DTLogInfo(@"Type is Start");
        [[Jason client] start:href];
        return YES;
    }
    
    // Only start if we're not going through an oauth auth process
    DTLogInfo(@"No Auth process found. Start normal");
    [[Jason client] start:nil];
    return YES;
}


#ifdef PUSH
#pragma mark - Remote Notification Delegate below iOS 9
- (void) application: (UIApplication *) application
didRegisterUserNotificationSettings: (UIUserNotificationSettings *) notificationSettings
{
    DTLogDebug(@"Registering for Remote Notifications");
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken: (NSData *) deviceToken
{
    NSString * device_token = [[NSString alloc]initWithFormat:@"%@",
                               [[[deviceToken description]
                                 stringByTrimmingCharactersInSet:[NSCharacterSet
                                                                  characterSetWithCharactersInString:@"<>"]]
                                stringByReplacingOccurrencesOfString:@" " withString:@""]];
    
    DTLogDebug(@"Got Device Token %@", device_token);
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"onRemoteNotificationDeviceRegistered" object:nil
     userInfo:@{@"token": device_token}];
}

- (void) application: (UIApplication *) application
    didReceiveRemoteNotification:(NSDictionary *) userInfo
{
    
    DTLogDebug(@"Received Remote Notification %@", userInfo);
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"onRemoteNotification"
     object:nil
     userInfo:userInfo];
}

- (void) application: (UIApplication *) application
    didFailToRegisterForRemoteNotificationsWithError: (NSError *) error
{
    DTLogWarning(@"Notifications Failed to be Registered %@", error);
}

#endif

@end
