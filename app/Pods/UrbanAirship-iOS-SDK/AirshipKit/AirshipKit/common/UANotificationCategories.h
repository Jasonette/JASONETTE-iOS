/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class UANotificationCategory;

NS_ASSUME_NONNULL_BEGIN

/**
 * Utility methods to create categories from plist files or NSDictionaries.
 */
@interface UANotificationCategories : NSObject

///---------------------------------------------------------------------------------------
/// @name Notification Catagories Factories
///---------------------------------------------------------------------------------------

/**
 * Creates a set of categories from the specified `.plist` file.
 *
 * Categories are defined in a plist dictionary with the category ID
 * followed by an NSArray of user notification action definitions. The
 * action definitions use the same keys as the properties on the action,
 * with the exception of "foreground" mapping to either UIUserNotificationActivationModeForeground
 * or UIUserNotificationActivationModeBackground. The required action definition
 * title can be defined with either the "title" or "title_resource" key, where
 * the latter takes precedence. If "title_resource" does not exist, the action
 * definition title will fall back to the value of "title". If the required action
 * definition title is not defined, the category will not be created.
 *
 * Example:
 *
 *  {
 *      "category_id" : [
 *          {
 *              "identifier" : "action ID",
 *              "title_resource" : "action title resource",
 *              "title" : "action title",
 *              "foreground" : @YES,
 *              "authenticationRequired" : @NO,
 *              "destructive" : @NO
 *          }]
 *  }
 *
 * @param filePath The path of the `.plist` file.
 * @return A set of categories.
 */
+ (NSSet *)createCategoriesFromFile:(NSString *)filePath;

/**
 * Creates a user notification category with the specified ID and action definitions.
 *
 * @param categoryId The category identifier
 * @param actionDefinitions An array of user notification action dictionaries used
 *        to construct UANotificationAction for the category.
 * @return The user notification category created or `nil` if an error occurred.
 */
+ (nullable UANotificationCategory *)createCategory:(NSString *)categoryId
                                            actions:(NSArray *)actionDefinitions;

/**
 * Creates a user notification category with the specified ID, action definitions, and 
 * hiddenPreviewsBodyPlaceholder.
 *
 * @param categoryId The category identifier
 * @param actionDefinitions An array of user notification action dictionaries used
 *        to construct UANotificationAction for the category.
 * @param hiddenPreviewsBodyPlaceholder A placeholder string to display when the 
 *        user has disabled notification previews for the app.
 * @return The user notification category created or `nil` if an error occurred.
 */
+ (UANotificationCategory * _Nullable)createCategory:(NSString *)categoryId
                                   actions:(NSArray *)actionDefinitions
             hiddenPreviewsBodyPlaceholder:(NSString *)hiddenPreviewsBodyPlaceholder;

@end

NS_ASSUME_NONNULL_END
