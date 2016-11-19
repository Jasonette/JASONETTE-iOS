// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

#pragma mark * Block Type Definitions

/**
 Callback that the filter should invoke once an HTTP response (with or without data) or an error
 has been received by the filter.
 */
typedef void (^MSFilterResponseBlock)(NSHTTPURLResponse *__nullable response,
                                      NSData *__nullable data,
                                      NSError *__nullable error);

/** Callback that the filter should invoke to allow the next filter to handle the given request. */
typedef void (^MSFilterNextBlock)(NSURLRequest *__nonnull request,
                                  MSFilterResponseBlock __nonnull onResponse);


#pragma  mark * MSFilter Public Protocol


/** 
 The MSFilter protocol allows developers to implement a class that can inspect and/or replace
 HTTP request and HTTP response messages being sent and received from an *MSClient* instance.
 An MSFilter will not be applied to login related actions.
*/
@protocol MSFilter <NSObject>

/** @name Modify the request */

/**
 Allows for the inspection and/or modification of the HTTP request and HTTP response messages
 being sent and received by an *MSClient* instance.

 @param request the outgoing HTTP request
 @param next A MSFilterNextBlock to call that allows the next MSFilter to run
 @param response The MSFilterResponseBlock callback to call once processing is complete,
                returning control to the previous filter
 */
-(void)handleRequest:(nonnull NSURLRequest *)request
                next:(nonnull MSFilterNextBlock)next
            response:(nonnull MSFilterResponseBlock)response;

@end
