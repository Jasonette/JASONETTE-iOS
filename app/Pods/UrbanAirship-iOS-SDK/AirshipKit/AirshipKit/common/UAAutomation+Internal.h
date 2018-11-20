/* Copyright 2017 Urban Airship and Contributors */


#import "UAAutomation.h"
#import "UAAnalytics+Internal.h"
#import <UIKit/UIKit.h>

@class UAAutomationStore;

/*
 * SDK-private extensions to UAAutomation
 */
@interface UAAutomation () <UAAnalyticsDelegate>

///---------------------------------------------------------------------------------------
/// @name Automation Internal Properties
///---------------------------------------------------------------------------------------

/**
 * The automation data store.
 */
@property (nonatomic, strong) UAAutomationStore *automationStore;

/**
 * The preference data store.
 */
@property (nonatomic, strong) UAPreferenceDataStore *preferenceDataStore;

/**
 * The last screen name in which screenTracked: has been called.
 */
@property (nonatomic, copy) NSString *currentScreen;

/**
 * The region ID for the last region event with a boundary crossing of type
 * UABoundaryEventEnter, otherwise nil.
 */
@property (nonatomic, copy) NSString *currentRegion;

/**
 * Checks foreground state of application.
 */
@property (nonatomic, assign) BOOL isForegrounded;

/**
 * Current active timers.
 */
@property (nonatomic, strong) NSMutableArray *activeTimers;

/**
 * Background task identifier.
 */
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

///---------------------------------------------------------------------------------------
/// @name Automation Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Automation constructor.
 */
+ (instancetype)automationWithConfig:(UAConfig *)config dataStore:(UAPreferenceDataStore *)dataStore;

@end
