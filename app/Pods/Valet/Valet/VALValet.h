//
//  VALValet.h
//  Valet
//
//  Created by Dan Federman on 3/16/15.
//  Copyright 2015 Square, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, VALAccessibility) {
    /// Valet data can only be accessed while the device is unlocked. This attribute is recommended for data that only needs to be accessible while the application is in the foreground. Valet data with this attribute will migrate to a new device when using encrypted backups.
    VALAccessibilityWhenUnlocked = 1,
    /// Valet data can only be accessed once the device has been unlocked after a restart. This attribute is recommended for data that needs to be accessible by background applications. Valet data with this attribute will migrate to a new device when using encrypted backups.
    VALAccessibilityAfterFirstUnlock,
    /// Valet data can always be accessed regardless of the lock state of the device. This attribute is not recommended. Valet data with this attribute will migrate to a new device when using encrypted backups.
    VALAccessibilityAlways,
    
    /// Valet data can only be accessed while the device is unlocked. This class is only available if a passcode is set on the device. This is recommended for items that only need to be accessible while the application is in the foreground. Valet data with this attribute will never migrate to a new device, so these items will be missing after a backup is restored to a new device. No items can be stored in this class on devices without a passcode. Disabling the device passcode will cause all items in this class to be deleted.
    VALAccessibilityWhenPasscodeSetThisDeviceOnly NS_ENUM_AVAILABLE(10_10, 8_0),
    /// Valet data can only be accessed while the device is unlocked. This is recommended for data that only needs to be accessible while the application is in the foreground. Valet data with this attribute will never migrate to a new device, so these items will be missing after a backup is restored to a new device.
    VALAccessibilityWhenUnlockedThisDeviceOnly,
    /// Valet data can only be accessed once the device has been unlocked after a restart. This is recommended for items that need to be accessible by background applications. Valet data with this attribute will never migrate to a new device, so these items will be missing after a backup is restored to a new device.
    VALAccessibilityAfterFirstUnlockThisDeviceOnly,
    /// Valet data can always be accessed regardless of the lock state of the device. This option is not recommended. Valet data with this attribute will never migrate to a new device, so these items will be missing after a backup is restored to a new device.
    VALAccessibilityAlwaysThisDeviceOnly,
};

extern NSString * __nonnull const VALMigrationErrorDomain;

typedef NS_ENUM(NSUInteger, VALMigrationError) {
    /// Migration failed because the keychain query was not valid.
    VALMigrationErrorInvalidQuery = 1,
    /// Migration failed because no items to migrate were found.
    VALMigrationErrorNoItemsToMigrateFound,
    /// Migration failed because the keychain could not be read.
    VALMigrationErrorCouldNotReadKeychain,
    /// Migration failed because a key in the query result could not be read.
    VALMigrationErrorKeyInQueryResultInvalid,
    /// Migration failed because some data in the query result could not be read.
    VALMigrationErrorDataInQueryResultInvalid,
    /// Migration failed because two keys with the same value were found in the keychain.
    VALMigrationErrorDuplicateKeyInQueryResult,
    /// Migration failed because a key in the keychain duplicates a key already managed by Valet.
    VALMigrationErrorKeyInQueryResultAlreadyExistsInValet,
    /// Migration failed because writing to the keychain failed.
    VALMigrationErrorCouldNotWriteToKeychain,
    /// Migration failed because removing the migrated data from the keychain failed.
    VALMigrationErrorRemovalFailed,
};


/// Reads and writes keychain elements.
@interface VALValet : NSObject <NSCopying>

/// Creates a Valet that reads/writes keychain elements with the desired accessibility.
/// @see VALAccessibility
- (nullable instancetype)initWithIdentifier:(nonnull NSString *)identifier accessibility:(VALAccessibility)accessibility NS_DESIGNATED_INITIALIZER;

/// Creates a Valet that reads/writes keychain elements that can be shared across applications written by the same development team.
/// @param sharedAccessGroupIdentifier This must correspond with the value for keychain-access-groups in your Entitlements file.
/// @see VALAccessibility
- (nullable instancetype)initWithSharedAccessGroupIdentifier:(nonnull NSString *)sharedAccessGroupIdentifier accessibility:(VALAccessibility)accessibility NS_DESIGNATED_INITIALIZER;

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new NS_UNAVAILABLE;

@property (nonnull, copy, readonly) NSString *identifier;
@property (readonly, getter=isSharedAcrossApplications) BOOL sharedAcrossApplications;
@property (readonly) VALAccessibility accessibility;

/// @return YES if otherValet reads from and writes to the same sandbox within the keychain as the receiver.
- (BOOL)isEqualToValet:(nonnull VALValet *)otherValet;

/// @return YES if the keychain is accessible for reading and writing, NO otherwise.
/// @note Determined by writing a value to the keychain and then reading it back out.
- (BOOL)canAccessKeychain;

/// @param value An NSData value to be inserted into the keychain.
/// @return NO if the keychain is not accessible.
- (BOOL)setObject:(nonnull NSData *)value forKey:(nonnull NSString *)key;
/// @return The data currently stored in the keychain for the provided key. Returns nil if no object exists in the keychain for the specified key, or if the keychain is inaccessible.
- (nullable NSData *)objectForKey:(nonnull NSString *)key;

/// @param string An NSString value to store in the keychain for the provided key.
/// @return NO if the keychain is not accessible.
- (BOOL)setString:(nonnull NSString *)string forKey:(nonnull NSString *)key;
/// @return The string currently stored in the keychain for the provided key. Returns nil if no string exists in the keychain for the specified key, or if the keychain is inaccessible.
- (nullable NSString *)stringForKey:(nonnull NSString *)key;

/// @param key The key to look up in the keychain.
/// @return YES if a value has been set for the given key, NO otherwise.
- (BOOL)containsObjectForKey:(nonnull NSString *)key;
/// @return The set of all (NSString) keys currently stored in this Valet instance.
- (nonnull NSSet *)allKeys;

/// Removes a key/object pair from the keychain.
/// @return NO if the keychain is not accessible.
- (BOOL)removeObjectForKey:(nonnull NSString *)key;
/// Removes all key/object pairs accessible by this Valet instance from the keychain.
/// @return NO if the keychain is not accessible.
- (BOOL)removeAllObjects;

/// Migrates objects matching the secItemQuery into the receiving Valet instance.
/// @return An error if the operation failed. Error domain will be <code>VALMigrationErrorDomain</code>, and codes will be of type <code>VALMigrationError</code>
/// @see VALMigrationError
/// @note The keychain is not modified if a failure occurs.
- (nullable NSError *)migrateObjectsMatchingQuery:(nonnull NSDictionary *)secItemQuery removeOnCompletion:(BOOL)remove;
/// Migrates objects from the passed-in Valet into the receiving Valet instance.
/// @return An error if the operation failed. Error domain will be <code>VALMigrationErrorDomain</code>, and codes will be of type <code>VALMigrationError</code>
/// @see VALMigrationError
- (nullable NSError *)migrateObjectsFromValet:(nonnull VALValet *)valet removeOnCompletion:(BOOL)remove;

@end
