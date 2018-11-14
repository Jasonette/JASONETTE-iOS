/* Copyright 2017 Urban Airship and Contributors */

#import "UAOpenExternalURLAction.h"

NSString * const UAOpenExternalURLActionErrorDomain = @"com.urbanairship.actions.externalurlaction";

#define kUAOpenExternalURLActionDefaultRegistryName @"open_external_url_action"
#define kUAOpenExternalURLActionDefaultRegistryAlias @"^u"

@implementation UAOpenExternalURLAction

- (BOOL)acceptsArguments:(UAActionArguments *)arguments {
    if (arguments.situation == UASituationBackgroundPush || arguments.situation == UASituationBackgroundInteractiveButton) {
        return NO;
    }

    if ([arguments.value isKindOfClass:[NSString class]]) {
        return [NSURL URLWithString:arguments.value] != nil;
    }

    return [arguments.value isKindOfClass:[NSURL class]];
}

- (void)performWithArguments:(UAActionArguments *)arguments
           completionHandler:(UAActionCompletionHandler)completionHandler {

    NSURL *url = [self createURLFromValue:arguments.value];

    // do this in the background in case we're opening our own app!
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self openURL:url completionHandler:completionHandler];
    });
}

- (void)openURL:(NSURL *)url completionHandler:(UAActionCompletionHandler)completionHandler {
    if (([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 0, 0}])) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                if (!success) {
                    // Unable to open url
                    NSError *error =  [NSError errorWithDomain:UAOpenExternalURLActionErrorDomain
                                                          code:UAOpenExternalURLActionErrorCodeURLFailedToOpen
                                                      userInfo:@{NSLocalizedDescriptionKey : @"Unable to open URL"}];
                    
                    completionHandler([UAActionResult resultWithError:error]);
                } else {
                    completionHandler([UAActionResult resultWithValue:url.absoluteString]);
                }
            }];
        });
    }
#if !TARGET_OS_TV
    else if (![[UIApplication sharedApplication] openURL:url]) {
        // Unable to open url
        NSError *error =  [NSError errorWithDomain:UAOpenExternalURLActionErrorDomain
                                              code:UAOpenExternalURLActionErrorCodeURLFailedToOpen
                                          userInfo:@{NSLocalizedDescriptionKey : @"Unable to open URL"}];

        completionHandler([UAActionResult resultWithError:error]);
    }
#endif
    else {
        completionHandler([UAActionResult resultWithValue:url.absoluteString]);
    }
}

- (NSURL *)createURLFromValue:(id)value {
    NSURL *url = [value isKindOfClass:[NSURL class]] ? value : [NSURL URLWithString:value];

    if ([[url host] isEqualToString:@"phobos.apple.com"] || [[url host] isEqualToString:@"itunes.apple.com"]) {
        // Set the url scheme to http, as it could be itms which will cause the store to launch twice (undesireable)
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@%@", url.host, url.path]];
    } else if ([[url scheme] isEqualToString:@"tel"] || [[url scheme] isEqualToString:@"sms"]) {

        NSString *decodedUrlString = [url.absoluteString stringByRemovingPercentEncoding];
        NSCharacterSet *characterSet = [[NSCharacterSet characterSetWithCharactersInString:@"+-.0123456789"] invertedSet];
        NSString *strippedNumber = [[decodedUrlString componentsSeparatedByCharactersInSet:characterSet] componentsJoinedByString:@""];

        NSString *scheme = [decodedUrlString hasPrefix:@"sms"] ? @"sms:" : @"tel:";
        url = [NSURL URLWithString:[scheme stringByAppendingString:strippedNumber]];
    }

    return url;
}

@end
