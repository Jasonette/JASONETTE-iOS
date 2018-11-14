/* Copyright 2017 Urban Airship and Contributors */

#import "UADefaultMessageCenter.h"
#import "UAirship.h"
#import "UAInbox.h"
#import "UAInboxMessage.h"
#import "UAUtils.h"
#import "UAMessageCenterLocalization.h"
#import "UADefaultMessageCenterListViewController.h"
#import "UADefaultMessageCenterMessageViewController.h"
#import "UADefaultMessageCenterSplitViewController.h"
#import "UADefaultMessageCenterStyle.h"
#import "UAConfig.h"

@interface UADefaultMessageCenter()
@property(nonatomic, strong) UADefaultMessageCenterSplitViewController *splitViewController;
@end

@implementation UADefaultMessageCenter

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = UAMessageCenterLocalizedString(@"ua_message_center_title");
    }
    return self;
}

+ (instancetype)messageCenterWithConfig:(UAConfig *)config {
    UADefaultMessageCenter *center = [[UADefaultMessageCenter alloc] init];
    center.style = [UADefaultMessageCenterStyle styleWithContentsOfFile:config.messageCenterStyleConfig];
    return center;
}

- (void)display:(BOOL)animated {
    if (!self.splitViewController) {

        self.splitViewController = [[UADefaultMessageCenterSplitViewController alloc] initWithNibName:nil bundle:nil];
        self.splitViewController.filter = self.filter;

        UADefaultMessageCenterListViewController *lvc = self.splitViewController.listViewController;

        // if "Done" has been localized, use it, otherwise use iOS's UIBarButtonSystemItemDone
        if (UAMessageCenterLocalizedStringExists(@"ua_done")) {
            lvc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:UAMessageCenterLocalizedString(@"ua_done")
                                                                                    style:UIBarButtonItemStyleDone
                                                                                   target:self
                                                                                   action:@selector(dismiss)];
        } else {
            lvc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                                 target:self
                                                                                                 action:@selector(dismiss)];
        }

        self.splitViewController.style = self.style;
        self.splitViewController.title = self.title;

        self.splitViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

        [[UAUtils topController] presentViewController:self.splitViewController animated:animated completion:nil];
    }
}

- (void)display {
    [self display:YES];
}

- (void)displayMessage:(UAInboxMessage *)message animated:(BOOL)animated {
    [self display:animated];
    [self.splitViewController.listViewController displayMessage:message];
}

- (void)displayMessage:(UAInboxMessage *)message {
    [self displayMessage:message animated:NO];
}

- (void)displayMessageForID:(NSString *)messageID animated:(BOOL)animated {
    [self display:animated];
    [self.splitViewController.listViewController displayMessageForID:messageID];
}

- (void)displayMessageForID:(NSString *)messageID {
    [self displayMessageForID:messageID animated:NO];
}

- (void)dismiss:(BOOL)animated {
    [self.splitViewController.presentingViewController dismissViewControllerAnimated:animated completion:nil];
    self.splitViewController = nil;
}

- (void)dismiss {
    [self dismiss:YES];
}

@end
