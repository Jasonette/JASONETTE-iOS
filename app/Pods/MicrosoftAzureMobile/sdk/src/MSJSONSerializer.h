// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "MSSerializer.h"


#pragma mark * MSJSONSerializer Public Interface


// The |MSJSONSerializer| is an implementation of the |MSSerializer| protocol
// for serializing to and from JSON using |NSJSONSerialization| as its
// implementation.
@interface MSJSONSerializer : NSObject <MSSerializer>

// A singleton instance of the MSJSONSerializer.
+(id<MSSerializer>)JSONSerializer;

// Helper method to generate a random GUID
+ (NSString *) generateGUID;

@end
