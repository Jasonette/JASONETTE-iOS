/* Copyright 2017 Urban Airship and Contributors */

#import "UAChannelRegistrationPayload+Internal.h"
#import "UAirship.h"
#import "UAAnalytics.h"


@implementation UAChannelRegistrationPayload

- (NSData *)asJSONData {
    return [NSJSONSerialization dataWithJSONObject:[self payloadDictionary]
                                           options:0
                                             error:nil];
}

- (NSDictionary *)payloadDictionary {
    NSMutableDictionary *payloadDictionary = [NSMutableDictionary dictionary];

    if (self.deviceID || self.userID) {
        NSMutableDictionary *identityHints = [NSMutableDictionary dictionary];
        [identityHints setValue:self.userID forKey:kUAChannelUserIDKey];
        [identityHints setValue:self.deviceID forKey:kUAChannelDeviceIDKey];
        [payloadDictionary setValue:identityHints forKey:kUAChannelIdentityHintsKey];
    }

    // Channel is a top level object containing channel related fields.
    NSMutableDictionary *channel = [NSMutableDictionary dictionary];
    [channel setValue:@"ios" forKey:kUAChannelDeviceTypeKey];
    [channel setValue:[NSNumber numberWithBool:self.optedIn] forKey:kUAChannelOptInKey];
#if TARGET_OS_TV    // REVISIT - do we need to force self.backgroundEnabled to YES?? - may be a hacking artifact
    [channel setValue:[NSNumber numberWithBool:YES] forKey:kUABackgroundEnabledJSONKey];
#else
    [channel setValue:[NSNumber numberWithBool:self.backgroundEnabled] forKey:kUABackgroundEnabledJSONKey];
#endif
    [channel setValue:self.pushAddress forKey:kUAChannelPushAddressKey];

    self.alias = [self.alias stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([self.alias length] > 0) {
        [channel setValue:self.alias forKey:kUAChannelAliasJSONKey];
    }

    [channel setValue:[NSNumber numberWithBool:self.setTags] forKey:kUAChannelSetTagsKey];
    if (self.setTags) {
        [channel setValue:self.tags forKey:kUAChannelTagsJSONKey];
    }

    if (self.badge || self.quietTime) {
        NSMutableDictionary *ios = [NSMutableDictionary dictionary];
        [ios setValue:self.badge forKey:kUAChannelBadgeJSONKey];
        [ios setValue:self.quietTime forKey:kUAChannelQuietTimeJSONKey];
        [ios setValue:self.timeZone forKey:kUAChannelTimeZoneJSONKey];

        [channel setValue:ios forKey:kUAChanneliOSKey];
    }

    // Set top level timezone and language keys
    [channel setValue:self.timeZone forKey:kUAChannelTopLevelTimeZoneJSONKey];
    [channel setValue:self.language forKey:kUAChannelTopLevelLanguageJSONKey];
    [channel setValue:self.country forKey:kUAChannelTopLevelCountryJSONKey];

    [payloadDictionary setValue:channel forKey:kUAChannelKey];

    return payloadDictionary;
}

- (id)copyWithZone:(NSZone *)zone {
    UAChannelRegistrationPayload *copy = [[[self class] alloc] init];

    if (copy) {
        copy.userID = self.userID;
        copy.deviceID = self.deviceID;
        copy.optedIn = self.optedIn;
        copy.backgroundEnabled = self.backgroundEnabled;
        copy.pushAddress = self.pushAddress;
        copy.setTags = self.setTags;
        copy.tags = [self.tags copyWithZone:zone];
        copy.alias = self.alias;
        copy.quietTime = [self.quietTime copyWithZone:zone];
        copy.timeZone = self.timeZone;
        copy.language = self.language;
        copy.country = self.country;
        copy.badge = [self.badge copyWithZone:zone];
    }

    return copy;
}

- (BOOL)isEqualToPayload:(UAChannelRegistrationPayload *)payload {
    return [[self payloadDictionary] isEqualToDictionary:[payload payloadDictionary]];
}

- (NSString *)description {
    return [[self payloadDictionary] description];
}

@end
