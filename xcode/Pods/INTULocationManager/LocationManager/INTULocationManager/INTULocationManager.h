//
//  INTULocationManager.h
//
//  Copyright (c) 2014-2015 Intuit Inc.
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "INTULocationRequestDefines.h"

//! Project version number for INTULocationManager.
FOUNDATION_EXPORT double INTULocationManagerVersionNumber;

//! Project version string for INTULocationManager.
FOUNDATION_EXPORT const unsigned char INTULocationManagerVersionString[];


__INTU_ASSUME_NONNULL_BEGIN

/**
 An abstraction around CLLocationManager that provides a block-based asynchronous API for obtaining the device's location.
 INTULocationManager automatically starts and stops system location services as needed to minimize battery drain.
 */
@interface INTULocationManager : NSObject

/** Returns the current state of location services for this app, based on the system settings and user authorization status. */
+ (INTULocationServicesState)locationServicesState;

/** Returns the current state of heading services for this device. */
+ (INTUHeadingServicesState)headingServicesState;

/** Returns the singleton instance of this class. */
+ (instancetype)sharedInstance;

#pragma mark Location Requests

/**
 Asynchronously requests the current location of the device using location services.
 
 @param desiredAccuracy The accuracy level desired (refers to the accuracy and recency of the location).
 @param timeout         The maximum amount of time (in seconds) to wait for a location with the desired accuracy before completing. If 
                        this value is 0.0, no timeout will be set (will wait indefinitely for success, unless request is force completed or canceled).
 @param block           The block to execute upon success, failure, or timeout.
 
 @return The location request ID, which can be used to force early completion or cancel the request while it is in progress.
 */
- (INTULocationRequestID)requestLocationWithDesiredAccuracy:(INTULocationAccuracy)desiredAccuracy
                                                    timeout:(NSTimeInterval)timeout
                                                      block:(INTULocationRequestBlock)block;

/**
 Asynchronously requests the current location of the device using location services, optionally delaying the timeout countdown until the user has
 responded to the dialog requesting permission for this app to access location services.
 
 @param desiredAccuracy      The accuracy level desired (refers to the accuracy and recency of the location).
 @param timeout              The maximum amount of time (in seconds) to wait for a location with the desired accuracy before completing. If
                             this value is 0.0, no timeout will be set (will wait indefinitely for success, unless request is force completed or canceled).
 @param delayUntilAuthorized A flag specifying whether the timeout should only take effect after the user responds to the system prompt requesting
                             permission for this app to access location services. If YES, the timeout countdown will not begin until after the
                             app receives location services permissions. If NO, the timeout countdown begins immediately when calling this method.
 @param block                The block to execute upon success, failure, or timeout.
 
 @return The location request ID, which can be used to force early completion or cancel the request while it is in progress.
 */
- (INTULocationRequestID)requestLocationWithDesiredAccuracy:(INTULocationAccuracy)desiredAccuracy
                                                    timeout:(NSTimeInterval)timeout
                                       delayUntilAuthorized:(BOOL)delayUntilAuthorized
                                                      block:(INTULocationRequestBlock)block;

/**
 Creates a subscription for location updates that will execute the block once per update indefinitely (until canceled), regardless of the accuracy of each location.
 This method instructs location services to use the highest accuracy available (which also requires the most power).
 If an error occurs, the block will execute with a status other than INTULocationStatusSuccess, and the subscription will be canceled automatically.
 
 @param block The block to execute every time an updated location is available. 
              The status will be INTULocationStatusSuccess unless an error occurred; it will never be INTULocationStatusTimedOut.
 
 @return The location request ID, which can be used to cancel the subscription of location updates to this block.
 */
- (INTULocationRequestID)subscribeToLocationUpdatesWithBlock:(INTULocationRequestBlock)block;

/**
 Creates a subscription for location updates that will execute the block once per update indefinitely (until canceled), regardless of the accuracy of each location.
 The specified desired accuracy is passed along to location services, and controls how much power is used, with higher accuracies using more power.
 If an error occurs, the block will execute with a status other than INTULocationStatusSuccess, and the subscription will be canceled automatically.
 
 @param desiredAccuracy The accuracy level desired, which controls how much power is used by the device's location services.
 @param block           The block to execute every time an updated location is available. Note that this block runs for every update, regardless of
                        whether the achievedAccuracy is at least the desiredAccuracy.
                        The status will be INTULocationStatusSuccess unless an error occurred; it will never be INTULocationStatusTimedOut.
 
 @return The location request ID, which can be used to cancel the subscription of location updates to this block.
 */
- (INTULocationRequestID)subscribeToLocationUpdatesWithDesiredAccuracy:(INTULocationAccuracy)desiredAccuracy
                                                                 block:(INTULocationRequestBlock)block;

/**
 Creates a subscription for significant location changes that will execute the block once per change indefinitely (until canceled).
 If an error occurs, the block will execute with a status other than INTULocationStatusSuccess, and the subscription will be canceled automatically.
 
 @param block The block to execute every time an updated location is available.
              The status will be INTULocationStatusSuccess unless an error occurred; it will never be INTULocationStatusTimedOut.
 
 @return The location request ID, which can be used to cancel the subscription of significant location changes to this block.
 */
- (INTULocationRequestID)subscribeToSignificantLocationChangesWithBlock:(INTULocationRequestBlock)block;

/** Immediately forces completion of the location request with the given requestID (if it exists), and executes the original request block with the results.
    For one-time location requests, this is effectively a manual timeout, and will result in the request completing with status INTULocationStatusTimedOut.
    If the requestID corresponds to a subscription, then the subscription will simply be canceled. */
- (void)forceCompleteLocationRequest:(INTULocationRequestID)requestID;

/** Immediately cancels the location request (or subscription) with the given requestID (if it exists), without executing the original request block. */
- (void)cancelLocationRequest:(INTULocationRequestID)requestID;

#pragma mark Heading Requests

/**
 Creates a subscription for heading updates that will execute the block once per update indefinitely (until canceled), assuming the heading update exceeded the heading filter threshold.
 If an error occurs, the block will execute with a status other than INTUHeadingStatusSuccess, and the subscription will be canceled automatically.

 @param block           The block to execute every time an updated heading is available. The status will be INTUHeadingStatusSuccess unless an error occurred.

 @return The heading request ID, which can be used to cancel the subscription of heading updates to this block.
 */
- (INTUHeadingRequestID)subscribeToHeadingUpdatesWithBlock:(INTUHeadingRequestBlock)block;

/** Immediately cancels the heading subscription request with the given requestID (if it exists), without executing the original request block. */
- (void)cancelHeadingRequest:(INTUHeadingRequestID)requestID;

@end

__INTU_ASSUME_NONNULL_END
