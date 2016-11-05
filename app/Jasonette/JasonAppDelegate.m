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


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:@"_UIConstraintBasedLayoutLogUnsatisfiable"];
    if(launchOptions && launchOptions.count > 0 && launchOptions[UIApplicationLaunchOptionsURLKey]){
        // launched with url. so wait until openURL is called.
    } else {
        [[Jason client] start];
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
        [[Jason client] start];
    }
    return YES;
}

@end
