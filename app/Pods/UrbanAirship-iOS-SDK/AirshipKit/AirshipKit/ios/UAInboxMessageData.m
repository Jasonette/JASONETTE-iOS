/* Copyright 2017 Urban Airship and Contributors */

#import "UAInboxMessageData+Internal.h"
#import "UAInboxMessage+Internal.h"

#import "UAirship.h"
#import "UAInbox.h"
#import "UAInboxMessageList.h"
#import "UAUtils.h"
#import "UAGlobal.h"

/*
 * Implementation
 */
@implementation UAInboxMessageData

@dynamic title;
@dynamic messageBodyURL;
@dynamic messageSent;
@dynamic messageExpiration;
@dynamic unread;
@dynamic unreadClient;
@dynamic deletedClient;
@dynamic messageURL;
@dynamic messageID;
@dynamic extra;
@dynamic rawMessageObject;


@synthesize contentType;

- (BOOL)isGone{
    return ![self.managedObjectContext existingObjectWithID:self.objectID error:NULL];
}
@end
