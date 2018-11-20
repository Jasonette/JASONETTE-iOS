/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>

@class UAConfig;
@class UAPreferenceDataStore;
@class UAPush;

NS_ASSUME_NONNULL_BEGIN

/**
 * ChannelCapture checks the device clipboard for an expected token on app
 * foreground and displays an alert that allows the user to copy the Channel
 * or optionally open a url with the channel as an argument.
 */
@interface UAChannelCapture : NSObject

///---------------------------------------------------------------------------------------
/// @name Channel Capture Factory
///---------------------------------------------------------------------------------------

/**
 * Factory method to create the UAChannelCapture.
 *
 * @param config The Urban Airship config.
 * @param push The UAPush instance.
 * @param dataStore The UAPreferenceDataStore instance.
 *
 * @return A channel capture instance.
 */
+ (instancetype)channelCaptureWithConfig:(UAConfig *)config
                                    push:(UAPush *)push
                               dataStore:(UAPreferenceDataStore *)dataStore;

///---------------------------------------------------------------------------------------
/// @name Channel Capture Management
///---------------------------------------------------------------------------------------

/**
 * Enable channel capture for a specified duration.
 *
 * @param duration The length of time to enable channel capture for, in seconds.
 */
- (void)enable:(NSTimeInterval)duration;

/**
 * Disable channel capture.
 */
- (void)disable;

@end

NS_ASSUME_NONNULL_END
