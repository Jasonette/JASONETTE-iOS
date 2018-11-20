/* Copyright 2017 Urban Airship and Contributors */

#import "UAAssociatedIdentifiers.h"
#import "UAGlobal.h"

#define kUAAssociatedIdentifierIDFAKey @"com.urbanairship.idfa"
#define kUAAssociatedIdentifierVendorKey @"com.urbanairship.vendor"
#define kUAAssociatedIdentifierLimitedAdTrackingEnabledKey @"com.urbanairship.limited_ad_tracking_enabled"

@interface UAAssociatedIdentifiers()
@property (nonatomic, strong) NSMutableDictionary *mutableIDs;
@end

@implementation UAAssociatedIdentifiers

NSUInteger const UAAssociatedIdentifiersMaxCount = 100;
NSUInteger const UAAssociatedIdentifiersMaxCharacterCount = 255;

- (instancetype) init {
    self = [super init];
    if (self) {
        self.mutableIDs = [NSMutableDictionary dictionary];
    }

    return self;
}

+ (instancetype)identifiers {
    return [[UAAssociatedIdentifiers alloc] init];
}

+ (instancetype)identifiersWithDictionary:(NSDictionary *)identifiers {
    UAAssociatedIdentifiers *associatedIdentifiers = [[UAAssociatedIdentifiers alloc] init];

    for (id key in identifiers) {
        id value = identifiers[key];
        if ([key isKindOfClass:[NSString class]] && [value isKindOfClass:[NSString class]]) {
            [associatedIdentifiers setIdentifier:value forKey:key];
        } else {
            UA_LWARN(@"Unable to create associated identifiers instance when dictionary contains a non string key/value for key: %@", key);
        }
    }

    return associatedIdentifiers;
}

- (void)setAdvertisingID:(NSString *)advertisingID {
    [self setIdentifier:advertisingID forKey:kUAAssociatedIdentifierIDFAKey];
}

- (NSString *)advertisingID {
    return [self.mutableIDs valueForKey:kUAAssociatedIdentifierIDFAKey];
}

- (void)setVendorID:(NSString *)vendorID {
    [self setIdentifier:vendorID forKey:kUAAssociatedIdentifierVendorKey];
}

- (NSString *)vendorID {
    return [self.mutableIDs valueForKey:kUAAssociatedIdentifierVendorKey];
}

- (void)setAdvertisingTrackingEnabled:(BOOL)advertisingTrackingEnabled {
    // If advertisingTrackingEnabled is `YES`, store the limitedAdTrackingEnabled value as `false`
    [self setIdentifier:(advertisingTrackingEnabled ? @"false" : @"true") forKey:kUAAssociatedIdentifierLimitedAdTrackingEnabledKey];
}

- (BOOL)advertisingTrackingEnabled {
    return ![[self.mutableIDs valueForKey:kUAAssociatedIdentifierLimitedAdTrackingEnabledKey] isEqualToString:@"true"];
}

- (void)setIdentifier:(NSString *)identifier forKey:(NSString *)key {
    if (!key) {
        return;
    }

    if (identifier) {
        [self.mutableIDs setObject:identifier forKey:key];
    } else {
        [self.mutableIDs removeObjectForKey:key];
    }
}

- (NSDictionary *)allIDs {
    return [self.mutableIDs copy];
}

@end
