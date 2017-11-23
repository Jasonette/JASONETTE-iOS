//
//  VALSecureEnclaveValet.h
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

#import <Valet/VALValet.h>


/// Compiler flag for building against an SDK where Secure Enclave is available.
#define VAL_SECURE_ENCLAVE_SDK_AVAILABLE ((TARGET_OS_IPHONE && __IPHONE_8_0) || (TARGET_OS_MAC && __MAC_10_11))


typedef NS_ENUM(NSUInteger, VALAccessControl) {
    /// Access to keychain elements requires user presence verification via Touch ID or device Passcode. Keychain elements are still accessible by Touch ID even if fingers are added or removed. Touch ID does not have to be available or enrolled.
    /// @version Available on iOS 8 or later, and macOS 10.11 or later.
    VALAccessControlUserPresence = 1,
    
    /// Access to keychain elements requires user presence verification via any finger enrolled in Touch ID. Keychain elements are still accessible by Touch ID even if fingers are added or removed. Touch ID must be available and at least one finger must be enrolled.
    /// @version Available on iOS 9 or later, and macOS 10.12 or later.
    VALAccessControlTouchIDAnyFingerprint = 2,
    
    /// Access to keychain elements requires user presence verification via fingers currently enrolled in Touch ID. Previously written keychain elements become inaccessible when fingers are added or removed. Touch ID must be available and at least one finger must be enrolled.
    /// @version Available on iOS 9 or later, and macOS 10.12 or later.
    VALAccessControlTouchIDCurrentFingerprintSet = 3,
    
    /// Access to keychain elements requires user presence verification via device Passcode.
    /// @version Available on iOS 9 or later, and macOS 10.11 or later.
    VALAccessControlDevicePasscode = 4,
};


/// Reads and writes keychain elements that are stored on the Secure Enclave (available on iOS 8.0 and later and macOS 10.11 and later) using accessibility attribute VALAccessibilityWhenPasscodeSetThisDeviceOnly. Accessing these keychain elements will require the user to confirm their presence via Touch ID or passcode entry. If no passcode is set on the device, the below methods will fail. Data is removed from the Secure Enclave when the user removes a passcode from the device. Use the userPrompt methods to display custom text to the user in Apple's Touch ID and passcode entry UI.
/// @version Available on iOS 8 or later, and macOS 10.11 or later.
@interface VALSecureEnclaveValet : VALValet

/// @return YES if Secure Enclave storage is supported on the current iOS or macOS version (iOS 8.0 and macOS 10.11 and later).
+ (BOOL)supportsSecureEnclaveKeychainItems;

/// Creates a Valet that reads/writes Secure Enclave keychain elements and the specified access control.
/// @see VALAccessControl
- (nullable instancetype)initWithIdentifier:(nonnull NSString *)identifier accessControl:(VALAccessControl)accessControl;

/// Creates a Valet that reads/writes Secure Enclave keychain elements that can be shared across applications written by the same development team.
/// @param sharedAccessGroupIdentifier This must correspond with the value for keychain-access-groups in your Entitlements file.
/// @see VALAccessControl
- (nullable instancetype)initWithSharedAccessGroupIdentifier:(nonnull NSString *)sharedAccessGroupIdentifier accessControl:(VALAccessControl)accessControl;

@property (readonly) VALAccessControl accessControl;

/// Convenience method for retrieving data from the keychain with a user prompt.
/// @see -[VALSecureEnclave objectForKey:userPrompt:userCancelled:]
- (nullable NSData *)objectForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt;

/// Convenience method for retrieving data from the keychain with a user prompt.
/// @param userPrompt The prompt displayed to the user in Apple's Touch ID and passcode entry UI.
/// @param userCancelled A pointer to a BOOL which will be set to YES if the user cancels out of Touch ID or entering the device Passcode.
/// @return The object currently stored in the keychain for the provided key. Returns nil if no object exists in the keychain for the specified key, if the keychain is inaccessible, or if the user cancels out of the authentication UI.
- (nullable NSData *)objectForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt userCancelled:(nullable inout BOOL *)userCancelled;

/// Convenience method for retrieving a string from the keychain with a user prompt.
/// @see -[VALSecureEnclave stringForKey:userPrompt:userCancelled:]
- (nullable NSString *)stringForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt;

/// Convenience method for retrieving a string from the keychain with a user prompt.
/// @param userPrompt The prompt displayed to the user in Apple's Touch ID and passcode entry UI.
/// @param userCancelled A pointer to a BOOL which will be set to YES if the user cancels out of Touch ID or entering the device Passcode.
/// @return The string currently stored in the keychain for the provided key. Returns nil if no string exists in the keychain for the specified key, if the keychain is inaccessible, or if the user cancels out of the authentication UI.
- (nullable NSString *)stringForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt userCancelled:(nullable inout BOOL *)userCancelled;

/// This method is not supported on VALSecureEnclaveValet.
- (nonnull NSSet *)allKeys NS_UNAVAILABLE;

/// This method is not supported on VALSecureEnclaveValet.
- (BOOL)removeAllObjects NS_UNAVAILABLE;

@end


@interface VALSecureEnclaveValet (Deprecated)

- (nullable instancetype)initWithIdentifier:(nonnull NSString *)identifier __attribute__((deprecated("Use backwards-compatible initWithIdentifier:accessControl: with VALAccessControlUserPresence instead")));
- (nullable instancetype)initWithIdentifier:(nonnull NSString *)identifier accessibility:(VALAccessibility)accessibility __attribute__((deprecated("Use backwards-compatible initWithIdentifier:accessControl: with VALAccessControlUserPresence instead")));

- (nullable instancetype)initWithSharedAccessGroupIdentifier:(nonnull NSString *)sharedAccessGroupIdentifier __attribute__((deprecated("Use backwards-compatible initWithIdentifier:accessControl: with VALAccessControlUserPresence instead")));
- (nullable instancetype)initWithSharedAccessGroupIdentifier:(nonnull NSString *)sharedAccessGroupIdentifier accessibility:(VALAccessibility)accessibility __attribute__((deprecated("Use backwards-compatible initWithIdentifier:accessControl: with VALAccessControlUserPresence instead")));

@end
