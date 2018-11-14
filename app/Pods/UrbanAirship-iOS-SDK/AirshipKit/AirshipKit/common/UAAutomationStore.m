/* Copyright 2017 Urban Airship and Contributors */

#import "NSManagedObjectContext+UAAdditions.h"
#import "UAAutomationStore+Internal.h"
#import "UAActionScheduleData+Internal.h"
#import "UAScheduleTriggerData+Internal.h"
#import "UAScheduleDelayData+Internal.h"

#import "UAActionSchedule.h"
#import "NSJSONSerialization+UAAdditions.h"
#import "UAScheduleTrigger+Internal.h"
#import "UAirship.h"
#import "UAJSONPredicate.h"
#import "UAConfig.h"
#import "UAUtils.h"

@interface UAAutomationStore ()
@property (nonatomic, strong) NSManagedObjectContext *managedContext;
@property (nonatomic, copy) NSString *storeName;

@end

NSString *const UAAutomationStoreFileFormat = @"Automation-%@.sqlite";

@implementation UAAutomationStore


- (instancetype)initWithConfig:(UAConfig *)config {
    self = [super init];

    if (self) {
        self.storeName = [NSString stringWithFormat:UAAutomationStoreFileFormat, config.appKey];
        NSURL *modelURL = [[UAirship resources] URLForResource:@"UAAutomation" withExtension:@"momd"];
        self.managedContext = [NSManagedObjectContext managedObjectContextForModelURL:modelURL
                                                                      concurrencyType:NSPrivateQueueConcurrencyType];

        [self.managedContext addPersistentSqlStore:self.storeName completionHandler:^(BOOL success, NSError *error) {
            if (!success) {
                UA_LERR(@"Failed to create automation persistent store: %@", error);
            }
        }];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(protectedDataAvailable)
                                                     name:UIApplicationProtectedDataDidBecomeAvailable
                                                   object:nil];

    }

    return self;
}

+ (instancetype)automationStoreWithConfig:(UAConfig *)config {
    return [[UAAutomationStore alloc] initWithConfig:config];
}


- (void)protectedDataAvailable {
    if (!self.managedContext.persistentStoreCoordinator.persistentStores.count) {
        [self.managedContext addPersistentSqlStore:self.storeName completionHandler:^(BOOL success, NSError *error) {
            if (!success) {
                UA_LERR(@"Failed to create automation persistent store: %@", error);
            }
        }];
    }
}


#pragma mark -
#pragma mark Data Access

- (void)saveSchedule:(UAActionSchedule *)schedule limit:(NSUInteger)limit completionHandler:(void (^)(BOOL))completionHandler {
    [self.managedContext safePerformBlock:^(BOOL isSafe) {
        if (!isSafe) {
            completionHandler(NO);
            return;
        }

        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"UAActionScheduleData"];
        NSUInteger count = [self.managedContext countForFetchRequest:request error:nil];
        if (count >= limit) {
            UA_LERR(@"Max schedule limit reached. Unable to save new schedule.");
            completionHandler(NO);
            return;
        }

        [self createScheduleDataFromSchedule:schedule];

        completionHandler([self.managedContext safeSave]);
    }];
}

- (void)deleteSchedulesWithPredicate:(NSPredicate *)predicate {
    [self.managedContext safePerformBlock:^(BOOL isSafe) {
        if (!isSafe) {
            return;
        }

        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"UAActionScheduleData"];
        request.predicate = predicate;

        NSError *error;

        if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){9, 0, 0}]) {
            NSBatchDeleteRequest *deleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
            [self.managedContext executeRequest:deleteRequest error:&error];
        } else {
            request.includesPropertyValues = NO;
            NSArray *schedules = [self.managedContext executeFetchRequest:request error:&error];
            for (NSManagedObject *schedule in schedules) {
                [self.managedContext deleteObject:schedule];
            }
        }

        if (error) {
            UA_LERR(@"Error deleting entities %@", error);
            return;
        }

        [self.managedContext safeSave];
    }];
}



- (void)fetchSchedulesWithPredicate:(NSPredicate *)predicate limit:(NSUInteger)limit completionHandler:(void (^)(NSArray<UAActionScheduleData *> *))completionHandler {
    [self.managedContext safePerformBlock:^(BOOL isSafe) {
        if (!isSafe) {
            completionHandler(@[]);
            return;
        }

        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"UAActionScheduleData"];
        request.predicate = predicate;
        request.fetchLimit = limit;

        NSError *error;
        NSArray *result = [self.managedContext executeFetchRequest:request error:&error];

        if (error) {
            UA_LERR(@"Error fetching schedules %@", error);
            completionHandler(@[]);
        } else {
            completionHandler(result);
            [self.managedContext safeSave];
        }

    }];
}




- (void)fetchTriggersWithPredicate:(NSPredicate *)predicate completionHandler:(void (^)(NSArray<UAScheduleTriggerData *> *))completionHandler {
    [self.managedContext safePerformBlock:^(BOOL isSafe) {
        if (!isSafe) {
            completionHandler(@[]);
            return;
        }

        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"UAScheduleTriggerData"];
        request.predicate = predicate;

        NSError *error;
        NSArray *result = [self.managedContext executeFetchRequest:request error:&error];
        if (error) {
            UA_LERR(@"Error fetching triggers %@", error);
            completionHandler(@[]);
        } else {
            completionHandler(result);
            [self.managedContext safeSave];
        }
    }];
}

#pragma mark -
#pragma mark Converters

- (UAActionScheduleData *)createScheduleDataFromSchedule:(UAActionSchedule *)schedule {
    UAActionScheduleData *scheduleData = [NSEntityDescription insertNewObjectForEntityForName:@"UAActionScheduleData"
                                                                       inManagedObjectContext:self.managedContext];

    scheduleData.identifier = schedule.identifier;
    scheduleData.limit = @(schedule.info.limit);
    scheduleData.actions = [NSJSONSerialization stringWithObject:schedule.info.actions];
    scheduleData.group = schedule.info.group;
    scheduleData.triggers = [self createTriggerDataFromTriggers:schedule.info.triggers scheduleStart:schedule.info.start];
    scheduleData.start = schedule.info.start;
    scheduleData.end = schedule.info.end;

    if (schedule.info.delay) {
        scheduleData.delay = [self createDelayDataFromDelay:schedule.info.delay scheduleStart:schedule.info.start];
    }

    return scheduleData;
}

- (UAScheduleDelayData *)createDelayDataFromDelay:(UAScheduleDelay *)delay scheduleStart:(NSDate *)scheduleStart {
    UAScheduleDelayData *delayData = [NSEntityDescription insertNewObjectForEntityForName:@"UAScheduleDelayData"
                                                                   inManagedObjectContext:self.managedContext];

    delayData.seconds = @(delay.seconds);
    delayData.appState = @(delay.appState);
    delayData.regionID = delay.regionID;
    delayData.screen = delay.screen;
    delayData.cancellationTriggers = [self createTriggerDataFromTriggers:delay.cancellationTriggers scheduleStart:scheduleStart];

    return delayData;
}

- (NSSet<UAScheduleTriggerData *> *)createTriggerDataFromTriggers:(NSArray <UAScheduleTrigger *> *)triggers scheduleStart:(NSDate *)scheduleStart {
    NSMutableSet *data = [NSMutableSet set];

    for (UAScheduleTrigger *trigger in triggers) {
        UAScheduleTriggerData *triggerData = [NSEntityDescription insertNewObjectForEntityForName:@"UAScheduleTriggerData"
                                                                           inManagedObjectContext:self.managedContext];
        triggerData.type = @(trigger.type);
        triggerData.goal = trigger.goal;
        triggerData.start = scheduleStart;

        if (trigger.predicate) {
            triggerData.predicateData = [NSJSONSerialization dataWithJSONObject:trigger.predicate.payload options:0 error:nil];
        }

        [data addObject:triggerData];
    }

    return data;
}


@end
