/* Copyright 2017 Urban Airship and Contributors */


#import "UAApplicationMetrics+Internal.h"
#import "UAPreferenceDataStore+Internal.h"

@interface UAApplicationMetrics()
@property (nonatomic, strong) UAPreferenceDataStore *dataStore;
@end

@implementation UAApplicationMetrics
NSString *const UAApplicationMetricLastOpenDate = @"UAApplicationMetricLastOpenDate";

- (instancetype)initWithDataStore:(UAPreferenceDataStore *)dataStore {
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
        // App inactive/active for incoming calls, notification center, and taskbar
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }

    return self;
}

+ (instancetype)applicationMetricsWithDataStore:(UAPreferenceDataStore *)dataStore {
    return [[UAApplicationMetrics alloc] initWithDataStore:dataStore];
}

- (void)didBecomeActive {
    self.lastApplicationOpenDate = [NSDate date];
}

- (NSDate *)lastApplicationOpenDate {
    return [self.dataStore objectForKey:UAApplicationMetricLastOpenDate];
}

- (void)setLastApplicationOpenDate:(NSDate *)date {
    [self.dataStore setObject:date forKey:UAApplicationMetricLastOpenDate];
}

@end
