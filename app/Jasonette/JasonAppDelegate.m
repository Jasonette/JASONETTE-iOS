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
    Class ExtensionClass = NSClassFromString(className);
    [ExtensionClass performSelector: @selector(initialize:) withObject: launchOptions];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:@"_UIConstraintBasedLayoutLogUnsatisfiable"];
    
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024 diskCapacity:20 * 1024 * 1024 diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];

    
    // # initialize
    // Run "initialize" for built-in daemon type actions
    NSArray *native_daemon_actions = @[@"push"];
    for(NSString *action in native_daemon_actions) {
        [self init_class:action withLaunchOptions:launchOptions];
    }
    // Run "initialize" method for all extensions
    [self init_extensions: launchOptions];

    
    if(launchOptions && launchOptions.count > 0 && launchOptions[UIApplicationLaunchOptionsURLKey]){
        // launched with url. so wait until openURL is called.
        
    } else if(launchOptions && launchOptions.count > 0 && [launchOptions objectForKey: UIApplicationLaunchOptionsRemoteNotificationKey]){
        // launched with push notification. so ignore. It's already been taken care of by
        // JasonPushAction.initialize from [self init_extensions]
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





@end
