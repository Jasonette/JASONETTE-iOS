/* Copyright 2017 Urban Airship and Contributors */

#import "UANotificationCategories.h"

NS_ASSUME_NONNULL_BEGIN

/*
 * SDK-private extensions to UANotificationCategories
 */
@interface UANotificationCategories ()

/**
 * Factory method to create the default set of user notification categories.
 * Background user notification actions will default to requiring authorization.
 * @return A set of user notification categories.
 */
+ (NSSet *)defaultCategories;


/**
 * Factory method to create the default set of user notification categories.
 *
 * @param requireAuth If background actions should default to requiring authorization or not.
 * @return A set of user notification categories.
 */
+ (NSSet *)defaultCategoriesWithRequireAuth:(BOOL)requireAuth;

@end

NS_ASSUME_NONNULL_END
