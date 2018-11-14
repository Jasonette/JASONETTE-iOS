/* Copyright 2017 Urban Airship and Contributors */

#import "UAAddCustomEventAction.h"
#import "UACustomEvent+Internal.h"
#import "UAirship.h"
#import "UAAnalytics.h"
#import "UAAnalytics+Internal.h"

NSString * const UAAddCustomEventActionErrorDomain = @"UAAddCustomEventActionError";

@implementation UAAddCustomEventAction

- (BOOL)acceptsArguments:(UAActionArguments *)arguments {
    if ([arguments.value isKindOfClass:[NSDictionary class]]) {
        NSString *eventName = [arguments.value valueForKey:UACustomEventNameKey];
        if (eventName) {
            return YES;
        } else {
            UA_LDEBUG(@"UAAddCustomEventAction requires an event name in the event data.");
            return NO;
        }
    } else {
        UA_LDEBUG(@"UAAddCustomEventAction requires a dictionary of event data.");
        return NO;
    }
}

- (void)performWithArguments:(UAActionArguments *)arguments
           completionHandler:(UAActionCompletionHandler)completionHandler {

    NSDictionary *dict = [NSDictionary dictionaryWithDictionary:arguments.value];

    NSString *eventName = [self parseStringFromDictionary:dict key:UACustomEventNameKey];
    NSString *eventValue = [self parseStringFromDictionary:dict key:UACustomEventValueKey];
    NSString *interactionID = [self parseStringFromDictionary:dict key:UACustomEventInteractionIDKey];
    NSString *interactionType = [self parseStringFromDictionary:dict key:UACustomEventInteractionTypeKey];
    NSString *transactionID = [self parseStringFromDictionary:dict key:UACustomEventTransactionIDKey];
    id properties = dict[UACustomEventPropertiesKey];

    UACustomEvent *event = [UACustomEvent eventWithName:eventName valueFromString:eventValue];
    event.transactionID = transactionID;

    if (interactionID || interactionType) {
        event.interactionType = interactionType;
        event.interactionID = interactionID;
    } else {
        id message = [arguments.metadata objectForKey:UAActionMetadataInboxMessageKey];
        if (message) {
#if !TARGET_OS_TV
            [event setInteractionFromMessage:message];
#endif
        }
    }

    // Set the conversion send ID if the action was triggered from a push
    event.conversionSendID = arguments.metadata[UAActionMetadataPushPayloadKey][@"_"];

    // Set the conversion send Metadata if the action was triggered from a push
    event.conversionPushMetadata = arguments.metadata[UAActionMetadataPushPayloadKey][kUAPushMetadata];

    if (properties && [properties isKindOfClass:[NSDictionary class]]) {
        for (id key in properties) {

            if (![key isKindOfClass:[NSString class]]) {
                UA_LWARN(@"Only String keys are allowed for custom event properties.");
                continue;
            }

            id value = properties[key];

            if ([value isKindOfClass:[NSString class]]) {
                [event setStringProperty:value forKey:key];
            } else if ([value isKindOfClass:[NSArray class]]) {
                [event setStringArrayProperty:value forKey:key];
            } else if ([value isKindOfClass:[NSNumber class]]) {
                // BOOLs come in as NSNumbers
                [event setNumberProperty:value forKey:key];
            } else {
                UA_LWARN(@"Property %@ contains an invalid object: %@", key, value);
            }
        }
    }

    if ([event isValid]) {
        [event track];
        completionHandler([UAActionResult emptyResult]);
    } else {
        NSError *error = [NSError errorWithDomain:UAAddCustomEventActionErrorDomain
                                             code:UAAddCustomEventActionErrorCodeInvalidEventName
                                         userInfo:@{NSLocalizedDescriptionKey:@"Invalid custom event. Verify the event name is specified, event value must be a number, and all values must not exceed 255 characters."}];

        completionHandler([UAActionResult resultWithError:error]);
    }
}

/**
 * Helper method to parse a string from a dictionary's value.
 * @param dict The dictionary to be parsed.
 * @param key The specified key.
 * @return The string parsed from the dicitionary.
 */
- (NSString *)parseStringFromDictionary:(NSDictionary *)dict key:(NSString *)key {
    id value = [dict objectForKey:key];
    if (!value) {
        return nil;
    } else if ([value isKindOfClass:[NSString class]]) {
        return value;
    } else if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    } else {
        return [value description];
    }
}

@end
