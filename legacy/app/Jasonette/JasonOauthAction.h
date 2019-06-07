//
//  JasonOauthAction.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonAction.h"
#import <SafariServices/SafariServices.h>
#import "JasonHelper.h"
#import <AFNetworking/AFNetworking.h>
#import "AFOAuth2Manager.h"
#import "AFHTTPRequestSerializer+OAuth2.h"
@import AHKActionSheet;

@interface JasonOauthAction : JasonAction <SFSafariViewControllerDelegate>
@end
