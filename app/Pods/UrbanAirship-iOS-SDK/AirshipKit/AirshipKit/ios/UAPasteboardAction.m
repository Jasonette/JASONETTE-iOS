/* Copyright 2017 Urban Airship and Contributors */

#import "UAPasteboardAction.h"
#import "UAActionArguments.h"

@implementation UAPasteboardAction

- (BOOL)acceptsArguments:(UAActionArguments *)arguments {
    switch (arguments.situation) {
        case UASituationManualInvocation:
        case UASituationWebViewInvocation:
        case UASituationLaunchedFromPush:
        case UASituationBackgroundInteractiveButton:
        case UASituationForegroundInteractiveButton:
        case UASituationAutomation:
            return [self pasteboardStringWithArguments:arguments] != nil;
        case UASituationBackgroundPush:
        case UASituationForegroundPush:
            return NO;
    }
}

- (void)performWithArguments:(UAActionArguments *)arguments
           completionHandler:(UAActionCompletionHandler)completionHandler {

    [UIPasteboard generalPasteboard].string = [self pasteboardStringWithArguments:arguments];
    
    completionHandler([UAActionResult resultWithValue:arguments.value]);
}

- (NSString *)pasteboardStringWithArguments:(UAActionArguments *)arguments {
    if ([arguments.value isKindOfClass:[NSString class]]) {
        return arguments.value;
    }

    if ([arguments.value isKindOfClass:[NSDictionary class]] && [arguments.value[@"text"] isKindOfClass:[NSString class]]) {
        return arguments.value[@"text"];
    }

    return nil;
}

@end
