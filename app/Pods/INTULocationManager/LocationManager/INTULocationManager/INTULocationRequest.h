//
//  INTULocationRequest.h
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

__INTU_ASSUME_NONNULL_BEGIN

/** The available types of location requests. */
typedef NS_ENUM(NSInteger, INTULocationRequestType) {
    /** A one-time location request with a specific desired accuracy and optional timeout. */
    INTULocationRequestTypeSingle,
    /** A subscription to location updates. */
    INTULocationRequestTypeSubscription,
    /** A subscription to significant location changes. */
    INTULocationRequestTypeSignificantChanges
};

@class INTULocationRequest;

/**
 Protocol for the INTULocationRequest to notify the its delegate that a request has timed out.
 */
@protocol INTULocationRequestDelegate

/**
 Notification that a location request has timed out.
 
 @param locationRequest The location request that timed out.
 */
- (void)locationRequestDidTimeout:(INTULocationRequest *)locationRequest;

@end


/**
 Represents a geolocation request that is created and managed by INTULocationManager.
 */
@interface INTULocationRequest : NSObject

/** The delegate for this location request. */
@property (nonatomic, weak, __INTU_NULLABLE) id<INTULocationRequestDelegate> delegate;
/** The request ID for this location request (set during initialization). */
@property (nonatomic, readonly) INTULocationRequestID requestID;
/** The type of this location request (set during initialization). */
@property (nonatomic, readonly) INTULocationRequestType type;
/** Whether this is a recurring location request (type is either Subscription or SignificantChanges). */
@property (nonatomic, readonly) BOOL isRecurring;
/** The desired accuracy for this location request. */
@property (nonatomic, assign) INTULocationAccuracy desiredAccuracy;
/** The maximum amount of time the location request should be allowed to live before completing.
    If this value is exactly 0.0, it will be ignored (the request will never timeout by itself). */
@property (nonatomic, assign) NSTimeInterval timeout;
/** How long the location request has been alive since the timeout value was last set. */
@property (nonatomic, readonly) NSTimeInterval timeAlive;
/** Whether this location request has timed out (will also be YES if it has been completed). Subcriptions can never time out. */
@property (nonatomic, readonly) BOOL hasTimedOut;
/** The block to execute when the location request completes. */
@property (nonatomic, copy, __INTU_NULLABLE) INTULocationRequestBlock block;

/** Designated initializer. Initializes and returns a newly allocated location request object with the specified type. */
- (instancetype)initWithType:(INTULocationRequestType)type __INTU_DESIGNATED_INITIALIZER;

/** Completes the location request. */
- (void)complete;
/** Forces the location request to consider itself timed out. */
- (void)forceTimeout;
/** Cancels the location request. */
- (void)cancel;

/** Starts the location request's timeout timer if a nonzero timeout value is set, and the timer has not already been started. */
- (void)startTimeoutTimerIfNeeded;

/** Returns the associated recency threshold (in seconds) for the location request's desired accuracy level. */
- (NSTimeInterval)updateTimeStaleThreshold;

/** Returns the associated horizontal accuracy threshold (in meters) for the location request's desired accuracy level. */
- (CLLocationAccuracy)horizontalAccuracyThreshold;

@end

__INTU_ASSUME_NONNULL_END
