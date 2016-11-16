// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>


#pragma  mark * MSUserAgentBuilder Public Interface


// The |MSUserAgentBuilder| class encapsulates the logic for building the
// appropriate HTTP 'User-Agent' header value for all |MSClient| requests.
// Microsoft Azure Mobile Services expects the 'User-Agent' to be of the form:
//
//     ZUMO/<sdk-version> (<sdk-language> <OS> <OS-version> <Architecture> <sdk-fileversion>)
//
@interface MSUserAgentBuilder : NSObject


#pragma  mark * Public UserAgent Method


// The HTTP 'User-Agent' value to use with all |MSClient| requests
+(NSString *)userAgent;

@end
