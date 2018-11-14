/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

@interface NSString (UALocalizationAdditions)

///---------------------------------------------------------------------------------------
/// @name NSString Localization Additions Core Methods
///---------------------------------------------------------------------------------------

/**
 * Returns a localized string associated to the receiver by the given table, returning the receiver if the
 * string cannot be found. This method searches the main bundle before falling back on AirshipResources,
 * allowing for developers to override or supplement any officially bundled localizations.
 *
 * @param table The table.
 * @param defaultValue The default value.
 * @return The localized string corresponding to the key and table, or the default value if it cannot be found.
 */
- (NSString *)localizedStringWithTable:(NSString *)table defaultValue:(NSString *)defaultValue;

/**
 * Returns a localized string associated to the receiver by the given table, returning the receiver if the
 * string cannot be found. This method searches the main bundle before falling back on AirshipResources,
 * allowing for developers to override or supplement any officially bundled localizations.
 *
 * @param table The table.
 * @return The localized string corresponding to the key and table, or the key if it cannot be found.
 */
- (NSString *)localizedStringWithTable:(NSString *)table;

/**
 * Returns a localized string associated to the receiver by the given table, falling back on the provided
 * locale and finally the receiver if the string cannot be found. This method searches the main bundle before
 * falling back on AirshipResources, allowing for developers to override or supplement any officially bundled localizations.
 *
 * @param table The table.
 * @param fallbackLocale The locale to use in case a localized string for the current locale cannot be found.
 * @return The localized string corresponding to the key and table, or the key if it cannot be found.
 */
- (NSString *)localizedStringWithTable:(NSString *)table fallbackLocale:(NSString *)fallbackLocale;

/**
 * Checks if a localized string associated to the receiver exists in the given table. This method searches
 * the main bundle before falling back on AirshipResources, allowing for developers to override or supplement
 * any officially bundled localizations.
 *
 * @param table The table.
 * @return YES if a localized string corresponding to the key and table was found, or NO if it cannot be found.
 */
- (BOOL)localizedStringExistsInTable:(NSString *)table;

/**
 * Checks if a localized string associated to the receiver exists in the given table, falling back on the provided
 * locale. This method searches the main bundle before falling back on AirshipResources, allowing for developers
 * to override or supplement any officially bundled localizations.
 *
 * @param table The table.
 * @param fallbackLocale The locale to use in case a localized string for the current locale cannot be found.
 * @return YES if a localized string corresponding to the key and table was found, or NO if it cannot be found.
 */
- (BOOL)localizedStringExistsInTable:(NSString *)table fallbackLocale:(NSString *)fallbackLocale;

@end
