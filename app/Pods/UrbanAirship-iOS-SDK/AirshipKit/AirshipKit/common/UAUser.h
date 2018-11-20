/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const UAUserCreatedNotification;

/**
 * Primary interface for working with the application's associated UA user.
 */
@interface UAUser : NSObject

///---------------------------------------------------------------------------------------
/// @name User Properties
///---------------------------------------------------------------------------------------

/**
 * Indicates whether the default user has been created.
 * @return `YES` if the user has been created, `NO` otherwise.
 */
@property (nonatomic, readonly, getter=isCreated) BOOL created;

/**
 * The user name.
 */
@property (nonatomic, readonly, copy, nullable) NSString *username;

/**
 * The user password.
 */
@property (nonatomic, readonly, copy, nullable) NSString *password;

/**
 * The user url.
 */
@property (nonatomic, readonly, copy, nullable) NSString *url;

@end

NS_ASSUME_NONNULL_END

