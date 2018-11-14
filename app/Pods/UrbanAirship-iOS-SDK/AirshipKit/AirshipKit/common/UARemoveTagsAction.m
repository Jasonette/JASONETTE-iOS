/* Copyright 2017 Urban Airship and Contributors */

#import "UARemoveTagsAction.h"
#import "UAPush.h"
#import "UAirship.h"
#import "UATagsActionPredicate+Internal.h"

@implementation UARemoveTagsAction

- (void)applyChannelTags:(NSArray *)tags {
    [[UAirship push] removeTags:tags];
}

- (void)applyChannelTags:(NSArray *)tags group:(NSString *)group {
    [[UAirship push] removeTags:tags group:group];
}

- (void)applyNamedUserTags:(NSArray *)tags group:(NSString *)group {
    [[UAirship namedUser] removeTags:tags group:group];
}

@end
