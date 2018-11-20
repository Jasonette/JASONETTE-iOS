/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * Represents the result of performing a background fetch, or none if no fetch was performed.
 */
typedef NS_OPTIONS(NSInteger, UAActionFetchResult) {
    /**
     * The action did not result in any new data being fetched.
     */
    UAActionFetchResultNoData = UIBackgroundFetchResultNoData,

    /**
     * The action resulted in new data being fetched.
     */
    UAActionFetchResultNewData = UIBackgroundFetchResultNewData,

    /**
     * The action failed.
     */
    UAActionFetchResultFailed = UIBackgroundFetchResultFailed
};

/**
 * Represents the action status.
 */
typedef NS_ENUM(NSInteger, UAActionStatus) {
    /**
     * The action accepted the arguments and executed without an error.
     */
    UAActionStatusCompleted,

    /**
     * The action was not performed because the arguments were rejected by
     * either the predicate in the registry or the action.
     */
    UAActionStatusArgumentsRejected,

    /**
     * The action was not performed because the action was not found
     * in the registry. This value is only possible if trying to run an
     * action by name through the runner.
     */
    UAActionStatusActionNotFound,

    /**
     * The action encountered an error during execution.
     */
    UAActionStatusError
};

NS_ASSUME_NONNULL_BEGIN

/**
 * A class that holds the results of running an action, with optional metadata.
 */
@interface UAActionResult : NSObject

///---------------------------------------------------------------------------------------
/// @name Action Result Properties
///---------------------------------------------------------------------------------------

/**
 * The result value produced when running an action (can be nil).
 */
@property (nonatomic, strong, readonly, nullable) id value;

/**
 * An optional UAActionFetchResult that can be set if the action performed a background fetch.
 */
@property (nonatomic, assign, readonly) UAActionFetchResult fetchResult;

/**
 * An optional error value that can be set if the action was unable to perform its work successfully.
 */
@property (nonatomic, strong, readonly, nullable) NSError *error;

/**
 * The action's run status.
 */
@property (nonatomic, assign, readonly) UAActionStatus status;

///---------------------------------------------------------------------------------------
/// @name Action Result Creation
///---------------------------------------------------------------------------------------

/**
 * Creates a UAActionResult with the supplied value. The `fetchResult` and `error` properties
 * default to UAActionFetchResultNoData and nil, respectively.
 *
 * @param value An id typed value object.
 * @return An instance of UAActionResult.
 */
+ (instancetype)resultWithValue:(nullable id)value;

/**
 * Creates a UAActionResult with the supplied value and fetch result. The `error` property
 * defaults to nil.
 *
 * @param result An id typed value object.
 * @param fetchResult A UAActionFetchResult enum value.
 * @return An instance of UAActionResult.
 */
+ (instancetype)resultWithValue:(nullable id)result withFetchResult:(UAActionFetchResult)fetchResult;

/**
 * Creates an "empty" UAActionResult with the value, fetch result and error set to
 * nil, UAActionFetchResultNoData, and nil, respectively.
 */
+ (instancetype)emptyResult;

/**
 * Creates a UAActionResult with the value and fetch result set to
 * nil and UAActionFetchResultNoData, respectively. The `error` property
 * is set to the supplied argument.
 *
 * @param error An instance of NSError.
 */
+ (instancetype)resultWithError:(NSError *)error;

/**
 * Creates a UAActionResult with the value set to nil. The `error`
 * and `fetchResult` properties are set to the supplied arguments.
 *
 * @param error An instance of NSError.
 * @param fetchResult A UAActionFetchResult enum value.
 */
+ (instancetype)resultWithError:(NSError *)error withFetchResult:(UAActionFetchResult)fetchResult;

@end

NS_ASSUME_NONNULL_END
