/* Copyright 2017 Urban Airship and Contributors */

#import "UAInbox+Internal.h"
#import "UAirship.h"
#import "UAInboxMessageList.h"
#import "UAInboxMessage.h"
#import "UAUser.h"
#import "UAInboxMessageList+Internal.h"

@implementation UAInbox

- (void)dealloc {
    [self.client.session cancelAllRequests];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithUser:(UAUser *)user config:(UAConfig *)config dataStore:(UAPreferenceDataStore *)dataStore {
    self = [super init];
    if (self) {
        self.user = user;
        self.client = [UAInboxAPIClient clientWithConfig:config session:[UARequestSession sessionWithConfig:config] user:user dataStore:dataStore];
        self.messageList = [UAInboxMessageList messageListWithUser:self.user client:self.client config:config];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(enterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];

        if (!self.user.isCreated) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(userCreated)
                                                         name:UAUserCreatedNotification
                                                       object:nil];
        }

        [self.messageList loadSavedMessages];

        // Register for didBecomeActive to refresh the inbox on the first active
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];



        // delete legacy UAInboxCache if present
        [self deleteInboxCache];
    }
    
    return self;
}

+ (instancetype) inboxWithUser:(UAUser *)user config:(UAConfig *)config dataStore:(UAPreferenceDataStore *)dataStore {
    return [[UAInbox alloc] initWithUser:user config:config dataStore:dataStore];
}

- (void)enterForeground {
    [self.messageList retrieveMessageListWithSuccessBlock:nil withFailureBlock:nil];
}


- (void)didBecomeActive {
    [self.messageList retrieveMessageListWithSuccessBlock:nil withFailureBlock:nil];

    // We only want to refresh the inbox on the first active. enterForeground will
    // handle any background->foreground inbox refresh
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
}

- (void)userCreated {
    [self.messageList retrieveMessageListWithSuccessBlock:nil withFailureBlock:nil];
}

//note: this is for deleting the UAInboxCache from disk, which is no longer in use.
- (void)deleteInboxCache{
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [cachePaths objectAtIndex:0];
    NSString *diskCachePath = [NSString stringWithFormat:@"%@/%@", cacheDirectory, @"UAInboxCache"];

    NSFileManager *fm = [NSFileManager defaultManager];

    if ([fm fileExistsAtPath:diskCachePath]) {
        NSError *error = nil;
        [fm removeItemAtPath:diskCachePath error:&error];
        if (error) {
            UA_LTRACE(@"Error deleting inbox cache: %@", error.description);
        }
    }
}

@end
