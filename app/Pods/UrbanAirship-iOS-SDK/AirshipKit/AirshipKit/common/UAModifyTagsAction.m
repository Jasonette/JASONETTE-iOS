/* Copyright 2017 Urban Airship and Contributors */

#import "UAModifyTagsAction.h"
#import "UAirship.h"
#import "UAPush.h"
#import "UANamedUser.h"

NSString *const UAModifyTagsNamedUserKey = @"named_user";
NSString *const UAModifyTagsChannelKey = @"channel";

@implementation UAModifyTagsAction

- (BOOL)acceptsArguments:(UAActionArguments *)arguments {
    //no background push
    if (arguments.situation == UASituationBackgroundPush) {
        return NO;
    };

    //argument value can be a string (one tag)
    if ([arguments.value isKindOfClass:[NSString class]]) {
        return YES;
    }
    
    // argument value can be a map of tag groups
    if ([arguments.value isKindOfClass:[NSDictionary class]]) {
        
        // keys must be a string
        for (id obj in arguments.value) {
            if (![obj isKindOfClass:[NSString class]]) {
                return NO;
            }
        }
        
        // values must be a dictionary of tag groups
        for (id obj in [arguments.value allValues]) {
            if (![obj isKindOfClass:[NSDictionary class]]) {
                return NO;
            }
            
            // the groups must be strings
            for (id group in obj) {
                if (![group isKindOfClass:[NSString class]]) {
                    return NO;
                }
            }
            
            // the tags must be in arrays
            for (id tags in [obj allValues]) {
                if (![tags isKindOfClass:[NSArray class]]) {
                    return NO;
                }
            }
        }
        
        return YES;
    }

    //or it can be an array, in which case the elements must all be strings
    if ([arguments.value isKindOfClass:[NSArray class]]) {
        for (id obj in arguments.value) {
            if (![obj isKindOfClass:[NSString class]]) {
                return NO;
            }
        }
        return  YES;
    } else {
        return NO;
    }
}


- (void)performWithArguments:(UAActionArguments *)arguments
           completionHandler:(UAActionCompletionHandler)completionHandler {
    if ([arguments.value isKindOfClass:[NSString class]]) {
        [self applyChannelTags:@[arguments.value]];
        [[UAirship push] updateRegistration];
    } else if ([arguments.value isKindOfClass:[NSArray class]]) {
        [self applyChannelTags:arguments.value];
        [[UAirship push] updateRegistration];
    } else if ([arguments.value isKindOfClass:[NSDictionary class]]) {
        id channelTags = arguments.value[UAModifyTagsChannelKey];
        if (channelTags && [channelTags isKindOfClass:[NSDictionary class]]) {
            for (id key in channelTags) {
                [self applyChannelTags:channelTags[key] group:key];
            }

            [[UAirship push] updateRegistration];
        }

        id namedUserTags = arguments.value[UAModifyTagsNamedUserKey];
        if (namedUserTags && [namedUserTags isKindOfClass:[NSDictionary class]]) {
            for (id key in namedUserTags) {
                [self applyNamedUserTags:namedUserTags[key] group:key];
            }

            [[UAirship namedUser] updateTags];
        }
    }

    completionHandler([UAActionResult emptyResult]);
}

- (void)applyChannelTags:(NSArray *)tags {}

- (void)applyChannelTags:(NSArray *)tags group:(NSString *)group {}

- (void)applyNamedUserTags:(NSArray *)tags group:(NSString *)group {}

@end
