/* Copyright 2017 Urban Airship and Contributors */

#import "UATagGroupsMutation+Internal.h"

#define kUATagGroupsSetKey @"set"
#define kUATagGroupsAddKey @"add"
#define kUATagGroupsRemoveKey @"remove"

@interface UATagGroupsMutation()
@property(nonatomic, strong) NSDictionary *addTagGroups;
@property(nonatomic, strong) NSDictionary *removeTagGroups;
@property(nonatomic, strong) NSDictionary *setTagGroups;
@end

@implementation UATagGroupsMutation

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.addTagGroups forKey:kUATagGroupsAddKey];
    [coder encodeObject:self.removeTagGroups forKey:kUATagGroupsRemoveKey];
    [coder encodeObject:self.setTagGroups forKey:kUATagGroupsSetKey];
}

- (id)initWithCoder:(NSCoder *)coder;
{
    self = [super init];
    if (self) {
        self.addTagGroups = [coder decodeObjectForKey:kUATagGroupsAddKey];
        self.removeTagGroups = [coder decodeObjectForKey:kUATagGroupsRemoveKey];
        self.setTagGroups = [coder decodeObjectForKey:kUATagGroupsSetKey];
    }

    return self;
}

+ (instancetype)mutationToAddTags:(NSArray *)tags group:(NSString *)group {

    UATagGroupsMutation *mutation = [[UATagGroupsMutation alloc] init];

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:[NSSet setWithArray:tags] forKey:group];
    mutation.addTagGroups = dictionary;

    return mutation;
}

+ (instancetype)mutationToRemoveTags:(NSArray *)tags group:(NSString *)group {

    UATagGroupsMutation *mutation = [[UATagGroupsMutation alloc] init];

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:[NSSet setWithArray:tags] forKey:group];
    mutation.removeTagGroups = dictionary;

    return mutation;
}

+ (instancetype)mutationToSetTags:(NSArray *)tags group:(NSString *)group {

    UATagGroupsMutation *mutation = [[UATagGroupsMutation alloc] init];

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:[NSSet setWithArray:tags] forKey:group];
    mutation.setTagGroups = dictionary;

    return mutation;
}


+ (instancetype)mutationWithAddTags:(NSDictionary *)addTags
                         removeTags:(NSDictionary *)removeTags {

    UATagGroupsMutation *mutation = [[UATagGroupsMutation alloc] init];
    mutation.removeTagGroups = [UATagGroupsMutation normalizeTagGroup:removeTags];
    mutation.addTagGroups = [UATagGroupsMutation normalizeTagGroup:addTags];;
    return mutation;
}

- (NSDictionary *)payload {
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    if (self.setTagGroups.count) {
        [payload setValue:[UATagGroupsMutation prepareTagGroup:self.setTagGroups] forKey:kUATagGroupsSetKey];
    }

    if (self.addTagGroups.count) {
        [payload setValue:[UATagGroupsMutation prepareTagGroup:self.addTagGroups] forKey:kUATagGroupsAddKey];
    }

    if (self.removeTagGroups.count) {
        [payload setValue:[UATagGroupsMutation prepareTagGroup:self.removeTagGroups] forKey:kUATagGroupsRemoveKey];
    }

    return [payload copy];
}

+ (NSArray<UATagGroupsMutation *> *)collapseMutations:(NSArray<UATagGroupsMutation *> *)mutations {
    if (!mutations.count) {
        return mutations;
    }

    NSMutableDictionary *addTagGroups = [NSMutableDictionary dictionary];
    NSMutableDictionary *removeTagGroups = [NSMutableDictionary dictionary];
    NSMutableDictionary *setTagGroups = [NSMutableDictionary dictionary];

    for (UATagGroupsMutation *mutation in mutations) {

        // Add tags
        for (NSString *group in mutation.addTagGroups) {

            NSMutableSet *tags = [mutation.addTagGroups[group] mutableCopy];

            // Add to the set tag groups if we can
            if (setTagGroups[group]) {
                [setTagGroups[group] unionSet:tags];
                continue;
            }

            // Remove from remove tag groups
            [removeTagGroups[group] minusSet:tags];
            if (![removeTagGroups[group] count]) {
                [removeTagGroups removeObjectForKey:group];
            }

            // Add to the add tag groups
            if (!addTagGroups[group]) {
                addTagGroups[group] = tags;
            } else {
                [addTagGroups[group] unionSet:tags];
            }
        }

        // Remove tags
        for (NSString *group in mutation.removeTagGroups) {
            NSMutableSet *tags = [mutation.removeTagGroups[group] mutableCopy];

            // Remove to the set tag groups if we can
            if (setTagGroups[group]) {
                [setTagGroups[group] minusSet:tags];
                break;
            }

            // Remove from add tag groups
            [addTagGroups[group] minusSet:tags];
            if (![addTagGroups[group] count]) {
                [addTagGroups removeObjectForKey:group];
            }

            // Add to the remove tag groups
            if (!removeTagGroups[group]) {
                removeTagGroups[group] = tags;
            } else {
                [removeTagGroups[group] unionSet:tags];
            }
        }

        // Set tags
        for (NSString *group in mutation.setTagGroups) {

            NSMutableSet *tags = [mutation.setTagGroups[group] mutableCopy];

            // Add to the set tags group
            setTagGroups[group] = tags;

            // Remove from the other groups
            [removeTagGroups removeObjectForKey:group];
            [addTagGroups removeObjectForKey:group];
        }
    }

    NSMutableArray *collapsedMutations = [NSMutableArray array];

    // Set must be a separate mutation
    if (setTagGroups.count) {
        UATagGroupsMutation *mutation = [[UATagGroupsMutation alloc] init];
        mutation.setTagGroups = setTagGroups;
        [collapsedMutations addObject:mutation];
    }

    // Add and remove can be collapsed into one mutation
    if (addTagGroups.count || removeTagGroups.count) {
        UATagGroupsMutation *mutation = [[UATagGroupsMutation alloc] init];
        mutation.removeTagGroups = removeTagGroups;
        mutation.addTagGroups = addTagGroups;
        [collapsedMutations addObject:mutation];
    }

    return [collapsedMutations copy];
}

/**
 * Normalizes a dictionary of tag groups. Converts any arrays to sets.
 * @param tagGroups A tag group.
 * @returns A tag group with sets instead of arrays.
 */
+ (NSDictionary *)normalizeTagGroup:(NSDictionary *)tagGroups {
    if (!tagGroups.count) {
        return nil;
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (NSString *group in tagGroups) {

        NSSet *tags = nil;
        if ([tagGroups[group] isKindOfClass:[NSSet class]]) {
            tags = tagGroups[group];
        } else {
            tags = [NSSet setWithArray:tagGroups[group]];
        }

        [dictionary setValue:tags forKey:group];
    }

    return dictionary;
}


/**
 * Converts a dictionary of string to set to a dictionary of string to array.
 * @param tagGroups A tag group.
 * @returns A tag group with arrays instead of sets.
 */
+ (NSDictionary *)prepareTagGroup:(NSDictionary *)tagGroups {
    if (!tagGroups.count) {
        return nil;
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (NSString *group in tagGroups) {

        NSArray *tags = nil;
        if ([tagGroups[group] isKindOfClass:[NSSet class]]) {
            tags = [tagGroups[group] allObjects];
        } else {
            tags = tagGroups[group];
        }

        [dictionary setValue:tags forKey:group];
    }

    return dictionary;
}

@end
