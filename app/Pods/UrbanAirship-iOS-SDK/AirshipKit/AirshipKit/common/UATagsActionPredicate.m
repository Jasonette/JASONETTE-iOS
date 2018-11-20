/* Copyright 2017 Urban Airship and Contributors */

#import "UATagsActionPredicate+Internal.h"

@implementation UATagsActionPredicate

-(BOOL)applyActionArguments:(UAActionArguments *)args {
    BOOL foregroundPresentation = args.metadata[UAActionMetadataForegroundPresentationKey] != nil;
    return (BOOL)!foregroundPresentation;
}

@end
