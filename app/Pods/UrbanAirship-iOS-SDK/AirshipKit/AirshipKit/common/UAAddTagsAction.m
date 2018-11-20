/* Copyright 2017 Urban Airship and Contributors */

#import "UAAddTagsAction.h"
#import "UATagsActionPredicate+Internal.h"
#import "UAPush.h"
#import "UAirship.h"


@implementation UAAddTagsAction

- (void)applyChannelTags:(NSArray *)tags {
    [[UAirship push] addTags:tags];
}

- (void)applyChannelTags:(NSArray *)tags group:(NSString *)group {
    [[UAirship push] addTags:tags group:group];
}

- (void)applyNamedUserTags:(NSArray *)tags group:(NSString *)group {
    [[UAirship namedUser] addTags:tags group:group];
}

@end
