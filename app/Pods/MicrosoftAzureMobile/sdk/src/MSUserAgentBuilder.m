// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSUserAgentBuilder.h"
#import "MicrosoftAzureMobile.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif


#pragma mark * User Agent Header String Constants


static NSString *const sdkLanguage = @"objective-c";
static NSString *const userAgentValueFormat = @"ZUMO/%@ (lang=%@; os=%@; os_version=%@; arch=%@; version=%@)";
static NSString *const simulatorModel = @"iOSSimulator";
static NSString *const unknownValue = @"--";
static NSString *const sdkVersionFormat = @"%d.%d";
static NSString *const sdkFileVesionFormat = @"%d.%d.%d";


#pragma mark * MSUserAgentBuilder Implementation


@implementation MSUserAgentBuilder


#pragma  mark * Public UserAgent Method


+(NSString *) userAgent
{
    NSString *model = nil;
    NSString *OS = nil;
    NSString *OSversion = nil;
    
    // Get the device related info
#if TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    model = simulatorModel;
    OS = unknownValue;
    OSversion = unknownValue;
#elif TARGET_OS_IPHONE
    UIDevice *currentDevice = [UIDevice currentDevice];
    model = [currentDevice model];
    OS = [currentDevice systemName];
    OSversion = [currentDevice systemVersion];
#else
	OSversion = [[NSProcessInfo processInfo] operatingSystemVersionString];
	OS = @"OSX";
	model = @"Mac";
#endif
    NSString *sdkVersion = [NSString stringWithFormat:sdkVersionFormat,
                                MicrosoftAzureMobileSdkMajorVersion,
                                MicrosoftAzureMobileSdkMinorVersion];
    NSString *fileVersion = [NSString stringWithFormat:sdkFileVesionFormat,
                                MicrosoftAzureMobileSdkMajorVersion,
                                MicrosoftAzureMobileSdkMinorVersion,
                                MicrosoftAzureMobileSdkBuildVersion ];
    
    // Build the user agent string
    NSString *userAgent = [NSString stringWithFormat:userAgentValueFormat,
                           sdkVersion,
                           sdkLanguage,
                           OS,
                           OSversion,
                           model,
                           fileVersion];
    
    return userAgent;
}

@end
