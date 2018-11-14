/* Copyright 2017 Urban Airship and Contributors */

#import "UAChannelRegistrar.h"

@class UAChannelRegistrationPayload;
@class UAChannelAPIClient;
@class UAConfig;

NS_ASSUME_NONNULL_BEGIN

@interface UAChannelRegistrar ()

///---------------------------------------------------------------------------------------
/// @name Channel Registrar Delegate Internal Properties
///---------------------------------------------------------------------------------------

/**
 * The channel API client.
 */
@property (nonatomic, strong) UAChannelAPIClient *channelAPIClient;


/**
 * The last successful payload that was registered.
 */
@property (nonatomic, strong, nullable) UAChannelRegistrationPayload *lastSuccessPayload;


/**
 * A flag indicating if registration is in progress.
 */
@property (atomic, assign) BOOL isRegistrationInProgress;

///---------------------------------------------------------------------------------------
/// @name Channel Registrar Delegate Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Factory method to create a channel registrar.
 * @param config The Urban Airship config.
 * @return A new channel registrar instance.
 */
+ (instancetype)channelRegistrarWithConfig:(UAConfig *)config;

@end

NS_ASSUME_NONNULL_END

