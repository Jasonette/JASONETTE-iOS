//
//  VALSecureEnclaveValet.m
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

#import "VALSecureEnclaveValet.h"
#import "VALSecureEnclaveValet_Protected.h"
#import "VALValet_Protected.h"

#import "ValetDefines.h"


/// Compiler flag for building against an SDK where VALAccessControlTouchIDAnyFingerprint and VALAccessControlTouchIDCurrentFingerprintSet are available.
#define VAL_ACCESS_CONTROL_TOUCH_ID_SDK_AVAILABLE ((TARGET_OS_IPHONE && __IPHONE_9_0) || (TARGET_OS_MAC && __MAC_10_12))

/// Compiler flag for building against an SDK where VALAccessControlDevicePasscode is available.
#define VAL_ACCESS_CONTROL_DEVICE_PASSCODE_SDK_AVAILABLE ((TARGET_OS_IPHONE && __IPHONE_9_0) || (TARGET_OS_MAC && __MAC_10_11))


NSString *__nonnull VALStringForAccessControl(VALAccessControl accessControl)
{
    switch (accessControl) {
        case VALAccessControlUserPresence:
            return @"AccessControlUserPresence";
            
        case VALAccessControlTouchIDAnyFingerprint:
            return @"AccessControlTouchIDAnyFingerprint";
            
        case VALAccessControlTouchIDCurrentFingerprintSet:
            return @"AccessControlTouchIDCurrentFingerprintSet";
            
        case VALAccessControlDevicePasscode:
            return @"AccessControlDevicePasscode";
    }
    
    return @"AccessControlInvalid";
}

#if VAL_SECURE_ENCLAVE_SDK_AVAILABLE

@implementation VALSecureEnclaveValet

@synthesize baseQuery = _baseQuery;

#pragma mark - Class Methods

+ (BOOL)supportsSecureEnclaveKeychainItems;
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-compare"
    return (&kSecAttrAccessControl != NULL && &kSecUseOperationPrompt != NULL);
#pragma clang diagnostic pop
}

#pragma mark - Private Class Methods

+ (BOOL)_macOSElCapitanOrLater;
{
#if TARGET_OS_MAC && __MAC_10_11
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-compare"
    return (&kSecUseAuthenticationUI != NULL);
#pragma clang diagnostic pop
#else
    return NO;
#endif
}

+ (BOOL)_macOSSierraOrLater;
{
#if TARGET_OS_MAC && __MAC_10_12
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-compare"
    return (&kSecAttrTokenIDSecureEnclave != NULL);
#pragma clang diagnostic pop
#else
    return NO;
#endif
}

+ (BOOL)_iOS8OrLater;
{
#if TARGET_OS_IPHONE
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-compare"
    return (&kSecUseOperationPrompt != NULL);
#pragma clang diagnostic pop
#else
    return NO;
#endif
}

+ (BOOL)_iOS9OrLater;
{
#if TARGET_OS_IPHONE && __IPHONE_9_0
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-compare"
    return (&kSecUseAuthenticationUI != NULL);
#pragma clang diagnostic pop
#else
    return NO;
#endif
}

+ (BOOL)_currentOSSupportedForAccessControl:(VALAccessControl)accessControl;
{
    switch (accessControl) {
        case VALAccessControlUserPresence:
            return ([self _iOS8OrLater] || [self _macOSElCapitanOrLater]);
            
        case VALAccessControlTouchIDAnyFingerprint:
        case VALAccessControlTouchIDCurrentFingerprintSet:
            return [self _iOS9OrLater] || [self _macOSSierraOrLater];
            
        case VALAccessControlDevicePasscode:
            return ([self _iOS9OrLater] || [self _macOSElCapitanOrLater]);
    }
    
    return NO;
}

+ (void)_augmentBaseQuery:(nonnull NSMutableDictionary *)mutableBaseQuery accessControl:(VALAccessControl)accessControl;
{
    // Add the access control, which opts us in to Secure Element storage.
    [mutableBaseQuery addEntriesFromDictionary:@{ (__bridge id)kSecAttrAccessControl : (__bridge_transfer id)SecAccessControlCreateWithFlags(NULL, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, ({
        SecAccessControlCreateFlags accessControlFlag = 0;
        
        switch (accessControl) {
            case VALAccessControlUserPresence:
                accessControlFlag = kSecAccessControlUserPresence;
                break;
                
#if VAL_ACCESS_CONTROL_TOUCH_ID_SDK_AVAILABLE
            case VALAccessControlTouchIDAnyFingerprint:
                accessControlFlag = kSecAccessControlTouchIDAny;
                break;
            case VALAccessControlTouchIDCurrentFingerprintSet:
                accessControlFlag = kSecAccessControlTouchIDCurrentSet;
                break;
#else
            case VALAccessControlTouchIDAnyFingerprint:
            case VALAccessControlTouchIDCurrentFingerprintSet:
                // This SDK does not support these access controls. But on this SDK we'll never reach this line, so just fake it.
                break;
#endif
                
#if VAL_ACCESS_CONTROL_DEVICE_PASSCODE_SDK_AVAILABLE
            case VALAccessControlDevicePasscode:
                accessControlFlag = kSecAccessControlDevicePasscode;
                break;
#else
            case VALAccessControlDevicePasscode:
                // This SDK does not support these access controls. But on this SDK we'll never reach this line, so just fake it.
                break;
#endif
        }
        
        accessControlFlag;
    }), NULL) }];
    
    // kSecAttrAccessControl and kSecAttrAccessible are mutually exclusive, so remove kSecAttrAccessible from our query.
    [mutableBaseQuery removeObjectForKey:(__bridge id)kSecAttrAccessible];
    
    NSString *const service = mutableBaseQuery[(__bridge id)kSecAttrService];
    NSString *const accessControlServiceSuffix = ({
        NSString *accessControlServiceSuffix = @"";
        
        switch (accessControl) {
            case VALAccessControlUserPresence:
                /*
                 VALSecureEnclaveValet v1.0-v2.0.7 used UserPresence without a suffix – the concept of a customizable AccessControl was added in v2.1.
                 For backwards compatibility, do not append an access control suffix for UserPresence.
                 */
                break;
                
            case VALAccessControlTouchIDAnyFingerprint:
            case VALAccessControlTouchIDCurrentFingerprintSet:
            case VALAccessControlDevicePasscode:
                accessControlServiceSuffix = [@"_" stringByAppendingString:VALStringForAccessControl(accessControl)];
                break;
        }
        
        accessControlServiceSuffix;
    });
    
    if (service.length > 0 && accessControlServiceSuffix.length > 0) {
        // Ensure that our service identifier includes our access control suffix.
        mutableBaseQuery[(__bridge id)kSecAttrService] = [service stringByAppendingString:accessControlServiceSuffix];
    }
}

#pragma mark - Initialization

- (nullable instancetype)initWithIdentifier:(nonnull NSString *)identifier accessControl:(VALAccessControl)accessControl;
{
    VALCheckCondition([[self class] supportsSecureEnclaveKeychainItems], nil, @"This device does not support storing data on the secure enclave.");
    VALCheckCondition([[self class] _currentOSSupportedForAccessControl:accessControl], nil, @"This device does not support %@", VALStringForAccessControl(accessControl));
    
    VALAccessibility const accessibility = VALAccessibilityWhenPasscodeSetThisDeviceOnly;
    self = [super initWithIdentifier:identifier accessibility:accessibility];

    SEL const backwardsCompatibleInitializer = @selector(initWithIdentifier:accessibility:);
    NSMutableDictionary *const baseQuery = [[self class] mutableBaseQueryWithIdentifier:identifier
                                                                          accessibility:accessibility
                                                                            initializer:backwardsCompatibleInitializer];
    [[self class] _augmentBaseQuery:baseQuery
                      accessControl:accessControl];
    _baseQuery = baseQuery;
    _accessControl = accessControl;
    
    return [[self class] sharedValetForValet:self];
}

- (nullable instancetype)initWithSharedAccessGroupIdentifier:(nonnull NSString *)sharedAccessGroupIdentifier accessControl:(VALAccessControl)accessControl
{
    VALCheckCondition([[self class] supportsSecureEnclaveKeychainItems], nil, @"This device does not support storing data on the secure enclave.");
    VALCheckCondition([[self class] _currentOSSupportedForAccessControl:accessControl], nil, @"This device does not support %@", VALStringForAccessControl(accessControl));
    
    VALAccessibility const accessibility = VALAccessibilityWhenPasscodeSetThisDeviceOnly;
    self = [super initWithSharedAccessGroupIdentifier:sharedAccessGroupIdentifier accessibility:accessibility];

    SEL const backwardsCompatibleInitializer = @selector(initWithSharedAccessGroupIdentifier:accessibility:);
    NSMutableDictionary *const baseQuery = [[self class] mutableBaseQueryWithSharedAccessGroupIdentifier:sharedAccessGroupIdentifier
                                                                                           accessibility:accessibility
                                                                                             initializer:backwardsCompatibleInitializer];
    [[self class] _augmentBaseQuery:baseQuery
                      accessControl:accessControl];
    _baseQuery = baseQuery;
    _accessControl = accessControl;
    
    return [[self class] sharedValetForValet:self];
}

#pragma mark - VALValet

- (BOOL)canAccessKeychain;
{
    // To avoid prompting the user for Touch ID or passcode, create a VALValet with our identifier and accessibility and ask it if it can access the keychain.
    VALValet *noPromptValet = nil;
    if ([self isSharedAcrossApplications]) {
        noPromptValet = [[VALValet alloc] initWithSharedAccessGroupIdentifier:self.identifier accessibility:self.accessibility];
    } else {
        noPromptValet = [[VALValet alloc] initWithIdentifier:self.identifier accessibility:self.accessibility];
    }
    
    return [noPromptValet canAccessKeychain];
}

- (BOOL)containsObjectForKey:(nonnull NSString *)key;
{
    OSStatus const status = [self containsObjectForKey:key options:nil];
    BOOL const keyAlreadyInKeychain = (status == errSecInteractionNotAllowed || status == errSecSuccess);
    return keyAlreadyInKeychain;
}

- (nonnull NSSet *)allKeys;
{
    VALCheckCondition(NO, [NSSet new], @"%s is not supported on %@", __PRETTY_FUNCTION__, NSStringFromClass([self class]));
}

- (BOOL)removeAllObjects;
{
    VALCheckCondition(NO, NO, @"%s is not supported on %@", __PRETTY_FUNCTION__, NSStringFromClass([self class]));
}

- (nullable NSError *)migrateObjectsMatchingQuery:(nonnull NSDictionary *)secItemQuery removeOnCompletion:(BOOL)remove;
{
    if ([[self class] supportsSecureEnclaveKeychainItems]) {
        VALCheckCondition(secItemQuery[(__bridge id)kSecUseOperationPrompt] == nil, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorInvalidQuery userInfo:nil], @"kSecUseOperationPrompt is not supported in a migration query. Keychain items can not be migrated en masse from the Secure Enclave.");
    }
    
    return [super migrateObjectsMatchingQuery:secItemQuery removeOnCompletion:remove];
}

#pragma mark - Public Methods

- (nullable NSData *)objectForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt;
{
    return [self objectForKey:key userPrompt:userPrompt userCancelled:NULL];
}

- (nullable NSData *)objectForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt userCancelled:(nullable inout BOOL *)userCancelled;
{
    return [self objectForKey:key userPrompt:userPrompt userCancelled:userCancelled options:nil];
}

- (nullable NSString *)stringForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt;
{
    return [self stringForKey:key userPrompt:userPrompt userCancelled:NULL];
}

- (nullable NSString *)stringForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt userCancelled:(nullable inout BOOL *)userCancelled;
{
    return [self stringForKey:key userPrompt:userPrompt userCancelled:userCancelled options:nil];
}

#pragma mark - VALValet Protected Methods

- (BOOL)setObject:(nonnull NSData *)value forKey:(nonnull NSString *)key options:(nullable NSDictionary *)options;
{
    // Remove the key before trying to set it. This will prevent us from calling SecItemUpdate on an item stored on the Secure Enclave, which would cause iOS to prompt the user for authentication.
    [self removeObjectForKey:key];
    
    return [super setObject:value forKey:key options:options];
}

- (OSStatus)containsObjectForKey:(nonnull NSString *)key options:(nullable NSDictionary *)options;
{
    NSDictionary *baseOptions = nil;
    
    // iOS 9 and macOS 10.11 use kSecUseAuthenticationUI, not kSecUseNoAuthenticationUI.
#if ((TARGET_OS_IPHONE && __IPHONE_9_0) || (TARGET_OS_MAC && __MAC_10_11))
    if ([[self class] _iOS9OrLater] || [[self class] _macOSElCapitanOrLater]) {
        baseOptions = @{ (__bridge id)kSecUseAuthenticationUI : (__bridge id)kSecUseAuthenticationUIFail };
    } else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        // kSecUseNoAuthenticationUI is deprecated in the iOS 9 SDK, but we still need it on iOS 8.
#if (TARGET_OS_IPHONE && __IPHONE_9_0)
        options = @{ (__bridge id)kSecUseNoAuthenticationUI : @YES };
#endif
#pragma GCC diagnostic pop
    }
#else
    options = @{ (__bridge id)kSecUseNoAuthenticationUI : @YES };
#endif
    
    NSMutableDictionary *const allOptions = [baseOptions mutableCopy];
    [allOptions addEntriesFromDictionary:options];
    return [super containsObjectForKey:key options:allOptions];
}

#pragma mark - VALSecureEnclaveValet Protected Methods

- (nullable NSData *)objectForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt userCancelled:(nullable inout BOOL *)userCancelled options:(nullable NSDictionary *)options;
{
    OSStatus status = errSecSuccess;
    
    NSMutableDictionary *const allOptions = [[self _optionsDictionaryForUserPrompt:userPrompt] mutableCopy];
    if (options.count > 0) {
        [allOptions addEntriesFromDictionary:options];
    }
    
    NSData *const objectForKey = [self objectForKey:key options:allOptions status:&status];
    if (userCancelled != NULL) {
        *userCancelled = (status == errSecUserCanceled || status == errSecAuthFailed);
    }
    
    return objectForKey;
}

- (nullable NSString *)stringForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt userCancelled:(nullable inout BOOL *)userCancelled options:(nullable NSDictionary *)options;
{
    OSStatus status = errSecSuccess;
    
    NSMutableDictionary *const allOptions = [[self _optionsDictionaryForUserPrompt:userPrompt] mutableCopy];
    if (options.count > 0) {
        [allOptions addEntriesFromDictionary:options];
    }
    
    NSString *const stringForKey = [self stringForKey:key options:allOptions status:&status];
    if (userCancelled != NULL) {
        *userCancelled = (status == errSecUserCanceled || status == errSecAuthFailed);
    }
    
    return stringForKey;
}

#pragma mark - Private Methods

- (nullable NSDictionary *)_optionsDictionaryForUserPrompt:(nullable NSString *)userPrompt;
{
    if (userPrompt.length == 0) {
        return nil;
        
    } else {
        return @{ (__bridge id)kSecUseOperationPrompt : userPrompt };
    }
}

@end


#pragma mark - Deprecated Category


@implementation VALSecureEnclaveValet (Deprecated)

#pragma mark - Deprecated Initializers

- (nullable instancetype)initWithIdentifier:(nonnull NSString *)identifier;
{
    return [self initWithIdentifier:identifier accessibility:VALAccessibilityWhenPasscodeSetThisDeviceOnly];
}

- (nullable instancetype)initWithIdentifier:(nonnull NSString *)identifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(accessibility == VALAccessibilityWhenPasscodeSetThisDeviceOnly, nil, @"Accessibility on SecureEnclaveValet must be VALAccessibilityWhenPasscodeSetThisDeviceOnly");
    
    return [self initWithIdentifier:identifier accessControl:VALAccessControlUserPresence];
}

- (nullable instancetype)initWithSharedAccessGroupIdentifier:(nonnull NSString *)sharedAccessGroupIdentifier;
{
    return [self initWithSharedAccessGroupIdentifier:sharedAccessGroupIdentifier accessibility:VALAccessibilityWhenPasscodeSetThisDeviceOnly];
}

- (nullable instancetype)initWithSharedAccessGroupIdentifier:(nonnull NSString *)sharedAccessGroupIdentifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(accessibility == VALAccessibilityWhenPasscodeSetThisDeviceOnly, nil, @"Accessibility on SecureEnclaveValet must be VALAccessibilityWhenPasscodeSetThisDeviceOnly");
    
    return [self initWithSharedAccessGroupIdentifier:sharedAccessGroupIdentifier accessControl:VALAccessControlUserPresence];
}

@end

#else // Below this line we're in !VAL_SECURE_ENCLAVE_SDK_AVAILABLE, meaning none of our API is actually usable. Return NO or nil everywhere.

@implementation VALSecureEnclaveValet

+ (BOOL)supportsSecureEnclaveKeychainItems;
{
    VALCheckCondition(NO, NO, @"VALSecureEnclaveValet unsupported on this SDK");
}

- (nullable instancetype)initWithIdentifier:(nonnull NSString *)identifier accessControl:(VALAccessControl)accessControl;
{
    VALCheckCondition(NO, nil, @"VALSecureEnclaveValet unsupported on this SDK");
}

- (nullable instancetype)initWithSharedAccessGroupIdentifier:(nonnull NSString *)sharedAccessGroupIdentifier accessControl:(VALAccessControl)accessControl;
{
    VALCheckCondition(NO, nil, @"VALSecureEnclaveValet unsupported on this SDK");
}

- (nullable NSData *)objectForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt;
{
    VALCheckCondition(NO, nil, @"VALSecureEnclaveValet unsupported on this SDK");
}

- (nullable NSData *)objectForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt userCancelled:(nullable inout BOOL *)userCancelled;
{
    VALCheckCondition(NO, nil, @"VALSecureEnclaveValet unsupported on this SDK");
}

- (nullable NSString *)stringForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt;
{
    VALCheckCondition(NO, nil, @"VALSecureEnclaveValet unsupported on this SDK");
}

- (nullable NSString *)stringForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt userCancelled:(nullable inout BOOL *)userCancelled;
{
    VALCheckCondition(NO, nil, @"VALSecureEnclaveValet unsupported on this SDK");
}

- (nullable NSData *)objectForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt userCancelled:(nullable inout BOOL *)userCancelled options:(nullable NSDictionary *)options;
{
    VALCheckCondition(NO, nil, @"VALSecureEnclaveValet unsupported on this SDK");
}

- (nullable NSString *)stringForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt userCancelled:(nullable inout BOOL *)userCancelled options:(nullable NSDictionary *)options;
{
    VALCheckCondition(NO, nil, @"VALSecureEnclaveValet unsupported on this SDK");
}

@end


@implementation VALSecureEnclaveValet (Deprecated)

- (nullable instancetype)initWithIdentifier:(nonnull NSString *)identifier;
{
    VALCheckCondition(NO, nil, @"VALSecureEnclaveValet unsupported on this SDK");
}

- (nullable instancetype)initWithIdentifier:(nonnull NSString *)identifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(NO, nil, @"VALSecureEnclaveValet unsupported on this SDK");
}

- (nullable instancetype)initWithSharedAccessGroupIdentifier:(nonnull NSString *)sharedAccessGroupIdentifier;
{
    VALCheckCondition(NO, nil, @"VALSecureEnclaveValet unsupported on this SDK");
}

- (nullable instancetype)initWithSharedAccessGroupIdentifier:(nonnull NSString *)sharedAccessGroupIdentifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(NO, nil, @"VALSecureEnclaveValet unsupported on this SDK");
}

@end


#endif // VAL_SECURE_ENCLAVE_SDK_AVAILABLE
