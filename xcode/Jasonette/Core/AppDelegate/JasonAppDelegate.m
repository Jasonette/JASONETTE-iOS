//
//  JasonAppDelegate.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonAppDelegate.h"
#import "JasonLogger.h"
#import "JasonNSClassFromString.h"

static NSURL * _launchURL;
static NSArray * _services;

@interface JasonAppDelegate ()

@end

@implementation JasonAppDelegate

+ (void)initializeExtensionsWithOptions:(NSDictionary *)launchOptions
{
    // 1. Find json files that start with $
    // 2. For each file, see if the class contains an "initialize" class method
    // 3. If so, run them one by one.
    DTLogInfo (@"Initializing Extensions");
    NSString * resourcePath = [[NSBundle mainBundle] resourcePath];

    NSArray * dirFiles = [[NSFileManager defaultManager]
                          contentsOfDirectoryAtPath:resourcePath
                                              error:nil];

    DTLogInfo (@"Loading jr.json files");
    NSArray * jrs = [dirFiles filteredArrayUsingPredicate:
                     [NSPredicate
                      predicateWithFormat:@"(self ENDSWITH[c] '.json') AND (self BEGINSWITH[c] '$')"]];

    if (jrs.count <= 0) {
        DTLogInfo (@"No extensions found with jr.json");
        return;
    }

    NSString * filename;
    NSString * absolutePath;
    NSInputStream * inputStream;
    NSError * error = nil;
    NSDictionary * json;
    NSString * class;

    for (filename in jrs) {
        DTLogDebug (@"Parsing %@", filename);

        absolutePath = [NSString stringWithFormat:@"%@/%@", resourcePath, filename];

        inputStream = [[NSInputStream alloc] initWithFileAtPath:absolutePath];
        error = nil;

        [inputStream open];

        json = [NSJSONSerialization
                JSONObjectWithStream:inputStream
                             options:kNilOptions
                               error:&error];
        [inputStream close];

        if (error) {
            DTLogInfo (@"Error parsing %@ %@", filename, error);
            continue;
        }

        if (!json[@"classname"]) {
            DTLogWarning (@"No 'classname' property found in jr.json %@ %@", filename, json);
            continue;
        }

        if (!json[@"name"]) {
            // If no name property, then Jasonette would try to autodetect based on filename
            DTLogWarning (@"No 'name' property found in jr.json %@ %@", filename, json);
        }

        class = json[@"classname"];
        DTLogInfo (@"Initializing %@ Extension", filename);
        [JasonAppDelegate initializeClass:class
                              withOptions:launchOptions];
    }
}

+ (void)initializeClass:(NSString *)className
            withOptions:(NSDictionary *)launchOptions
{
    DTLogInfo (@"Initializing %@", className);

    if (![className hasPrefix:@"Jason"]) {
        DTLogWarning (@"Class %@ does not start with 'Jason'", className);
        DTLogWarning (@"Use the format Jason{MyClass}Action|Component|Service. Example: JasonMyCustomAction.\nSkipping");
        return;
    }

    if (!([className hasSuffix:@"Action"] || [className hasSuffix:@"Component"] || [className hasSuffix:@"Service"])) {
        DTLogWarning (@"Class %@ does not end with 'Action', 'Component' or 'Service'", className);
        DTLogWarning (@"Use the format Jason{MyClass}Action|Component|Service. Example: JasonMyCustomAction.\nSkipping");
        return;
    }

    DTLogInfo (@"Calling initilize: method on class %@", className);
    Class ActionClass = [JasonNSClassFromString
                         classFromString:className];
    id extension;

    if ([Jason client].services && [Jason client].services[className]) {
        extension = [Jason client].services[className];
    } else {
        DTLogInfo (@"Adding Class %@ to the Stack", className);
        extension = [[ActionClass alloc] init];
        [Jason client].services[className] = extension;
    }

    SEL initialize = NSSelectorFromString (@"initialize:");

    if ([extension respondsToSelector:initialize]) {
#pragma message "TODO: Find a way to remove those clang diagnostic pragmas"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [extension performSelector:initialize
                        withObject:launchOptions];
#pragma clang diagnostic pop
        return;
    }

    DTLogWarning (@"Class %@ does not implement initialize: method. Skipping", className);
}

+ (void)initializeServicesWithOptions:(NSDictionary *)launchOptions
{
    // # initialize
    // Run "initialize" for built-in daemon type actions
    DTLogInfo (@"Initializing Core Services");
    NSArray * services = @[@"JasonPushService",
                           @"JasonVisionService",
                           @"JasonWebsocketService",
                           @"JasonAgentService"];

    for (NSString * service in services) {
        [JasonAppDelegate
         initializeClass:service
             withOptions:launchOptions];
    }
}

+ (void)setLaunchURLWithOptions:(NSDictionary *)launchOptions
{
    if (launchOptions && launchOptions.count > 0 &&
        launchOptions[UIApplicationLaunchOptionsURLKey]) {
        // launched with url. so wait until openURL is called.
        _launchURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
        DTLogInfo (@"Launched with Url %@", _launchURL);
    } else if (launchOptions && launchOptions.count > 0 &&
               launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        // launched with push notification.
        DTLogInfo (@"Launched with Push Notification");
    }
}

+ (void)setCache
{
    int MegaByte = 1024 * 1024;
    NSURLCache * URLCache = [[NSURLCache alloc]
                             initWithMemoryCapacity:4 * MegaByte
                                       diskCapacity:20 * MegaByte
                                           diskPath:nil];

    [NSURLCache setSharedURLCache:URLCache];
}

+ (void)setLayoutConstraintsConfiguration
{
    [[NSUserDefaults standardUserDefaults]
     setValue:@(NO)
       forKey:@"_UIConstraintBasedLayoutLogUnsatisfiable"];
}

+ (void)setLogger
{
#if DEBUG
    [JasonLogger setupWithLogLevelDebug];
#else
    [JasonLogger setupWithLogLevelError];
#endif
}

+ (BOOL)              application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [JasonAppDelegate setLogger];
    DTLogInfo (@"Begin Bootstrapping Jasonette");

    [JasonAppDelegate setLayoutConstraintsConfiguration];
    [JasonAppDelegate setCache];

    // Run "initialize" method for the core services
    [JasonAppDelegate initializeServicesWithOptions:launchOptions];

    // Run "initialize" method for all extensions
    [JasonAppDelegate initializeExtensionsWithOptions:launchOptions];

    [JasonAppDelegate setLaunchURLWithOptions:launchOptions];

    DTLogInfo (@"Jasonette Bootstraped");
    DTLogInfo (@"Begin Building Screen");

    [[Jason client] start:nil];
    return YES;
}

+ (void)applicationDidBecomeActive:(UIApplication *)application
{
    DTLogInfo (@"Application Did Become Active");

    if (_launchURL) {
        DTLogInfo (@"Launch URL Detected");
        [JasonAppDelegate openURL:_launchURL type:@"start"];
        _launchURL = nil;
    }
}

+ (BOOL)  application:(UIApplication *)application
              openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation
{
    if (!url) {
        return NO;
    }

    DTLogInfo (@"Received Application openURL");
    return [JasonAppDelegate openURL:url type:@"go"];
}

+ (BOOL)openURL:(NSURL *)url
           type:(NSString *)type
{
    DTLogInfo (@"OpenURL Triggered");
    DTLogDebug (@"Opening Url %@ Type %@", [url absoluteString], type);

    if ([[url absoluteString] containsString:@"://oauth"]) {
        DTLogInfo (@"://oauth call detected");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"oauth_callback" object:nil userInfo:@{ @"url": url }];
        return YES;
    }

    if ([[url absoluteString] containsString:@"://href?"]) {
        DTLogInfo (@"://href? call detected");

        NSString * u = [url absoluteString];
        NSString * href_url = [JasonHelper getParamValueFor:@"url" fromUrl:u];
        NSString * href_view = [JasonHelper getParamValueFor:@"view" fromUrl:u];
        NSString * href_transition = [JasonHelper getParamValueFor:@"transition" fromUrl:u];

        DTLogInfo (@"Checking href config");
        NSMutableDictionary * href = [@{} mutableCopy];

        if (href_url && href_url.length > 0) {
            DTLogDebug (@"href url %@", href_url);
            href[@"url"] = href_url;
        }

        if (href_view && href_view.length > 0) {
            DTLogDebug (@"href view %@", href_view);
            href[@"view"] = href_view;
        }

        href[@"transition"] = @"modal";

        if (href_transition && href_transition.length > 0) {
            DTLogDebug (@"href transition %@", href_transition);
            href[@"transition"] = href_transition;
        }

        if ([type isEqualToString:@"go"]) {
            DTLogInfo (@"Type is Go");
            [[Jason client] go:href];
            return YES;
        }

        DTLogInfo (@"Type is Start");
        [[Jason client] start:href];
        return YES;
    }

    // Only start if we're not going through an oauth auth process
    DTLogInfo (@"No Auth process found. Start normal");
    [[Jason client] start:nil];
    return YES;
}

#pragma mark - Remote Notification Delegate below iOS 9
+ (void)                    application:(UIApplication *)application
    didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    DTLogDebug (@"Registering for Remote Notifications");
    [application registerForRemoteNotifications];
}

+ (void)                                 application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString * device_token = [[NSString alloc]initWithFormat:@"%@",
                               [[[deviceToken description]
                                 stringByTrimmingCharactersInSet:[NSCharacterSet
                                                                  characterSetWithCharactersInString:@"<>"]]
                                stringByReplacingOccurrencesOfString:@" "
                                                          withString:@""]];

    DTLogInfo (@"Got Device Token");
    DTLogDebug (@"Got Device Token %@", device_token);

    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"onRemoteNotificationDeviceRegistered"
                   object:nil
                 userInfo:@{ @"token": device_token }];
}

+ (void)             application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    DTLogInfo (@"Got Remote Notification");
    DTLogDebug (@"Received Remote Notification %@", userInfo);

    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"onRemoteNotification"
                   object:nil
                 userInfo:userInfo];
}

+ (void)                                 application:(UIApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    DTLogWarning (@"Notifications Failed to be Registered %@", error);
}

@end
