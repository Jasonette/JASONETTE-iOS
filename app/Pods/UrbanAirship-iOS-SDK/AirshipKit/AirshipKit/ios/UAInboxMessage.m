/* Copyright 2017 Urban Airship and Contributors */

#import "UAInboxMessage+Internal.h"
#import "UAInbox.h"
#import "UAInboxMessageData+Internal.h"
#import "UAInboxAPIClient+Internal.h"
#import "UAInboxMessageList+Internal.h"
#import "UAUtils.h"

@interface UAInboxMessage()
@property (nonatomic, copy) NSString *messageID;
@property (nonatomic, strong) NSURL *messageBodyURL;
@property (nonatomic, strong) NSURL *messageURL;
@property (nonatomic, copy) NSString *contentType;
@property (nonatomic, strong) NSDate *messageSent;
@property (nonatomic, strong, nullable) NSDate *messageExpiration;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSDictionary *extra;
@property (nonatomic, copy) NSDictionary *rawMessageObject;
@property (nonatomic, weak) UAInboxMessageList *messageList;
@end

@implementation UAInboxMessageBuilder

@end

@implementation UAInboxMessage

- (instancetype)initWithBuilder:(UAInboxMessageBuilder *)builder {
    self = [super init];
    if (self) {
        self.messageURL = builder.messageURL;
        self.messageID = builder.messageID;
        self.messageSent = builder.messageSent;
        self.messageBodyURL = builder.messageBodyURL;
        self.messageExpiration = builder.messageExpiration;
        self.unread = builder.unread;
        self.rawMessageObject = builder.rawMessageObject;
        self.extra = builder.extra;
        self.title = builder.title;
        self.contentType = builder.contentType;
        self.messageList = builder.messageList;
    }
    return self;
}

+ (instancetype)messageWithBuilderBlock:(void (^)(UAInboxMessageBuilder *))builderBlock {
    UAInboxMessageBuilder *builder = [[UAInboxMessageBuilder alloc] init];

    if (builderBlock) {
        builderBlock(builder);
    }

    return [[UAInboxMessage alloc] initWithBuilder:builder];
}

#pragma mark -
#pragma mark NSObject methods

// NSObject override
- (NSString *)description {
    return [NSString stringWithFormat: @"%@ - %@", self.messageID, self.title];
}

#pragma mark -
#pragma mark Mark As Read Delegate Methods


- (UADisposable *)markMessageReadWithCompletionHandler:(UAInboxMessageCallbackBlock)completionHandler {
    if (!self.unread) {
        return nil;
    }

    return [self.messageList markMessagesRead:@[self] completionHandler:^{
        if (completionHandler) {
            completionHandler(self);
        }
    }];
}

- (BOOL)isExpired {
    if (self.messageExpiration) {
        NSComparisonResult result = [self.messageExpiration compare:[NSDate date]];
        return (result == NSOrderedAscending || result == NSOrderedSame);
    }

    return NO;
}


#pragma mark -
#pragma mark Quick Look methods

- (BOOL)waitWithTimeoutInterval:(NSTimeInterval)interval pollingWebView:(UIWebView *)webView {
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:interval];
    // The webView may not have begun loading at this point
    BOOL loadingStarted = webView.loading;
    while ([timeoutDate timeIntervalSinceNow] > 0) {
        if (!loadingStarted && webView.loading) {
            loadingStarted = YES;
        } else if (loadingStarted && !webView.loading) {
            // Break once the webView has transitioned from a loading to non-loading state
            break;
        }
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    return [timeoutDate timeIntervalSinceNow] > 0;
}

- (id)debugQuickLookObject {

    UIWebView *webView = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.messageBodyURL];
    NSString *auth = [UAUtils userAuthHeaderString];
    [request setValue:auth forHTTPHeaderField:@"Authorization"];

    // Load the message body, spin the run loop and poll the webView with a 5 second timeout.
    [webView loadRequest:request];
    [self waitWithTimeoutInterval:5 pollingWebView:webView];

    // Return a UIImage rendered from the webView
    UIGraphicsBeginImageContext(webView.bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [webView.layer renderInContext:context];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@end
