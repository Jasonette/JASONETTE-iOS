/* Copyright 2017 Urban Airship and Contributors */


#import "UAFetchDeviceInfoAction.h"
#import "UAirship.h"
#import "UALocation.h"
#import "UAPush.h"
#import "UANamedUser.h"

@implementation UAFetchDeviceInfoAction

NSString *const UAChannelIDKey = @"channel_id";
NSString *const UANamedUserKey = @"named_user";
NSString *const UATagsKey = @"tags";
NSString *const UAPushOptInKey = @"push_opt_in";
NSString *const UALocationEnabledKey = @"location_enabled";

- (void)performWithArguments:(UAActionArguments *)arguments
           completionHandler:(UAActionCompletionHandler)completionHandler {
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:[UAirship push].channelID forKey:UAChannelIDKey];
    [dict setValue:[UAirship namedUser].identifier forKey:UANamedUserKey];
    
    NSArray *tags = [[UAirship push] tags];
    if (tags.count) {
        [dict setValue:tags forKey:UATagsKey];
    }

    BOOL optedIn = [UAirship push].authorizedNotificationOptions != 0;
    [dict setValue:@(optedIn) forKey:UAPushOptInKey];
    
    BOOL locationEnabled = [UAirship location].locationUpdatesEnabled;
    [dict setValue:@(locationEnabled) forKey:UALocationEnabledKey];
    
    completionHandler([UAActionResult resultWithValue:dict]);
}

@end
