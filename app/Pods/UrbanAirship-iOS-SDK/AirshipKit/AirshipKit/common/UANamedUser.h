/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

@class UAPreferenceDataStore;

NS_ASSUME_NONNULL_BEGIN

/**
 * The named user is an alternate method of identifying the device. Once a named
 * user is associated to the device, it can be used to send push notifications
 * to the device.
 */
@interface UANamedUser : NSObject

///---------------------------------------------------------------------------------------
/// @name Named User Properties
///---------------------------------------------------------------------------------------

/**
 * The named user ID for this device.
 */
@property (nonatomic, copy, nullable) NSString *identifier;

///---------------------------------------------------------------------------------------
/// @name Named User Management
///---------------------------------------------------------------------------------------

/**
 * Force updating the association or disassociation of the current named user ID.
 */
- (void)forceUpdate;

/**
 * Add tags to named user tags. To update the server,
 * make all of your changes, then call `updateTags`.
 *
 * @param tags Array of tags to add.
 * @param tagGroupID Tag group ID string.
 */
- (void)addTags:(NSArray<NSString *> *)tags group:(NSString *)tagGroupID;

/**
 * Removes tags from named user tags. To update the server,
 * make all of your changes, then call `updateTags`.
 *
 * @param tags Array of tags to remove.
 * @param tagGroupID Tag group ID string.
 */
- (void)removeTags:(NSArray<NSString *> *)tags group:(NSString *)tagGroupID;


/**
 * Set tags for named user tags. To update the server,
 * make all of your changes, then call `updateTags`.
 *
 * @param tags Array of tags to set.
 * @param tagGroupID Tag group ID string.
 */
- (void)setTags:(NSArray<NSString *> *)tags group:(NSString *)tagGroupID;

/**
 * Update named user tags.
 */
- (void)updateTags;

@end

NS_ASSUME_NONNULL_END
