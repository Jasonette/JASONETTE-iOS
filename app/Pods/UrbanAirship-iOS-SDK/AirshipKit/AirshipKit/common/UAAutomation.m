 /* Copyright 2017 Urban Airship and Contributors */

#import "UAAutomation+Internal.h"
#import "UAAnalytics+Internal.h"
#import "UAAutomationStore+Internal.h"
#import "UAScheduleTriggerData+Internal.h"
#import "UAActionScheduleData+Internal.h"
#import "UAScheduleDelayData+Internal.h"
#import "UAActionSchedule+Internal.h"
#import "UAScheduleTrigger+Internal.h"

#import "UAirship.h"
#import "UAEvent.h"
#import "UARegionEvent+Internal.h"
#import "UACustomEvent+Internal.h"
#import "UAActionRunner+Internal.h"
#import "NSJSONSerialization+UAAdditions.h"
#import "UAJSONPredicate.h"
#import "UAPreferenceDataStore+Internal.h"

NSUInteger const UAAutomationScheduleLimit = 100;
NSString *const UAAutomationEnabled = @"UAAutomationEnabled";

@implementation UAAutomation

- (void)dealloc {
    [self cancelTimers];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithConfig:(UAConfig *)config dataStore:(UAPreferenceDataStore *)dataStore{
    self = [super init];

    if (self) {
        self.automationStore = [UAAutomationStore automationStoreWithConfig:config];
        self.preferenceDataStore = dataStore;
        self.activeTimers = [NSMutableArray array];
        self.isForegrounded = NO;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(enterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(enterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [self rescheduleTimers];
        
        [self updateTriggersWithType:UAScheduleTriggerAppInit argument:nil incrementAmount:1.0];
    }

    return self;
}

+ (instancetype)automationWithConfig:(UAConfig *)config dataStore:(UAPreferenceDataStore *)dataStore {
    return [[UAAutomation alloc] initWithConfig:config dataStore:dataStore];
}

#pragma mark -
#pragma mark Public API

- (void)scheduleActions:(UAActionScheduleInfo *)scheduleInfo completionHandler:(void (^)(UAActionSchedule *))completionHandler {
    // Only allow valid schedules to be saved
    if (!scheduleInfo.isValid) {
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil);
            });
        }

        return;
    }

    [self.preferenceDataStore setBool:YES forKey:UAAutomationEnabled];

    // Delete any expired schedules before trying to save a schedule to free up the limit
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"end <= %@", [NSDate date]];
    [self.automationStore deleteSchedulesWithPredicate:predicate];

    // Create a schedule to save
    UAActionSchedule *schedule = [UAActionSchedule actionScheduleWithIdentifier:[NSUUID UUID].UUIDString info:scheduleInfo];

    // Try to save the schedule
    [self.automationStore saveSchedule:schedule limit:UAAutomationScheduleLimit completionHandler:^(BOOL success) {
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(success ? schedule : nil);
            });
        }
    }];
}

- (void)cancelScheduleWithIdentifier:(NSString *)identifier {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    [self.automationStore deleteSchedulesWithPredicate:predicate];
    [self cancelTimersWithIdentifiers:[NSSet setWithArray:@[identifier]]];
}

- (void)cancelAll {
    [self.automationStore deleteSchedulesWithPredicate:nil];
    [self cancelTimers];
}

- (void)cancelSchedulesWithGroup:(NSString *)group {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"group == %@", group];
    [self.automationStore deleteSchedulesWithPredicate:predicate];
    [self cancelTimersWithGroup:group];
}

- (void)getScheduleWithIdentifier:(NSString *)identifier completionHandler:(void (^)(UAActionSchedule *))completionHandler {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@ && end >= %@", identifier, [NSDate date]];
    [self.automationStore fetchSchedulesWithPredicate:predicate limit:UAAutomationScheduleLimit completionHandler:^(NSArray<UAActionScheduleData *> *schedulesData) {
        UAActionSchedule *schedule;
        if (schedulesData.count) {
            schedule = [UAAutomation scheduleFromData:[schedulesData firstObject]];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(schedule);
        });
    }];
}

- (void)getSchedules:(void (^)(NSArray<UAActionSchedule *> *))completionHandler {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"end >= %@", [NSDate date]];
    [self.automationStore fetchSchedulesWithPredicate:predicate limit:UAAutomationScheduleLimit completionHandler:^(NSArray<UAActionScheduleData *> *schedulesData) {
        NSMutableArray *schedules = [NSMutableArray array];
        for (UAActionScheduleData *scheduleData in schedulesData) {
            [schedules addObject:[UAAutomation scheduleFromData:scheduleData]];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(schedules);
        });
    }];
}

- (void)getSchedulesWithGroup:(NSString *)group completionHandler:(void (^)(NSArray<UAActionSchedule *> *))completionHandler {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"group == %@ && end >= %@", group, [NSDate date]];
    [self.automationStore fetchSchedulesWithPredicate:predicate limit:UAAutomationScheduleLimit completionHandler:^(NSArray<UAActionScheduleData *> *schedulesData) {
        NSMutableArray *schedules = [NSMutableArray array];
        for (UAActionScheduleData *scheduleData in schedulesData) {
            [schedules addObject:[UAAutomation scheduleFromData:scheduleData]];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(schedules);
        });
    }];
}


#pragma mark -
#pragma mark Event listeners

- (void)didBecomeActive {
    [self enterForeground];

    // This handles the first active. enterForeground will handle future background->foreground
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
}

- (void)enterForeground {
    self.isForegrounded = YES;

    if (!self.activeTimers) {
        [self rescheduleTimers];
    }

    [self updateTriggersWithType:UAScheduleTriggerAppForeground argument:nil incrementAmount:1.0];
    [self scheduleConditionsChanged];
}

- (void)enterBackground {
    self.isForegrounded = NO;

    [self updateTriggersWithType:UAScheduleTriggerAppBackground argument:nil incrementAmount:1.0];
    [self scheduleConditionsChanged];
}

-(void)customEventAdded:(UACustomEvent *)event {
    [self updateTriggersWithType:UAScheduleTriggerCustomEventCount argument:event.payload incrementAmount:1.0];

    if (event.eventValue) {
        [self updateTriggersWithType:UAScheduleTriggerCustomEventValue argument:event.payload incrementAmount:[event.eventValue doubleValue]];
    }
}

-(void)regionEventAdded:(UARegionEvent *)event {
    UAScheduleTriggerType triggerType;

    if (event.boundaryEvent == UABoundaryEventEnter) {
        triggerType = UAScheduleTriggerRegionEnter;
        self.currentRegion = event.regionID;
    } else {
        triggerType = UAScheduleTriggerRegionExit;
        self.currentRegion = nil;
    }

    [self updateTriggersWithType:triggerType argument:event.payload incrementAmount:1.0];

    [self scheduleConditionsChanged];
}

-(void)screenTracked:(NSString *)screenName {
    if (screenName) {
        [self updateTriggersWithType:UAScheduleTriggerScreen argument:screenName incrementAmount:1.0];
    }

    self.currentScreen = screenName;
    [self scheduleConditionsChanged];
}

#pragma mark -
#pragma mark Event processing

- (void)updateTriggersWithType:(UAScheduleTriggerType)triggerType argument:(id)argument incrementAmount:(double)amount {
    if (![self.preferenceDataStore boolForKey:UAAutomationEnabled]) {
        return;
    }

    UA_LDEBUG(@"Updating triggers with type: %ld", (long)triggerType);

    NSDate *start = [NSDate date];
    // Only update schedule triggers and active cancellation triggers
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(type = %ld AND start <= %@) AND (delay == nil || delay.schedule.isPendingExecution = 1)", triggerType, start];

    [self.automationStore fetchTriggersWithPredicate:predicate completionHandler:^(NSArray<UAScheduleTriggerData *> *triggers) {

        // Capture what schedules need to be cancelled and executed in sets so we do not double process any schedules
        NSMutableSet *schedulesToCancel = [NSMutableSet set];
        NSMutableSet *schedulesToExecute = [NSMutableSet set];

        // Process triggers
        for (UAScheduleTriggerData *trigger in triggers) {
            UAJSONPredicate *predicate = [UAAutomation predicateFromData:trigger.predicateData];
            if (predicate && argument) {
                if (![predicate evaluateObject:argument]) {
                    continue;
                }
            }

            trigger.goalProgress = @([trigger.goalProgress doubleValue] + amount);
            if ([trigger.goalProgress compare:trigger.goal] != NSOrderedAscending) {
                trigger.goalProgress = 0;

                // A delay associated with a trigger indicates its a cancellation trigger
                if (trigger.delay) {
                    [schedulesToCancel addObject:trigger.delay.schedule];
                    continue;
                }

                // Normal execution trigger. Only reexecute schedules that are not currently pending
                if (trigger.schedule && ![trigger.schedule.isPendingExecution boolValue]) {
                    [schedulesToExecute addObject:trigger.schedule];
                }
            }
        }

        // Process all the schedules to execute
        [self processTriggeredSchedules:[schedulesToExecute allObjects]];

        // Process all the schedules to cancel
        for (UAActionScheduleData *scheduleData in schedulesToCancel) {
            UA_LTRACE(@"Pending automation schedule %@ execution canceled", scheduleData.identifier);
            scheduleData.isPendingExecution = @(NO);
            scheduleData.delayedExecutionDate = nil;
        }

        // Cancel timers
        if (schedulesToCancel.count) {
            NSSet *timersToCancel = [schedulesToCancel valueForKeyPath:@"identifier"];

            // Handle timers on the main queue
            dispatch_async(dispatch_get_main_queue(), ^{
                [self cancelTimersWithIdentifiers:timersToCancel];
            });
        }

        NSTimeInterval executionTime = -[start timeIntervalSinceNow];
        UA_LTRACE(@"Automation execution time: %f seconds, triggers: %ld, triggered schedules: %ld", executionTime, (unsigned long)triggers.count, (unsigned long)schedulesToExecute.count);
    }];
}

/**
 * Starts a timer for the schedule.
 *
 * @param scheduleData The schedule's data.
 */
- (void)startTimerForSchedule:(UAActionScheduleData *)scheduleData {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue:scheduleData.identifier forKey:@"identifier"];
    [userInfo setValue:scheduleData.group forKey:@"group"];
    [userInfo setValue:scheduleData.delayedExecutionDate forKey:@"delayedExecutionDate"];


    NSTimeInterval delay = [scheduleData.delay.seconds doubleValue];
    if (scheduleData.delayedExecutionDate) {
        delay = [scheduleData.delayedExecutionDate timeIntervalSinceNow];
    }

    if (delay <= 0) {
        delay = .1;
    }

    NSTimer *timer = [NSTimer timerWithTimeInterval:delay
                                             target:self
                                           selector:@selector(scheduleTimerFired:)
                                           userInfo:userInfo
                                            repeats:NO];

    // Schedule the timer on the main queue
    dispatch_async(dispatch_get_main_queue(), ^{

        // Make sure we have a background task identifier before starting the timer
        if (self.backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
            self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                UA_LTRACE(@"Automation background task expired. Cancelling delayed scheduled actions.");
                [self cancelTimers];
            }];

            // No background time. The timer will be rescheduled the next time the app is active
            if (self.backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
                UA_LTRACE(@"Unable to request background task for automation timer.");
                return;
            }
        }

        UA_LTRACE(@"Starting automation timer for %f seconds with user info %@", delay, timer.userInfo);
        [self.activeTimers addObject:timer];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    });
}

/**
 * Delay timer fired for a schedule. Method is called on the main queue.
 *
 * @param timer The timer.
 */
- (void)scheduleTimerFired:(NSTimer *)timer {
    // Called on the main queue

    [self.activeTimers removeObject:timer];

    UA_LTRACE(@"Automation timer fired: %@", timer.userInfo);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@ AND isPendingExecution = 1 AND delayedExecutionDate == %@",
                              timer.userInfo[@"identifier"], timer.userInfo[@"delayedExecutionDate"]];

    [self.automationStore fetchSchedulesWithPredicate:predicate limit:1 completionHandler:^(NSArray<UAActionScheduleData *> *schedules) {
        if (schedules.count != 1) {
            return;
        }

        UAActionScheduleData *scheduleData = schedules[0];

        // If the delayedExecutionDate is still in the future then the system time must have changed.
        // Update the delayedExcutionDate to now.
        if ([scheduleData.delayedExecutionDate compare:[NSDate date]] != NSOrderedAscending) {
            scheduleData.delayedExecutionDate = [NSDate date];
        }

        [self processTriggeredSchedules:schedules];

        // Check if we need to end the background task on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.activeTimers.count) {
                [self endBackgroundTask];
            }
        });
    }];
}

/**
 * Cancel timers by schedule identifiers.
 *
 * @param identifiers A set of identifiers to cancel.
 */
- (void)cancelTimersWithIdentifiers:(NSSet<NSString *> *)identifiers {
    for (NSTimer *timer in [self.activeTimers copy]) {
        if ([identifiers containsObject:timer.userInfo[@"identifier"]]) {
            if (timer.isValid) {
                [timer invalidate];
            }
            [self.activeTimers removeObject:timer];
        }
    }

    if (!self.activeTimers.count) {
        [self endBackgroundTask];
    }
}

/**
 * Cancel timers by schedule group.
 *
 * @param group A schedule group.
 */
- (void)cancelTimersWithGroup:(NSString *)group {
    for (NSTimer *timer in [self.activeTimers copy]) {
        if ([group isEqualToString:timer.userInfo[@"group"]]) {
            if (timer.isValid) {
                [timer invalidate];
            }
            [self.activeTimers removeObject:timer];
        }
    }

    if (!self.activeTimers.count) {
        [self endBackgroundTask];
    }
}

/**
 * Cancels all timers.
 */
- (void)cancelTimers {
    for (NSTimer *timer in self.activeTimers) {
        if (timer.isValid) {
            [timer invalidate];
        }
    }

    [self.activeTimers removeAllObjects];
    [self endBackgroundTask];
}

/**
 * Reschedules timers for any schedule that is pending execution and has a future delayed execution date.
 */
- (void)rescheduleTimers {
    [self cancelTimers];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isPendingExecution = 1 AND delayedExecutionDate > %@", [NSDate date]];
    [self.automationStore fetchSchedulesWithPredicate:predicate limit:UAAutomationScheduleLimit completionHandler:^(NSArray<UAActionScheduleData *> *schedules) {
        for (UAActionScheduleData *scheduleData in schedules) {

            // If the delayedExecutionDate is greater than the original delay it probably means a clock adjustment. Reset the delay.
            if ([scheduleData.delayedExecutionDate timeIntervalSinceNow] > [scheduleData.delay.seconds doubleValue]) {
                scheduleData.delayedExecutionDate = [NSDate dateWithTimeIntervalSinceNow:[scheduleData.delay.seconds doubleValue]];
            }

            [self startTimerForSchedule:scheduleData];
        }
    }];
}

/**
 * Called when one of the schedule conditions changes.
 */
- (void)scheduleConditionsChanged {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isPendingExecution = 1 AND (delayedExecutionDate == nil OR delayedExecutionDate =< %@)", [NSDate date]];
    [self.automationStore fetchSchedulesWithPredicate:predicate limit:UAAutomationScheduleLimit completionHandler:^(NSArray<UAActionScheduleData *> *schedules) {

        [self processTriggeredSchedules:schedules];
    }];
}

/**
 * Checks if a schedule that is pending execution is able to be executed.
 *
 * @param scheduleDelay The UAScheduleDelay to check.
 * @param delayedExecutionDate The delayed execution date.
 * @return YES if conditions are satisfied, otherwise NO.
 */
- (BOOL)isScheduleDelaySatisfied:(UAScheduleDelay *)scheduleDelay
            delayedExecutionDate:(NSDate *)delayedExecutionDate {

    if (delayedExecutionDate && [delayedExecutionDate compare:[NSDate date]] != NSOrderedAscending) {
        return NO;
    }

    if (!scheduleDelay) {
        return YES;
    }

    if (scheduleDelay.screen && ![scheduleDelay.screen isEqualToString:self.currentScreen]) {
        return NO;
    }

    if (scheduleDelay.regionID && ![scheduleDelay.regionID isEqualToString:self.currentRegion]) {
        return NO;
    }

    if (scheduleDelay.appState == UAScheduleDelayAppStateForeground && !self.isForegrounded) {
        return NO;
    }

    if (scheduleDelay.appState == UAScheduleDelayAppStateBackground && self.isForegrounded) {
        return NO;
    }

    return YES;
}

/**
 * Processes triggered schedules.
 *
 * @param schedules An array of triggered schedule data.
 */
- (void)processTriggeredSchedules:(NSArray<UAActionScheduleData *> *)schedules {
    NSMutableArray *executionBlocks = [NSMutableArray array];
    NSMutableArray *postExecutionBlocks = [NSMutableArray array];

    for (UAActionScheduleData *scheduleData in schedules) {
        // If the schedule has expired, delete it
        if ([scheduleData.end compare:[NSDate date]] == NSOrderedAscending) {
            [scheduleData.managedObjectContext deleteObject:scheduleData];
            UA_LTRACE(@"Schedule expired, deleting schedule: %@", scheduleData.identifier);
            continue;
        }

        // Seconds delay
        if (![scheduleData.isPendingExecution boolValue] && [scheduleData.delay.seconds doubleValue] > 0) {
            scheduleData.isPendingExecution = @(YES);
            scheduleData.delayedExecutionDate = [NSDate dateWithTimeIntervalSinceNow:[scheduleData.delay.seconds doubleValue]];

            // Reset the cancellation triggers
            for (UAScheduleTriggerData *cancellationTrigger in scheduleData.delay.cancellationTriggers) {
                cancellationTrigger.goalProgress = 0;
            }

            // Start a timer
            [self startTimerForSchedule:scheduleData];
            continue;
        }


        // Pull out any info required to check for conditions and run actions for the schedule on the main queue
        NSDictionary *actions = [NSJSONSerialization objectWithString:scheduleData.actions];
        NSString *scheduleIdentifier = scheduleData.identifier;
        UAScheduleDelay *scheduleDelay = [UAAutomation delayFromData:scheduleData.delay];
        NSDate *delayedExecutionDate = scheduleData.delayedExecutionDate;

        __block BOOL scheduleExecuted = NO;


        void (^executionBlock)(void) = ^{
            if ([self isScheduleDelaySatisfied:scheduleDelay delayedExecutionDate:delayedExecutionDate]) {
                // Run the actions
                [UAActionRunner runActionsWithActionValues:actions
                                                 situation:UASituationAutomation
                                                  metadata:nil
                                         completionHandler:^(UAActionResult *result) {
                                             UA_LINFO(@"Actions triggered for schedule: %@", scheduleIdentifier);
                                         }];
                scheduleExecuted = YES;
            }
        };

        void (^postExecutionBlock)(void) = ^{
            if (scheduleExecuted) {
                // Reset pending execution state
                scheduleData.isPendingExecution = @(NO);
                scheduleData.delayedExecutionDate = nil;

                if ([scheduleData.limit integerValue] > 0) {
                    scheduleData.triggeredCount = @([scheduleData.triggeredCount integerValue] + 1);
                    if (scheduleData.triggeredCount >= scheduleData.limit) {
                        UA_LINFO(@"Limit reached for schedule %@", scheduleIdentifier);
                        [scheduleData.managedObjectContext deleteObject:scheduleData];
                    }
                }
            } else if (![scheduleData.isPendingExecution boolValue]) {
                UA_LTRACE(@"Automation schedule %@ waiting on conditions.", scheduleData.identifier);

                // Reset the cancellation triggers
                for (UAScheduleTriggerData *cancellationTrigger in scheduleData.delay.cancellationTriggers) {
                    cancellationTrigger.goalProgress = 0;
                }

                scheduleData.isPendingExecution = @(YES);
            }
        };

        [executionBlocks addObject:executionBlock];
        [postExecutionBlocks addObject:postExecutionBlock];
    }

    // Conditions and action executions must be run on the main queue.
    dispatch_sync(dispatch_get_main_queue(), ^{
        for (void (^executionBlock)(void) in executionBlocks) {
            executionBlock();
        }
    });

    // Run all the post executions on the background queue
    for (void (^postExecutionBlock)(void) in postExecutionBlocks) {
        postExecutionBlock();
    }
}

/**
 * Helper method to end the background task if its not invalid.
 */
- (void)endBackgroundTask {
    if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }

}

#pragma mark -
#pragma mark Converters

+ (UAActionSchedule *)scheduleFromData:(UAActionScheduleData *)data {
    UAActionScheduleInfo *scheduleInfo = [UAActionScheduleInfo actionScheduleInfoWithBuilderBlock:^(UAActionScheduleInfoBuilder *builder) {
        builder.actions = [NSJSONSerialization objectWithString:data.actions];
        builder.triggers = [UAAutomation triggersFromData:data.triggers];
        builder.delay = [UAAutomation delayFromData:data.delay];
        builder.group = data.group;

    }];

    return [UAActionSchedule actionScheduleWithIdentifier:data.identifier info:scheduleInfo];
}

+ (NSArray<UAScheduleTrigger *> *)triggersFromData:(NSSet<UAScheduleTriggerData *> *)data {
    NSMutableArray *triggers = [NSMutableArray array];

    for (UAScheduleTriggerData *triggerData in data) {
        UAScheduleTrigger *trigger = [UAScheduleTrigger triggerWithType:(UAScheduleTriggerType)[triggerData.type integerValue]
                                                                   goal:triggerData.goal
                                                              predicate:[UAAutomation predicateFromData:triggerData.predicateData]];

        [triggers addObject:trigger];
    }

    return triggers;
}

+ (UAJSONPredicate *)predicateFromData:(NSData *)data {
    if (!data) {
        return nil;
    }

    id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    return [UAJSONPredicate predicateWithJSON:json error:nil];
}

+ (UAScheduleDelay *)delayFromData:(UAScheduleDelayData *)data {
    if (!data) {
        return nil;
    }

    return [UAScheduleDelay delayWithBuilderBlock:^(UAScheduleDelayBuilder *builder) {
        builder.seconds = [data.seconds doubleValue];
        builder.screen = data.screen;
        builder.regionID = data.regionID;
        builder.cancellationTriggers = [UAAutomation triggersFromData:data.cancellationTriggers];
        builder.appState = [data.appState integerValue];
    }];
}
@end

