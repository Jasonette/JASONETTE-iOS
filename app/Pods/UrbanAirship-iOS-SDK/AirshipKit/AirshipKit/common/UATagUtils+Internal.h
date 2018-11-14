/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The UATagUtils object provides an interface for creating tags.
 */
@interface UATagUtils : NSObject

///---------------------------------------------------------------------------------------
/// @name Tag Utils Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Used to trim whitespace and filter out tags with unacceptable tag length.
 *
 * @note This method is for internal use only. It is called when tags are set.
 * @param tags Tags as an NSArray.
 */
+ (NSArray<NSString *> *)normalizeTags:(NSArray *)tags;

/**
 * Used to trim whitespace and validate a tag group.
 *
 * @note This method is for internal use only. It is called when tags are set.
 * @param tagGroupID Tags as an NSArray.
 */
+ (nullable NSString *)normalizeTagGroupID:(NSString *)tagGroupID;

@end

NS_ASSUME_NONNULL_END
