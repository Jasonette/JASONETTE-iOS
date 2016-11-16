// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "MSBlockDefinitions.h"

@class MSPush;

@interface MSPushRequest : NSMutableURLRequest

/// Creates a request to update the installation Id associated with this device
/// with the given token and template
+(MSPushRequest *) requestToRegisterDeviceToken:(NSData *)deviceToken
                                           push:(MSPush *)push
                                      templates:(NSDictionary *)templates
                                     completion:(MSCompletionBlock)completion;

/// Creates a request to remove the push registration associated with the device's
/// installation ID
+(MSPushRequest *) requestToUnregisterPush:(MSPush *)push
                                completion:(MSCompletionBlock)completion;


/// Initialize an MSPushRequest with url, data and method.
- (MSPushRequest *)initWithURL:(NSURL *)url
                          data:(NSData *)data
                    HTTPMethod:(NSString *)method;

@end
