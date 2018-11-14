/* Copyright 2017 Urban Airship and Contributors */

#import "UANamedUser+Internal.h"
#import "UAPreferenceDataStore+InternalTagGroupsMutation.h"
#import "UANamedUserAPIClient+Internal.h"
#import "UAPush+Internal.h"
#import "UATagGroupsAPIClient+Internal.h"
#import "UATagUtils+Internal.h"
#import "UAConfig+Internal.h"
#import "UATagGroupsMutation+Internal.h"

#define kUAMaxNamedUserIDLength 128

NSString *const UANamedUserIDKey = @"UANamedUserID";
NSString *const UANamedUserChangeTokenKey = @"UANamedUserChangeToken";
NSString *const UANamedUserLastUpdatedTokenKey = @"UANamedUserLastUpdatedToken";

// Named user tag group keys
NSString *const UANamedUserAddTagGroupsSettingsKey = @"UANamedUserAddTagGroups";
NSString *const UANamedUserRemoveTagGroupsSettingsKey = @"UANamedUserRemoveTagGroups";
NSString *const UANamedUserTagGroupsMutationsKey = @"UANamedUserTagGroupsMutations";

@implementation UANamedUser

- (instancetype)initWithPush:(UAPush *)push config:(UAConfig *)config dataStore:(UAPreferenceDataStore *)dataStore {
    self = [super init];
    if (self) {
        self.config = config;
        self.push = push;
        self.dataStore = dataStore;
        self.namedUserAPIClient = [UANamedUserAPIClient clientWithConfig:config];
        self.tagGroupsAPIClient = [UATagGroupsAPIClient clientWithConfig:config];


        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(channelCreated:)
                                                     name:UAChannelCreatedEvent
                                                   object:nil];

        // Migrate tag group settings
        [self.dataStore migrateTagGroupSettingsForAddTagsKey:UANamedUserAddTagGroupsSettingsKey
                                               removeTagsKey:UANamedUserRemoveTagGroupsSettingsKey
                                                      newKey:UANamedUserTagGroupsMutationsKey];

        // Update the named user if necessary.
        [self update];
    }

    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


+ (instancetype) namedUserWithPush:(UAPush *)push config:(UAConfig *)config dataStore:(UAPreferenceDataStore *)dataStore {
    return [[UANamedUser alloc] initWithPush:push config:config dataStore:dataStore];
}

- (void)update {
    if (!self.changeToken && !self.lastUpdatedToken) {
        // Skip since no one has set the named user ID. Usually from a new or re-install.
        UA_LDEBUG(@"New or re-install, skipping named user update.");
        return;
    }

    if ([self.changeToken isEqualToString:self.lastUpdatedToken]) {
        // Skip since no change has occurred (token remains the same).
        UA_LDEBUG(@"Named user already updated. Skipping.");
        return;
    }

    if (!self.push.channelID) {
        // Skip since we don't have a channel ID.
        UA_LDEBUG(@"The channel ID does not exist. Will retry when channel ID is available.");
        return;
    }

    if (self.identifier) {
        // When identifier is non-nil, associate the current named user ID.
        [self associateNamedUser];
    } else {
        // When identifier is nil, disassociate the current named user ID.
        [self disassociateNamedUser];
    }
}

- (NSString *)identifier {
    return [self.dataStore objectForKey:UANamedUserIDKey];
}

- (void)setIdentifier:(NSString *)identifier {
    NSString *trimmedID;
    if (identifier) {
        trimmedID = [identifier stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([trimmedID length] <= 0 || [trimmedID length] > kUAMaxNamedUserIDLength) {
            UA_LERR(@"Failed to set named user ID. The named user ID must be greater than 0 and less than 129 characters.");
            return;
        }
    }

    // if the IDs don't match or ID is set to nil and current token is nil (re-install case), then update.
    if (!(self.identifier == trimmedID || [self.identifier isEqualToString:trimmedID]) || (!self.identifier && !self.changeToken)) {
        [self.dataStore setValue:trimmedID forKey:UANamedUserIDKey];

        // Update the change token.
        self.changeToken = [NSUUID UUID].UUIDString;

        // Update named user.
        [self update];

        // Clear pending tag group mutations
        [self.dataStore removeObjectForKey:UANamedUserTagGroupsMutationsKey];

    } else {
        UA_LDEBUG(@"NamedUser - Skipping update. Named user ID trimmed already matches existing named user: %@", self.identifier);
    }
}

- (void)setChangeToken:(NSString *)uuidString {
    [self.dataStore setValue:uuidString forKey:UANamedUserChangeTokenKey];
}

- (NSString *)changeToken {
    return [self.dataStore objectForKey:UANamedUserChangeTokenKey];
}

- (void)setLastUpdatedToken:(NSString *)token {
    [self.dataStore setValue:token forKey:UANamedUserLastUpdatedTokenKey];
}

- (NSString *)lastUpdatedToken {
    return [self.dataStore objectForKey:UANamedUserLastUpdatedTokenKey];
}

- (void)associateNamedUser {
    NSString *token = self.changeToken;
    [self.namedUserAPIClient associate:self.identifier channelID:self.push.channelID
                             onSuccess:^{
                                 self.lastUpdatedToken = token;
                                 UA_LDEBUG(@"Named user associated to channel successfully.");
                             }
                             onFailure:^(NSUInteger status) {
                                 UA_LDEBUG(@"Failed to associate channel to named user.");
                             }];
}

- (void)disassociateNamedUser {
    NSString *token = self.changeToken;
    [self.namedUserAPIClient disassociate:self.push.channelID
                                onSuccess:^{
                                    self.lastUpdatedToken = token;
                                    UA_LDEBUG(@"Named user disassociated from channel successfully.");
                                }
                                onFailure:^(NSUInteger status) {
                                    UA_LDEBUG(@"Failed to disassociate channel from named user.");
                                }];
}

- (void)disassociateNamedUserIfNil {
    if (!self.identifier) {
        self.identifier = nil;
    }
}

- (void)forceUpdate {
    UA_LDEBUG(@"NamedUser - force named user update.");
    self.changeToken = [NSUUID UUID].UUIDString;
    [self update];
}


- (void)addTags:(NSArray *)tags group:(NSString *)tagGroupID {
    NSArray *normalizedTags = [UATagUtils normalizeTags:tags];
    NSString *normalizedTagGroupID = [UATagUtils normalizeTagGroupID:tagGroupID];

    if (!normalizedTags.count || !normalizedTagGroupID.length) {
        return;
    }

    UATagGroupsMutation *mutation = [UATagGroupsMutation mutationToAddTags:normalizedTags
                                                                     group:normalizedTagGroupID];

    [self.dataStore addTagGroupsMutation:mutation atBeginning:NO forKey:UANamedUserTagGroupsMutationsKey];
}

- (void)removeTags:(NSArray *)tags group:(NSString *)tagGroupID {
    NSArray *normalizedTags = [UATagUtils normalizeTags:tags];
    NSString *normalizedTagGroupID = [UATagUtils normalizeTagGroupID:tagGroupID];

    if (!normalizedTags.count || !normalizedTagGroupID.length) {
        return;
    }

    UATagGroupsMutation *mutation = [UATagGroupsMutation mutationToRemoveTags:normalizedTags
                                                                        group:normalizedTagGroupID];

    [self.dataStore addTagGroupsMutation:mutation atBeginning:NO forKey:UANamedUserTagGroupsMutationsKey];
}

- (void)setTags:(NSArray *)tags group:(NSString *)tagGroupID {
    NSArray *normalizedTags = [UATagUtils normalizeTags:tags];
    NSString *normalizedTagGroupID = [UATagUtils normalizeTagGroupID:tagGroupID];

    if (!normalizedTagGroupID.length) {
        return;
    }

    UATagGroupsMutation *mutation = [UATagGroupsMutation mutationToSetTags:normalizedTags
                                                                     group:normalizedTagGroupID];

    [self.dataStore addTagGroupsMutation:mutation atBeginning:NO forKey:UANamedUserTagGroupsMutationsKey];
}

- (void)updateTags {
    if (!self.identifier) {
        return;
    }

    UATagGroupsMutation *mutation = [self.dataStore pollTagGroupsMutationForKey:UANamedUserTagGroupsMutationsKey];

    if (!mutation) {
        return;
    }

    __block UIBackgroundTaskIdentifier backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        UA_LTRACE(@"Tag groups background task expired.");
        [self.tagGroupsAPIClient cancelAllRequests];
        [self.dataStore addTagGroupsMutation:mutation atBeginning:YES forKey:UANamedUserTagGroupsMutationsKey];

        if (backgroundTask != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
            backgroundTask = UIBackgroundTaskInvalid;
        }
    }];

    if (backgroundTask == UIBackgroundTaskInvalid) {
        UA_LTRACE("Background task unavailable, skipping tag groups update.");
        [self.dataStore addTagGroupsMutation:mutation atBeginning:YES forKey:UANamedUserTagGroupsMutationsKey];
        return;
    }

    [self.tagGroupsAPIClient updateNamedUser:self.identifier
                           tagGroupsMutation:mutation
                           completionHandler:^(NSUInteger status) {
                               if (status >= 200 && status <= 299) {
                                   [self updateTags];
                               } else if (status != 400 && status != 403) {
                                   [self.dataStore addTagGroupsMutation:mutation atBeginning:YES forKey:UANamedUserTagGroupsMutationsKey];
                               }

                               [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
                               backgroundTask = UIBackgroundTaskInvalid;
                           }];
}

- (void)channelCreated:(NSNotification *)notification {
    BOOL existing = [notification.userInfo[UAChannelCreatedEventExistingKey] boolValue];

    // If this channel previously existed, a named user may be associated to it.
    if (existing && self.config.clearNamedUserOnAppRestore) {
        [self disassociateNamedUserIfNil];
    } else {
        // Once we get a channel, update the named user if necessary.
        [self update];
    }
}

@end
