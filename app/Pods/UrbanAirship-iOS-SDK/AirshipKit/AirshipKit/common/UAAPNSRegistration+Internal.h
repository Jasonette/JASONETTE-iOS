/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAAPNSRegistrationProtocol+Internal.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Adapter that implements APNS registration using the current (iOS10+) registration flow.
 */
@interface UAAPNSRegistration : NSObject <UAAPNSRegistrationProtocol>

@end

NS_ASSUME_NONNULL_END
