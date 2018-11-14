/* Copyright 2017 Urban Airship and Contributors */

#import "UATagUtils+Internal.h"
#import "UAGlobal.h"

#define kUAMinTagLength 1
#define kUAMaxTagLength 127

@implementation UATagUtils

+ (NSArray *)normalizeTags:(NSArray *)tags {
    NSMutableSet *normalizedTags = [NSMutableSet set];

    for (NSString *tag in tags) {

        NSString *trimmedTag = [tag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        if ([trimmedTag length] >= kUAMinTagLength && [trimmedTag length] <= kUAMaxTagLength) {
            [normalizedTags addObject:trimmedTag];
        } else {
            UA_LERR(@"Tags must be > 0 and < 128 characters in length, tag %@ has been removed from the tag set", tag);
        }
    }

    return [normalizedTags allObjects];
}

+ (NSString *)normalizeTagGroupID:(NSString *)tagGroup {
    NSString *normalizedID = [tagGroup stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (!normalizedID.length) {
        UA_LERR(@"The tag group ID string cannot be nil or length must be greater 0.");
        return nil;
    }

    return normalizedID;
}
@end
