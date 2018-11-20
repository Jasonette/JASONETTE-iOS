/* Copyright 2017 Urban Airship and Contributors */

#import "UAPreferenceDataStore+InternalTagGroupsMutation.h"

@implementation UAPreferenceDataStore(TagGroupsMutation)


- (void)setTagGroupsMutations:(NSArray<UATagGroupsMutation *> *)Mutations forKey:(NSString *)key {
    NSData *encodedMutations = [NSKeyedArchiver archivedDataWithRootObject:Mutations];
    [self setObject:encodedMutations forKey:key];
}

- (NSArray<UATagGroupsMutation *> *)tagGroupsMutationsForKey:(NSString *)key {
    id encodedMutations = [self valueForKey:key];
    if (!encodedMutations) {
        return [NSArray<UATagGroupsMutation *> array];
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:encodedMutations];
}

- (void)addTagGroupsMutation:(UATagGroupsMutation *)mutation atBeginning:(BOOL)atBeginning forKey:(NSString *)key {
    id Mutations = [[self tagGroupsMutationsForKey:key] mutableCopy];

    if (!Mutations) {
        Mutations = @[mutation];
    } else if (atBeginning) {
        [Mutations insertObject:mutation atIndex:0];
    } else {
        [Mutations addObject:mutation];
    }

    Mutations = [UATagGroupsMutation collapseMutations:Mutations];
    [self setTagGroupsMutations:Mutations forKey:key];
}

- (UATagGroupsMutation *)pollTagGroupsMutationForKey:(NSString *)key {
    id Mutations = [[self tagGroupsMutationsForKey:key] mutableCopy];
    if (![Mutations count]) {
        return nil;
    }

    id mutation = Mutations[0];
    [Mutations removeObjectAtIndex:0];

    if ([Mutations count]) {
        [self setTagGroupsMutations:Mutations forKey:key];
    } else {
        [self removeObjectForKey:key];
    }

    return mutation;
}

- (void)migrateTagGroupSettingsForAddTagsKey:(NSString *)addTagsKey
                               removeTagsKey:(NSString *)removeTagsKey
                                      newKey:(NSString *)key {

    NSDictionary *addTags = [self objectForKey:addTagsKey];
    NSDictionary *removeTags = [self objectForKey:removeTagsKey];

    if (addTags || removeTags) {
        UATagGroupsMutation *mutation = [UATagGroupsMutation mutationWithAddTags:addTags removeTags:removeTags];
        [self addTagGroupsMutation:mutation atBeginning:YES forKey:key];

        [self removeObjectForKey:addTagsKey];
        [self removeObjectForKey:removeTagsKey];
    }
}

@end
