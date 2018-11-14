/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAPreferenceDataStore+Internal.h"
#import "UATagGroupsMutation+Internal.h"
#import "UATagGroupsMutation+Internal.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Category methods to save and return tag mutations.
 */
@interface UAPreferenceDataStore(TagGroupsMutation)

///---------------------------------------------------------------------------------------
/// @name Tag Groups Mutation Category Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Adds a tag mutation to the array of saved mutations.
 * @param mutation The mutation to add.
 * @param atBeginning If the mutation should be inserted at the front of the array or not.
 * @param key The datastore key.
 */
- (void)addTagGroupsMutation:(UATagGroupsMutation *)mutation atBeginning:(BOOL)atBeginning forKey:(NSString *)key;

/**
 * Return the array of saved mutations.
 * @return The saved mutations as an array
 */
- (NSArray<UATagGroupsMutation *> *)tagGroupsMutationsForKey:(NSString *)key;

/**
 * Polls and removes the first mutation from the array of pending mutations.
 * @param key The datastore key.
 * @return The first mutation, or nil if no mutations are available.
 */
- (nullable UATagGroupsMutation *)pollTagGroupsMutationForKey:(NSString *)key;

/**
 * Migrates pending add and remove tag group changes to an array of mutations.
 * @param addTagsKey The data store key for pending add tag changes.
 * @param removeTagsKey The data store key for pending remove tag changes.
 * @param key The data store key to store the migrated mutations.
 */
- (void)migrateTagGroupSettingsForAddTagsKey:(NSString *)addTagsKey
                               removeTagsKey:(NSString *)removeTagsKey
                                      newKey:(NSString *)key;


@end

NS_ASSUME_NONNULL_END
