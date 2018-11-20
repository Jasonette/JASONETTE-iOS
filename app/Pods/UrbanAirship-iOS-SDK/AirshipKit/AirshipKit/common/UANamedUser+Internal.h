/* Copyright 2017 Urban Airship and Contributors */

#import "UANamedUser.h"

@class UANamedUserAPIClient;
@class UAConfig;
@class UATagGroupsAPIClient;
@class UAPush;

NS_ASSUME_NONNULL_BEGIN

/*
 * SDK-private extensions to UANamedUser
 */
@interface UANamedUser ()

///---------------------------------------------------------------------------------------
/// @name Named User Internal Properties
///---------------------------------------------------------------------------------------

/**
 * Named user identifier data store key.
 */
extern NSString *const UANamedUserIDKey;

/**
 * Named user change token data store key.
 */
extern NSString *const UANamedUserChangeTokenKey;

/**
 * Named user last updated token data store key.
 */
extern NSString *const UANamedUserLastUpdatedTokenKey;

/**
 * Add named user tags data store key.
 */
extern NSString *const UANamedUserAddTagGroupsSettingsKey;

/**
 * Remove named user tags data store key.
 */
extern NSString *const UANamedUserRemoveTagGroupsSettingsKey;

/**
 * The change token tracks the start of setting the named user ID.
 */
@property (nonatomic, copy, nullable) NSString *changeToken;

/**
 * The last updated token tracks when the named user ID was set successfully.
 */
@property (nonatomic, copy, nullable) NSString *lastUpdatedToken;

/**
 * The named user API client.
 */
@property (nonatomic, strong) UANamedUserAPIClient *namedUserAPIClient;

/**
 * The data store to save and load named user info.
 */
@property (nonatomic, strong) UAPreferenceDataStore *dataStore;

/**
 * The push instance.
 */
@property (nonatomic, strong) UAPush *push;

/**
 * The airship config.
 */
@property (nonatomic, strong) UAConfig *config;

/**
 * The tag groups API client.
 */
@property (nonatomic, strong) UATagGroupsAPIClient *tagGroupsAPIClient;

///---------------------------------------------------------------------------------------
/// @name Named User Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Factory method to create a named user.
 * @parm push The UAPush instance.
 * @param config The Urban Airship config.
 * @param dataStore The shared preference data store.
 * @return A named user instance.
 */
+ (instancetype)namedUserWithPush:(UAPush *)push
                           config:(UAConfig *)config
                        dataStore:(UAPreferenceDataStore *)dataStore;

/**
 * Updates the association or disassociation of the current named user ID.
 */
- (void)update;

/**
 * Disassociate the named user only if the named user ID is really nil.
 */
- (void)disassociateNamedUserIfNil;

@end

NS_ASSUME_NONNULL_END
