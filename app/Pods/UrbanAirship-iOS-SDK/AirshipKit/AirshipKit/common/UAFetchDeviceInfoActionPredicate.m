/* Copyright 2017 Urban Airship and Contributors */

#import "UAFetchDeviceInfoActionPredicate+Internal.h"

@implementation UAFetchDeviceInfoActionPredicate

- (BOOL)applyActionArguments:(UAActionArguments *)args {
    return args.situation == UASituationManualInvocation || args.situation == UASituationWebViewInvocation;
}

@end
