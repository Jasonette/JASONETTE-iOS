/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Model object for holding user data.
 */
@interface UAUserData : NSObject

///---------------------------------------------------------------------------------------
/// @name User Data Internal Properties
///---------------------------------------------------------------------------------------

/**
 * The user name.
 */
@property (nonatomic, readonly, copy) NSString *username;

/**
 * The password.
 */
@property (nonatomic, readonly, copy) NSString *password;

/**
 * The url as a string.
 */
@property (nonatomic, readonly, copy) NSString *url;

///---------------------------------------------------------------------------------------
/// @name User Data Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Autoreleased UAUserData class factory method.
 *
 * @param username The associated user name.
 * @param password The associated user password.
 * @param url The associated user url, as a string.
 */
+ (instancetype)dataWithUsername:(NSString *)username password:(NSString *)password url:(NSString *)url;

/**
 * UAUserData initializer.
 *
 * @param username The associated user name.
 * @param password The associated user password.
 * @param url The associated user url, as a string.
 */
- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password url:(NSString *)url;


@end

NS_ASSUME_NONNULL_END
