/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

#define kUAKeychainDeviceIDKey @"com.urbanairship.deviceID"

NS_ASSUME_NONNULL_BEGIN

/**
 * The UAKeychainUtils object provides an interface for keychain related methods.
 */
@interface UAKeychainUtils : NSObject

///---------------------------------------------------------------------------------------
/// @name Keychain Utils Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Creates a key chain.
 * @param username The username for the key chain.
 * @param password The password for the key chain.
 * @param identifier The identifier for the key chain.
 * @return YES if the key chain was created successfully. NO otherwise.
 */
+ (BOOL)createKeychainValueForUsername:(NSString *)username 
                          withPassword:(NSString *)password 
                         forIdentifier:(NSString *)identifier;

/**
 * Deletes a key chain.
 * @param identifier The identifier to specify the key chain to be deleted.
 */
+ (void)deleteKeychainValue:(NSString *)identifier;

/**
 * Updates a key chain.
 * @param username The username for the key chain.
 * @param password The password for the key chain.
 * @param identifier The identifier for the key chain.
 * @return YES if the key chain was updated successfully. NO otherwise.
 */
+ (BOOL)updateKeychainValueForUsername:(NSString *)username
                          withPassword:(NSString *)password
                         forIdentifier:(NSString *)identifier;

/**
 * Get the key chain's password.
 * @param identifier The identifier for the key chain.
 * @return The password as an NSString or nil if an error occurred.
 */
+ (nullable NSString *)getPassword:(NSString *)identifier;

/**
 * Get the key chain's username.
 * @param identifier The identifier for the key chain.
 * @return The username as an NSString or nil if an error occurred.
 */
+ (nullable NSString *)getUsername:(NSString *)identifier;

/**
 * Gets the device ID, creating or refreshing if necessary. Device IDs will be regenerated if a
 * device change is detected (though UAUser IDs remain the same in that case).
 *
 * @return The Urban Airship device ID or an empty string if an error occurred.
 */
+ (NSString *)getDeviceID;

@end

NS_ASSUME_NONNULL_END
