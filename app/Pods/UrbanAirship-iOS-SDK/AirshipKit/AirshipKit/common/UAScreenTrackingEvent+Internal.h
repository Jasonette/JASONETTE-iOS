/* Copyright 2017 Urban Airship and Contributors */

#import "UAEvent.h"

#define kUAScreenTrackingEventType @"screen_tracking"

#define kUAScreenTrackingEventMaxCharacters 255
#define kUAScreenTrackingEventMinCharacters 1

#define kUAScreenTrackingEventScreenKey @"screen"
#define kUAScreenTrackingEventPreviousScreenKey @"previous_screen"
#define kUAScreenTrackingEventEnteredTimeKey @"entered_time"
#define kUAScreenTrackingEventExitedTimeKey @"exited_time"
#define kUAScreenTrackingEventDurationKey @"duration"


@interface UAScreenTrackingEvent : UAEvent

///---------------------------------------------------------------------------------------
/// @name Screen Tracking Event Internal Properties
///---------------------------------------------------------------------------------------

/**
 * The tracking event start time
 */
@property (nonatomic, assign) NSTimeInterval startTime;

/**
 * The tracking event stop time
 */
@property (nonatomic, assign) NSTimeInterval stopTime;

/**
 * The tracking event duration
 */
@property (nonatomic, assign) NSTimeInterval duration;

/**
 * The name of the screen to be tracked
 */
@property (nonatomic, copy, nonnull) NSString *screen;

/**
 * The name of the previous tracked screen
 */
@property (nonatomic, copy, nullable) NSString *previousScreen;

///---------------------------------------------------------------------------------------
/// @name Screen Tracking Event Internal Factory
///---------------------------------------------------------------------------------------

/**
 * Factory method to create a UAScreenTrackingEvent with screen name and startTime
 */
+ (nullable instancetype)eventWithScreen:(nonnull NSString *)screen startTime:(NSTimeInterval)startTime;

@end
