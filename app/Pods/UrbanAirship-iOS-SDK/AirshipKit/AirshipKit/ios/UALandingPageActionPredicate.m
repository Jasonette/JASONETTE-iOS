/* Copyright 2017 Urban Airship and Contributors */

#import "UALandingPageActionPredicate+Internal.h"
#import "UALandingPageAction.h"
#import "UAirship.h"
#import "UAApplicationMetrics.h"

@implementation UALandingPageActionPredicate

- (BOOL)applyActionArguments:(UAActionArguments *)args {
    if (UASituationBackgroundPush == args.situation) {
        UAApplicationMetrics *metrics = [UAirship shared].applicationMetrics;
        NSTimeInterval timeSinceLastOpen = [[NSDate date] timeIntervalSinceDate:metrics.lastApplicationOpenDate];
        return (BOOL)(timeSinceLastOpen <= [kUALandingPageActionLastOpenTimeLimitInSeconds doubleValue]);
    }

    return (BOOL)(args.situation != UASituationForegroundPush);
}

@end
