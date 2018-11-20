/* Copyright 2017 Urban Airship and Contributors */

#import "UAUser.h"

// Current dictionary keys
#define kUserUrlKey @"UAUserUrlKey"

@class UAUserAPIClient;
@class UAConfig;
@class UAPreferenceDataStore;
@class UAPush;

NS_ASSUME_NONNULL_BEGIN

/*
 * SDK-private extensions to UAUser
 */
@interface UAUser()

///---------------------------------------------------------------------------------------
/// @name User Internal Properties
///---------------------------------------------------------------------------------------

/**
 * The user api client
 */
@property (nonatomic, strong) UAUserAPIClient *apiClient;

/**
 * The user name.
 */
@property (nonatomic, copy, nullable) NSString *username;

/**
 * The user's password.
 */
@property (nonatomic, copy, nullable) NSString *password;

/**
 * The user's url.
 */
@property (nonatomic, copy, nullable) NSString *url;


/**
 * Flag indicating if the  user is being created
 */
@property (nonatomic, assign) BOOL creatingUser;

/**
 * The preference data store
 */
@property (nonatomic, strong) UAPreferenceDataStore *dataStore;

/**
 * The Urban Airship config
 */
@property (nonatomic, strong) UAConfig *config;

///---------------------------------------------------------------------------------------
/// @name User Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Factory method to create a user instance.
 * @param push The push manager.
 * @param config The Urban Airship config.
 * @param dataStore The preference data store.
 * @return User instance.
 */
+ (instancetype)userWithPush:(UAPush *)push config:(UAConfig *)config dataStore:(UAPreferenceDataStore *)dataStore;

/**
 * Updates the user's device token and or channel ID
 */
- (void)updateUser;

/**
 * Creates a user
 */
- (void)createUser;

@end

NS_ASSUME_NONNULL_END

