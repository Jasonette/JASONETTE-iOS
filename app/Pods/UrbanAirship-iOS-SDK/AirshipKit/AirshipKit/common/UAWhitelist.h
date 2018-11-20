/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

@class UAConfig;

NS_ASSUME_NONNULL_BEGIN

/**
 * Class for whitelisting and verifying webview URLs.
 *
 * Whitelist entries are written as URL patterns with optional wildcard matching:
 *
 *     \<scheme\> := '\*' | 'http' | 'https'
 *
 *     \<host\> := '\*' | '\*.'\<any char except '/' and '\*'\> | \<any char except '/' and '\*'\>
 *
 *     \<path\> := '/' \<any chars, including \*\>
 *
 *     \<pattern\> := '\*' | \<scheme\>://\<host\>\<path\> | \<scheme\>://\<host\> | file://\<path\>
 *
 * Wildcards in the scheme pattern will match either http or https schemes.
 * The wildcard in a host pattern "*.mydomain.com" will match anything within the mydomain.com domain.
 * Wildcards in the path pattern will match any characters, including subdirectories.
 *
 * Note that NSURL does not support internationalized domains containing non-ASCII characters.
 * All whitelist entries for internationalized domains must be in ASCII IDNA format as
 * specified in https://tools.ietf.org/html/rfc3490
 */
@interface UAWhitelist : NSObject

///---------------------------------------------------------------------------------------
/// @name Whitelist Creation
///---------------------------------------------------------------------------------------

/**
 * Create a default whitelist with entries specified in a config object.
 * @note The entry "*.urbanairship.com" is added by default.
 * @param config An instance of UAConfig.
 * @return An instance of UAWhitelist
 */
+ (instancetype)whitelistWithConfig:(UAConfig *)config;

///---------------------------------------------------------------------------------------
/// @name Whitelist Core Methods
///---------------------------------------------------------------------------------------

/**
 * Add an entry to the whitelist.
 * @param patternString A whitelist pattern string.
 * @return `YES` if the whitelist pattern was validated and added, `NO` otherwise.
 */
- (BOOL)addEntry:(NSString *)patternString;
/**
 * Determines whether a given URL is whitelisted.
 * @param url The URL under consideration.
 * @return `YES` if the the URL is whitelisted, `NO` otherwise.
 */
- (BOOL)isWhitelisted:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
