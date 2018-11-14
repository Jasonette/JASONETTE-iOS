/* Copyright 2017 Urban Airship and Contributors */

#import "NSString+UALocalizationAdditions.h"

/**
 * Returns a localized string by key, searching the UAInbox table and falling back on
 * the "en" locale if necessary.
 */
#define UAMessageCenterLocalizedString(key) [key localizedStringWithTable:@"UrbanAirship" fallbackLocale:@"en"]

/**
 * Checks if a localized string exists for key, searching the UAInbox table and falling back on
 * the "en" locale if necessary.
 */
#define UAMessageCenterLocalizedStringExists(key) [key localizedStringExistsInTable:@"UrbanAirship" fallbackLocale:@"en"]
