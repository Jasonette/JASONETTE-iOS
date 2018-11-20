/* Copyright 2017 Urban Airship and Contributors */

#import "UAAssociateIdentifiersEvent+Internal.h"
#import "UAEvent+Internal.h"
#import "UAGlobal.h"

@implementation UAAssociateIdentifiersEvent

+ (instancetype)eventWithIDs:(UAAssociatedIdentifiers *)identifiers {
    UAAssociateIdentifiersEvent *event = [[self alloc] init];
    event.data = [NSDictionary dictionaryWithDictionary:identifiers.allIDs];
    return event;
}


- (BOOL)isValid {
    BOOL isValid = YES;

    if (self.data.count > UAAssociatedIdentifiersMaxCount) {
        UA_LERR(@"Associated identifiers count exceed %lu", (unsigned long)UAAssociatedIdentifiersMaxCount);
        isValid = NO;
    }

    for (NSString *key in self.data) {
        NSString *value = self.data[key];

        if (key.length > UAAssociatedIdentifiersMaxCharacterCount) {
            UA_LERR(@"Associated identifier %@ exceeds %lu characters", key, (unsigned long)UAAssociatedIdentifiersMaxCharacterCount);
            isValid = NO;
        }

        if (value.length > UAAssociatedIdentifiersMaxCharacterCount) {
            UA_LERR(@"Associated identifier %@ value exceeds %lu characters", key, (unsigned long)UAAssociatedIdentifiersMaxCharacterCount);
            isValid = NO;
        }
    }

    return isValid;
}

- (NSString *)eventType {
    return @"associate_identifiers";
}

@end
