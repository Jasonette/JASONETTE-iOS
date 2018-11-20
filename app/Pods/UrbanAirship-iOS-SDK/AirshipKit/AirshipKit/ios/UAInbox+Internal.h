/* Copyright 2017 Urban Airship and Contributors */

#import "UAInbox.h"

@class UAUser;
@class UAConfig;
@class UAPreferenceDataStore;

NS_ASSUME_NONNULL_BEGIN

/*
 * SDK-private extensions to UAInbox
 */
@interface UAInbox ()

///---------------------------------------------------------------------------------------
/// @name Inbox Internal Properties
///---------------------------------------------------------------------------------------

/**
 * The inbox API client.
 */
@property (nonatomic, strong) UAInboxAPIClient *client;

/**
 * The inbox user.
 */
@property (nonatomic, strong) UAUser *user;

///---------------------------------------------------------------------------------------
/// @name Inbox Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Factory method to create an inbox.
 * @param user The inbox user.
 * @param config The Urban Airship config.
 * @param dataStore The preference data store.
 * @return The user's inbox.
 */
+ (instancetype)inboxWithUser:(UAUser *)user
                       config:(UAConfig *)config
                    dataStore:(UAPreferenceDataStore *)dataStore;

@end

NS_ASSUME_NONNULL_END
