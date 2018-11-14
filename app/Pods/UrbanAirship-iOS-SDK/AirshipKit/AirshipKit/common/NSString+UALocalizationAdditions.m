/* Copyright 2017 Urban Airship and Contributors */

#import "NSString+UALocalizationAdditions.h"
#import "UAirship.h"

@implementation NSString (UALocalizationAdditions)

- (NSString *)sanitizedLocalizedStringWithTable:(NSString *)table primaryBundle:(NSBundle *)primaryBundle fallbackBundle:(NSBundle *)fallbackBundle {

    NSString *string;

    // This "empty" string has a space in it, so as not to be treated as equivalent to nil
    // by the NSBundle method
    NSString *missing = @" ";

    if (primaryBundle) {
        string = NSLocalizedStringWithDefaultValue(self, table, primaryBundle, missing, nil);
    }

    if (!string || [string isEqualToString:missing]) {
        if (fallbackBundle) {
            string = NSLocalizedStringWithDefaultValue(self, table, fallbackBundle, missing, nil);
        }
    }

    if (!string || [string isEqualToString:missing]) {
        return nil;
    }

    return string;
}

- (NSString *)localizedStringWithTable:(NSString *)table defaultValue:(NSString *)defaultValue fallbackLocale:(NSString *)fallbackLocale {

    NSBundle *primaryBundle = [NSBundle mainBundle];

    // If the string couldn't be found in the main bundle, search AirshipResources
    NSBundle *fallbackBundle = [UAirship resources];

    NSString *string = [self sanitizedLocalizedStringWithTable:table primaryBundle:primaryBundle fallbackBundle:fallbackBundle];
    if (!string) {
        if (fallbackLocale) {
            // If a fallback locale was provided, try searching in that locale explicitly
            primaryBundle = [NSBundle bundleWithPath:[primaryBundle pathForResource:fallbackLocale ofType:@"lproj"]];
            fallbackBundle = [NSBundle bundleWithPath:[fallbackBundle pathForResource:fallbackLocale ofType:@"lproj"]];

            string = [self sanitizedLocalizedStringWithTable:table primaryBundle:primaryBundle fallbackBundle:fallbackBundle];
        }
    }

    // If the bundle wasn't loaded correctly, it's possible the result value could be nil.
    // Convert to the key as a last resort in this case.
    return string ?: defaultValue;
}

- (NSString *)localizedStringWithTable:(NSString *)table defaultValue:(NSString *)defaultValue {
    return [self localizedStringWithTable:table defaultValue:defaultValue fallbackLocale:nil];
}

- (NSString *)localizedStringWithTable:(NSString *)table {
    return [self localizedStringWithTable:table defaultValue:self];
}

- (NSString *)localizedStringWithTable:(NSString *)table fallbackLocale:(NSString *)fallbackLocale {
    return [self localizedStringWithTable:table defaultValue:self fallbackLocale:fallbackLocale];
}

- (BOOL)localizedStringExistsInTable:(NSString *)table {
    return ([self localizedStringExistsInTable:table fallbackLocale:nil]);
}

- (BOOL)localizedStringExistsInTable:(NSString *)table fallbackLocale:(NSString *)fallbackLocale {
    return ([self localizedStringWithTable:table defaultValue:nil fallbackLocale:fallbackLocale] != nil);
}

@end

