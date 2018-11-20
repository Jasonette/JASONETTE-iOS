/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

@class UAChannelRegistrationPayload;

NS_ASSUME_NONNULL_BEGIN

/**
 * The UAChannelRegistrarDelegate protocol for registration events.
 */
@protocol UAChannelRegistrarDelegate <NSObject>
@optional

///---------------------------------------------------------------------------------------
/// @name Channel Registrar Delegate Methods
///---------------------------------------------------------------------------------------

/**
 * Called when the channel registrar failed to register.
 * @param payload The registration payload.
 */
- (void)registrationFailedWithPayload:(UAChannelRegistrationPayload *)payload;

/**
 * Called when the channel registrar successfully registered.
 * @param payload The registration payload.
 */
- (void)registrationSucceededWithPayload:(UAChannelRegistrationPayload *)payload;

/**
 * Called when the channel registrar creates a new channel.
 * @param channelID The channel ID string.
 * @param channelLocation The channel location string.
 * @param existing Boolean to indicate if the channel previously existed or not.
 */
- (void)channelCreated:(NSString *)channelID
       channelLocation:(NSString *)channelLocation
              existing:(BOOL)existing;

@end

/**
 * The UAChannelRegistrar class is responsible for device registrations.
 */
@interface UAChannelRegistrar : NSObject

///---------------------------------------------------------------------------------------
/// @name Channel Registrar Properties
///---------------------------------------------------------------------------------------

/**
 * A UAChannelRegistrarDelegate delegate.
 */
@property (nonatomic, weak, nullable) id<UAChannelRegistrarDelegate> delegate;


///---------------------------------------------------------------------------------------
/// @name Channel Registrar Registration Management
///---------------------------------------------------------------------------------------

/**
 * Register the device with Urban Airship.
 *
 * @param channelID The channel ID to update.  If `nil` is supplied, a channel will be created.
 * @param channelLocation The channel location.  If `nil` is supplied, a channel will be created.
 * @param payload The payload for the registration.
 * @param forcefully To force the registration, skipping duplicate request checks.
 */
- (void)registerWithChannelID:(nullable NSString *)channelID
              channelLocation:(nullable NSString *)channelLocation
                  withPayload:(UAChannelRegistrationPayload *)payload
                   forcefully:(BOOL)forcefully;

/**
 * Cancels all pending and current requests.  
 *
 * Note: This may or may not prevent the registration finished event and registration
 * delegate calls.
 */
- (void)cancelAllRequests;

@end

NS_ASSUME_NONNULL_END

