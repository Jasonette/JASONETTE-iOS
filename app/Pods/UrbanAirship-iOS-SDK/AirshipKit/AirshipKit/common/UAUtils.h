/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SystemConfiguration/SCNetworkReachability.h>

NS_ASSUME_NONNULL_BEGIN

@class UAHTTPRequest;
@class UARequest;

#define kUAConnectionTypeNone @"none"
#define kUAConnectionTypeCell @"cell"
#define kUAConnectionTypeWifi @"wifi"

/**
 * The UAUtils object provides an interface for utility methods.
 */
@interface UAUtils : NSObject

///---------------------------------------------------------------------------------------
/// @name Device ID Utils
///---------------------------------------------------------------------------------------

/**
 * Get the device model name. e.g., iPhone3,1
 * @return The device model name.
 */
+ (NSString *)deviceModelName;

/**
 * Gets the Urban Airship Device ID.
 *
 * @return The device ID, or an empty string if the ID cannot be retrieved or created.
 */
+ (NSString *)deviceID;

///---------------------------------------------------------------------------------------
/// @name UAHTTP Authenticated Request Helpers
///---------------------------------------------------------------------------------------

+ (void)logFailedRequest:(UARequest *)request
             withMessage:(NSString *)message
               withError:(nullable NSError *)error
            withResponse:(nullable NSHTTPURLResponse *)response;


#if !TARGET_OS_TV   // Inbox not supported on tvOS
/**
 * Returns a basic auth header string.
 *
 * The return value takes the form of: `Basic [Base64 Encoded "username:password"]`
 *
 * @return An HTTP Basic Auth header string value for the user's credentials.
 */
+ (NSString *)userAuthHeaderString;
#endif


/**
 * Returns a basic auth header string.
 *
 * The return value takes the form of: `Basic [Base64 Encoded "username:password"]`
 *
 * @return An HTTP Basic Auth header string value for the app's credentials.
 */
+ (NSString *)appAuthHeaderString;

///---------------------------------------------------------------------------------------
/// @name UI Formatting Helpers
///---------------------------------------------------------------------------------------

+ (NSString *)pluralize:(int)count
           singularForm:(NSString*)singular
             pluralForm:(NSString*)plural;

+ (NSString *)getReadableFileSizeFromBytes:(double)bytes;

///---------------------------------------------------------------------------------------
/// @name Date Formatting
///---------------------------------------------------------------------------------------

/**
 * Creates an ISO dateFormatter (UTC) with the following attributes:
 * locale set to 'en_US_POSIX', timestyle set to 'NSDateFormatterFullStyle',
 * date format set to 'yyyy-MM-dd HH:mm:ss'.
 *
 * @return A DateFormatter with the default attributes.
 */
+ (NSDateFormatter *)ISODateFormatterUTC;

/**
 * Creates an ISO dateFormatter (UTC) with the following attributes:
 * locale set to 'en_US_POSIX', timestyle set to 'NSDateFormatterFullStyle',
 * date format set to 'yyyy-MM-dd'T'HH:mm:ss'. The formatter returned by this method
 * is identical to that of `ISODateFormatterUTC`, except that the format matches the optional
 * `T` delimiter between date and time.
 *
 * @return A DateFormatter with the default attributes, matching the optional `T` delimiter.
 */
+ (NSDateFormatter *)ISODateFormatterUTCWithDelimiter;

/**
 * Parses ISO 8601 date strings. Supports timestamps with just year all
 * the way up to seconds with and without the optional `T` delimeter.
 * @param timestamp The ISO 8601 timestamp.
 * @return A parsed NSDate object, or nil if the timestamp is not a valid format.
 */
+ (nullable NSDate *)parseISO8601DateFromString:(NSString *)timestamp;


///---------------------------------------------------------------------------------------
/// @name File management
///---------------------------------------------------------------------------------------

/**
 * Sets a file or directory at a url to not backup in
 * iCloud or iTunes
 * @param url The items url
 * @return YES if successful, NO otherwise
 */
+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)url;

/**
 * Returns the main window for the app. This window will
 * be positioned underneath any other windows added and removed at runtime, by
 * classes such a UIAlertView or UIActionSheet.
 *
 * @return The main window, or `nil` if the window cannot be found.
 */
+ (nullable UIWindow *)mainWindow;

/**
 * A utility method that grabs the top-most view controller for the main application window.
 * May return nil if a suitable view controller cannot be found.
 * @return The top-most view controller or `nil` if controller cannot be found.
 */
+ (nullable UIViewController *)topController;

/**
 * Gets the current connection type.
 * Possible values are "cell", "wifi", or "none".
 * @return The current connection type as a string.
 */
+ (NSString *)connectionType;

///---------------------------------------------------------------------------------------
/// @name Notification payload
///---------------------------------------------------------------------------------------

/**
 * Determine if the notification payload is a silent push (no notification elements).
 * @param notification The notification payload
 * @return `YES` if it is a silent push, `NO` otherwise
 */
+ (BOOL)isSilentPush:(NSDictionary *)notification;

/**
 * Determine if the notification payload is an alerting push.
 * @param notification The notification payload
 * @return `YES` if it is an alerting push, `NO` otherwise
 */
+ (BOOL)isAlertingPush:(NSDictionary *)notification;

///---------------------------------------------------------------------------------------
/// @name Fetch Results
///---------------------------------------------------------------------------------------

/**
 * A utility method that takes an array of fetch results as NSNumbers and returns the merged result
 */
+ (UIBackgroundFetchResult)mergeFetchResults:(NSArray *)fetchResults;

///---------------------------------------------------------------------------------------
/// @name Device Tokens
///---------------------------------------------------------------------------------------

/**
 * A utility method that takes an APNS-provided device token and returns the decoded UA device token
 */
+ (NSString *)deviceTokenStringFromDeviceToken:(NSData *)deviceToken;

@end

NS_ASSUME_NONNULL_END
