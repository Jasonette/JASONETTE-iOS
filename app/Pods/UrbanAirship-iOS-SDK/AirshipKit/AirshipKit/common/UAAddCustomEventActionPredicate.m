/* Copyright 2017 Urban Airship and Contributors */

#import "UAAddCustomEventActionPredicate+Internal.h"

@implementation UAAddCustomEventActionPredicate

- (BOOL)applyActionArguments:(UAActionArguments *)args {
    BOOL foregroundPresentation = args.metadata[UAActionMetadataForegroundPresentationKey] != nil;
    return (BOOL)!foregroundPresentation;
}

@end
