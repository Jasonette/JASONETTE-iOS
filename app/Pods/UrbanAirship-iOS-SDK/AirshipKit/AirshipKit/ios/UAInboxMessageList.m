/* Copyright 2017 Urban Airship and Contributors */

#import "UAInboxMessageList+Internal.h"

#import "UAirship.h"
#import "UAConfig.h"
#import "UADisposable.h"
#import "UAInbox.h"
#import "UAInboxAPIClient+Internal.h"
#import "UAInboxMessage+Internal.h"
#import "UAInboxStore+Internal.h"
#import "UAUtils.h"
#import "UAUser.h"
#import "UAURLProtocol.h"

NSString * const UAInboxMessageListWillUpdateNotification = @"com.urbanairship.notification.message_list_will_update";
NSString * const UAInboxMessageListUpdatedNotification = @"com.urbanairship.notification.message_list_updated";

typedef void (^UAInboxMessageFetchCompletionHandler)(NSArray *);

@implementation UAInboxMessageList

@synthesize messages = _messages;

#pragma mark Create Inbox

- (instancetype)initWithUser:(UAUser *)user client:(UAInboxAPIClient *)client config:(UAConfig *)config {
    self = [super init];

    if (self) {
        self.inboxStore = [[UAInboxStore alloc] initWithConfig:config];
        self.user = user;
        self.client = client;
        self.batchOperationCount = 0;
        self.retrieveOperationCount = 0;
        self.unreadCount = -1;
        self.messages = @[];
    }

    return self;
}

+ (instancetype)messageListWithUser:(UAUser *)user client:(UAInboxAPIClient *)client config:(UAConfig *)config{
    return [[UAInboxMessageList alloc] initWithUser:user client:client config:config];
}

#pragma mark Accessors

- (void)setMessages:(NSArray *)messages {
    _messages = [messages copy];

    NSMutableDictionary *messageIDMap = [NSMutableDictionary dictionary];
    NSMutableDictionary *messageURLMap = [NSMutableDictionary dictionary];

    for (UAInboxMessage *message in _messages) {
        if (message.messageBodyURL.absoluteString) {
            [messageURLMap setObject:message forKey:message.messageBodyURL.absoluteString];
        }
        if (message.messageID) {
            [messageIDMap setObject:message forKey:message.messageID];
        }
    }

    self.messageIDMap = [messageIDMap copy];
    self.messageURLMap = [messageURLMap copy];
}

- (NSArray *)messages {
    return _messages;
}

- (NSArray<UAInboxMessage *> *)messagesFilteredUsingPredicate:(NSPredicate *)predicate {
    @synchronized(self) {
        return [_messages filteredArrayUsingPredicate:predicate];
    }
}

#pragma mark NSNotificationCenter helper methods

- (void)sendMessageListWillUpdateNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:UAInboxMessageListWillUpdateNotification object:nil];
}

- (void)sendMessageListUpdatedNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:UAInboxMessageListUpdatedNotification object:nil];
}

#pragma mark Update/Delete/Mark Messages

- (UADisposable *)retrieveMessageListWithSuccessBlock:(UAInboxMessageListCallbackBlock)successBlock
                                     withFailureBlock:(UAInboxMessageListCallbackBlock)failureBlock {

    if (!self.user.isCreated) {
        return nil;
    }

    UA_LDEBUG("Retrieving message list.");

    self.retrieveOperationCount++;
    [self sendMessageListWillUpdateNotification];

    __block UAInboxMessageListCallbackBlock retrieveMessageListSuccessBlock = successBlock;
    __block UAInboxMessageListCallbackBlock retrieveMessageListFailureBlock = failureBlock;

    UADisposable *disposable = [UADisposable disposableWithBlock:^{
        retrieveMessageListSuccessBlock = nil;
        retrieveMessageListFailureBlock = nil;
    }];

    void (^completionBlock)(BOOL) = ^(BOOL success){
        if (self.retrieveOperationCount > 0) {
            self.retrieveOperationCount--;
        }

        if (success) {

            if (retrieveMessageListSuccessBlock) {
                retrieveMessageListSuccessBlock();
            }
        } else {
            if (retrieveMessageListFailureBlock) {
                retrieveMessageListFailureBlock();
            }
        }

        [self sendMessageListUpdatedNotification];
    };

    // Fetch new messages
    [self.client retrieveMessageListOnSuccess:^(NSUInteger status, NSArray *messages) {
        // Sync client state
        [self syncLocalMessageState];

        if (status == 200) {
            UA_LDEBUG(@"Refreshing message list.");

            [self.inboxStore syncMessagesWithResponse:messages completionHandler:^(BOOL success) {
                if (!success) {
                    [self.client clearLastModifiedTime];
                    completionBlock(NO);
                    return;
                }

                // Push changes onto the main context
                [self refreshInboxWithCompletionHandler:^{
                    completionBlock(YES);
                }];
            }];
        } else {
            UA_LDEBUG(@"Retrieve message list succeeded with status: %lu", (unsigned long)status);
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(YES);
            });
        }

    } onFailure:^(){
        UA_LDEBUG(@"Retrieve message list failed");
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(NO);
        });
    }];

    return disposable;
}


- (UADisposable *)markMessagesRead:(NSArray *)messages completionHandler:(UAInboxMessageListCallbackBlock)completionHandler {
    if (!messages.count) {
        return nil;
    }

    NSArray *messageIDs = [messages valueForKeyPath:@"messageID"];

    for (UAInboxMessage *message in messages) {
        message.unread = NO;
    }

    self.batchOperationCount++;
    [self sendMessageListWillUpdateNotification];

    __block UAInboxMessageListCallbackBlock inboxMessageListCompletionBlock = completionHandler;
    UADisposable *disposable = [UADisposable disposableWithBlock:^{
        inboxMessageListCompletionBlock = nil;
    }];

    [self.inboxStore fetchMessagesWithPredicate:[NSPredicate predicateWithFormat:@"messageID IN %@", messageIDs]
                              completionHandler:^(NSArray<UAInboxMessageData *> *data) {

                                  UA_LDEBUG(@"Marking messages as read: %@.", messageIDs);
                                  for (UAInboxMessageData *messageData in data) {
                                      messageData.unreadClient = NO;
                                  }

                                  // Refresh the messages
                                  [self refreshInboxWithCompletionHandler:^{
                                      if (self.batchOperationCount > 0) {
                                          self.batchOperationCount--;
                                      }

                                      if (inboxMessageListCompletionBlock) {
                                          inboxMessageListCompletionBlock();
                                      }

                                      [self sendMessageListUpdatedNotification];
                                  }];

                                  [self syncLocalMessageState];
                              }];

    return disposable;
}

- (UADisposable *)markMessagesDeleted:(NSArray *)messages completionHandler:(UAInboxMessageListCallbackBlock)completionHandler{
    if (!messages.count) {
        return nil;
    }

    NSArray *messageIDs = [messages valueForKeyPath:@"messageID"];

    self.batchOperationCount++;
    [self sendMessageListWillUpdateNotification];

    __block UAInboxMessageListCallbackBlock inboxMessageListCompletionBlock = completionHandler;
    UADisposable *disposable = [UADisposable disposableWithBlock:^{
        inboxMessageListCompletionBlock = nil;
    }];


    [self.inboxStore fetchMessagesWithPredicate:[NSPredicate predicateWithFormat:@"messageID IN %@", messageIDs]
                              completionHandler:^(NSArray<UAInboxMessageData *> *data) {

                                  UA_LDEBUG(@"Marking messages as deleted %@.", messageIDs);
                                  for (UAInboxMessageData *messageData in data) {
                                      messageData.deletedClient = YES;
                                  }

                                  // Refresh the messages
                                  [self refreshInboxWithCompletionHandler:^{
                                      if (self.batchOperationCount > 0) {
                                          self.batchOperationCount--;
                                      }

                                      if (inboxMessageListCompletionBlock) {
                                          inboxMessageListCompletionBlock();
                                      }

                                      [self sendMessageListUpdatedNotification];
                                  }];

                                  [self syncLocalMessageState];
                              }];


    return disposable;
}

- (void)loadSavedMessages {
    // First load
    [self sendMessageListWillUpdateNotification];
    [self refreshInboxWithCompletionHandler:^ {
        [self sendMessageListUpdatedNotification];
    }];
}

#pragma mark -
#pragma mark Internal/Helper Methods


/**
 * Refreshes the publicly exposed inbox messages on the private context. 
 * The completion handler is executed on the main context.
 *
 * @param completionHandler Optional completion handler.
 */
- (void)refreshInboxWithCompletionHandler:(void (^)(void))completionHandler {
    NSString *predicateFormat = @"(messageExpiration == nil || messageExpiration >= %@) && (deletedClient == NO || deletedClient == nil)";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat, [NSDate date]];

    [self.inboxStore fetchMessagesWithPredicate:predicate
                              completionHandler:^(NSArray<UAInboxMessageData *> *data) {
                                  NSInteger unreadCount = 0;
                                  NSMutableArray *messages = [NSMutableArray arrayWithCapacity:data.count];

                                  for (UAInboxMessageData *messageData in data) {
                                      UAInboxMessage *message = [self messageFromMessageData:messageData];
                                      if (message.unread) {
                                          unreadCount ++;
                                      }
                                      // Add messsage's body url to the cachable urls
                                      [UAURLProtocol addCachableURL:message.messageBodyURL];

                                      [messages addObject:message];
                                  }

                                  UA_LINFO(@"Inbox messages updated.");

                                  UA_LTRACE(@"Loaded saved messages: %@.", messages);
                                  self.unreadCount = unreadCount;
                                  self.messages = messages;

                                  if (completionHandler) {
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          completionHandler();
                                      });
                                  }
                              }];
}

/**
 * Synchronizes local read messages state with the server, on the private context.
 */
- (void)syncReadMessageState {
    [self.inboxStore fetchMessagesWithPredicate:[NSPredicate predicateWithFormat:@"unreadClient == NO && unread == YES"]
                              completionHandler:^(NSArray<UAInboxMessageData *> *data) {
                                  if (!data.count) {
                                      // Nothing to do
                                      return;
                                  }

                                  NSArray *messageURLs = [data valueForKeyPath:@"messageURL"];
                                  NSArray *messageIDs = [data valueForKeyPath:@"messageID"];

                                  UA_LDEBUG(@"Synchronizing locally read messages %@ on server.", messageIDs);

                                  [self.client performBatchMarkAsReadForMessageURLs:messageURLs onSuccess:^{

                                      // Mark the messages as read
                                      [self.inboxStore fetchMessagesWithPredicate:[NSPredicate predicateWithFormat:@"messageID IN %@", messageIDs]
                                                                completionHandler:^(NSArray<UAInboxMessageData *> *data) {
                                                                    for (UAInboxMessageData *messageData in data) {
                                                                        messageData.unread = NO;
                                                                    }

                                                                    UA_LDEBUG(@"Successfully synchronized locally read messages on server.");
                                                                }];
                                  } onFailure:^() {
                                      UA_LDEBUG(@"Failed to synchronize locally read messages on server.");
                                  }];

                              }];
}

/**
 * Synchronizes local deleted message state with the server, on the private context.
 */
- (void)syncDeletedMessageState {

    [self.inboxStore fetchMessagesWithPredicate:[NSPredicate predicateWithFormat:@"deletedClient == YES"]
                              completionHandler:^(NSArray<UAInboxMessageData *> *data) {
                                  if (!data.count) {
                                      // Nothing to do
                                      return;
                                  }


                                  NSArray *messageURLs = [data valueForKeyPath:@"messageURL"];
                                  NSArray *messageIDs = [data valueForKeyPath:@"messageID"];

                                  UA_LDEBUG(@"Synchronizing locally deleted messages %@ on server.", messageIDs);

                                  [self.client performBatchDeleteForMessageURLs:messageURLs onSuccess:^{
                                      UA_LDEBUG(@"Successfully synchronized locally deleted messages on server.");
                                  } onFailure:^() {
                                      UA_LDEBUG(@"Failed to synchronize locally deleted messages on server.");
                                  }];
                              }];
}

/**
 * Synchronizes any local read or deleted message state with the server, on the private context.
 */
- (void)syncLocalMessageState {
    [self syncReadMessageState];
    [self syncDeletedMessageState];
}

- (NSUInteger)messageCount {
    return [self.messages count];
}

- (UAInboxMessage *)messageForBodyURL:(NSURL *)url {
    return [self.messageURLMap objectForKey:url.absoluteString];
}

- (UAInboxMessage *)messageForID:(NSString *)messageID {
    return [self.messageIDMap objectForKey:messageID];
}

- (BOOL)isRetrieving {
    return self.retrieveOperationCount > 0;
}

- (BOOL)isBatchUpdating {
    return self.batchOperationCount > 0;
}

- (id)debugQuickLookObject {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@""];

    NSUInteger index = 0;
    NSUInteger characterIndex = 0;
    for (UAInboxMessage *message in self.messages) {
        NSString *line = index < self.messages.count-1 ? [NSString stringWithFormat:@"%@\n", message.title] : message.title;
        [attributedString.mutableString appendString:line];
        // Display unread messages in bold text
        NSString *fontName = message.unread ? @"Helvetica Bold" : @"Helvetica";
        [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:fontName size:15]
                                 range:NSMakeRange(characterIndex, line.length)];
        index++;
        characterIndex += line.length;
    }
    
    return attributedString;
}

- (UAInboxMessage *)messageFromMessageData:(UAInboxMessageData *)data {
    return [UAInboxMessage messageWithBuilderBlock:^(UAInboxMessageBuilder *builder) {
        builder.messageURL = data.messageURL;
        builder.messageID = data.messageID;
        builder.messageSent = data.messageSent;
        builder.messageBodyURL = data.messageBodyURL;
        builder.messageExpiration = data.messageExpiration;
        builder.unread = data.unreadClient & data.unread;
        builder.rawMessageObject = data.rawMessageObject;
        builder.extra = data.extra;
        builder.title = data.title;
        builder.contentType = data.contentType;
        builder.messageList = self;
    }];
}

@end
