/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

@class UAEvent;
@class UAAssociatedIdentifiers;

NS_ASSUME_NONNULL_BEGIN

/**
 * The UAAnalytics object provides an interface to the Urban Airship Analytics API.
 */
@interface UAAnalytics : NSObject

///---------------------------------------------------------------------------------------
/// @name Analytics Properties
///---------------------------------------------------------------------------------------

/**
 * The conversion send ID.
 */
@property (nonatomic, copy, readonly, nullable) NSString *conversionSendID;

/**
 * The conversion push metadata.
 */
@property (nonatomic, copy, readonly, nullable) NSString *conversionPushMetadata;

/**
 * The conversion rich push ID.
 */
@property (nonatomic, copy, readonly, nullable) NSString *conversionRichPushID;

/**
 * The current session ID.
 */
@property (nonatomic, copy, readonly) NSString *sessionID;

/**
 * Date representing the last attempt to send analytics.
 * @return NSDate representing the last attempt to send analytics
 */
@property (nonatomic, strong, readonly) NSDate *lastSendTime;

/**
 * Analytics enable flag. Disabling analytics will delete any locally stored events
 * and prevent any events from uploading. Features that depend on analytics being
 * enabled may not work properly if it's disabled (reports, region triggers,
 * location segmentation, push to local time).
 *
 * Note: This property will always return `NO` if analytics is disabled in
 * UAConfig.
 */
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

///---------------------------------------------------------------------------------------
/// @name Analytics Core Methods
///---------------------------------------------------------------------------------------

/**
 * Triggers an analytics event.
 * @param event The event to be triggered
 */
- (void)addEvent:(UAEvent *)event;

/**
 * Associates identifiers with the device. This call will add a special event
 * that will be batched and sent up with our other analytics events. Previous
 * associated identifiers will be replaced.
 *
 * @param associatedIdentifiers The associated identifiers.
 */
- (void)associateDeviceIdentifiers:(UAAssociatedIdentifiers *)associatedIdentifiers;

/**
 * The device's current associated identifiers.
 * @return The device's current associated identifiers.
 */
- (UAAssociatedIdentifiers *)currentAssociatedDeviceIdentifiers;

/**
 * Initiates screen tracking for a specific app screen, must be called once per tracked screen.
 * @param screen The screen's identifier as an NSString.
 */
- (void)trackScreen:(nullable NSString *)screen;

/**
 * Schedules an event upload if one is not already scheduled.
 */
- (void)scheduleUpload;

@end

NS_ASSUME_NONNULL_END
