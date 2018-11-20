/* Copyright 2017 Urban Airship and Contributors */

#import "UAAction.h"

/**
 * This is the base class for UAAddTagsAction and UARemoveTagsAction.
 */
@interface UAModifyTagsAction : UAAction

///---------------------------------------------------------------------------------------
/// @name Modify Tags Action Methods
///---------------------------------------------------------------------------------------

/**
 * Called when updating channel tags.
 * @param tags The array of tags.
 */
- (void)applyChannelTags:(NSArray *)tags;

/**
 * Called when updating a channel tag group.
 * @param tags The array of tags.
 * @param group The tag group.
 */
- (void)applyChannelTags:(NSArray *)tags group:(NSString *)group;

/**
 * Called when updating a named user tag group.
 * @param tags The array of tags.
 * @param group The tag group.
 */
- (void)applyNamedUserTags:(NSArray *)tags group:(NSString *)group;
@end
