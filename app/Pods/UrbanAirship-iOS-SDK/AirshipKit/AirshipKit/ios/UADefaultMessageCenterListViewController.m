/* Copyright 2017 Urban Airship and Contributors */

#import "UADefaultMessageCenterListViewController.h"
#import "UADefaultMessageCenterListCell.h"
#import "UADefaultMessageCenterMessageViewController.h"
#import "UAMessageCenterMessageViewController.h"
#import "UAInboxMessage.h"
#import "UAirship.h"
#import "UAInbox.h"
#import "UAInboxMessageList.h"
#import "UAURLProtocol.h"
#import "UAMessageCenterLocalization.h"
#import "UADefaultMessageCenterStyle.h"
#import "UAConfig.h"

/*
 * List-view image controls: default image path and cache values
 */
#define kUAPlaceholderIconImage @"ua-inbox-icon-placeholder"
#define kUAIconImageCacheMaxCount 100
#define kUAIconImageCacheMaxByteCost (2 * 1024 * 1024) /* 2MB */
#define kUADefaultMessageCenterListCellNibName @"UADefaultMessageCenterListCell"

@interface UADefaultMessageCenterListViewController()

/**
 * The placeholder image to display in lieu of the icon
 */
@property (nonatomic, strong) UIImage *placeholderIcon;

/**
 * The table view of message list cells
 */
@property (nonatomic, weak) IBOutlet UITableView *messageTable;

/**
 * The messages displayed in the message table.
 */
@property (nonatomic, copy) NSArray *messages;

/**
 * The view displayed when there are no messages
 */
@property (nonatomic, weak) IBOutlet UIView *coverView;

/**
 * Label displayed in the coverView
 */
@property (nonatomic, weak) IBOutlet UILabel *coverLabel;

/**
 * The default tint color to use when overriding the inherited tint.
 */
@property (nonatomic, strong) UIColor *defaultTintColor;

/**
 * Bar button items for navigation bar and toolbar
 */
@property (nonatomic, strong) UIBarButtonItem *deleteItem;
@property (nonatomic, strong) UIBarButtonItem *selectAllButtonItem;
@property (nonatomic, strong) UIBarButtonItem *markAsReadButtonItem;
@property (nonatomic, strong) UIBarButtonItem *editItem;
@property (nonatomic, strong) UIBarButtonItem *cancelItem;


/**
 * The currently selected index path.
 */
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

/**
 * The currently selected message.
 */
@property (nonatomic, strong) UAInboxMessage *selectedMessage;

/**
 * The an array of currently selected message IDs during editing.
 */
@property (nonatomic, strong) NSMutableArray<NSString *> *selectedMessageIDs;

/**
 * Whether the interface is currently collapsed
 */
@property (nonatomic, assign) BOOL collapsed;

/**
 * A dictionary of sets of (NSIndexPath *) with absolute URLs (NSString *) for keys.
 * Used to track current list icon fetches.
 * Try to use this on the main thread.
 */
@property (nonatomic, strong) NSMutableDictionary *currentIconURLRequests;

/**
 * An icon cache that stores UIImage representations of fetched icon images
 * The default limit is 1MB or 100 items
 * Images are also stored in the UA HTTP Cache, so a re-fetch will typically only
 * incur the decoding (PNG->UIImage) costs.
 */
@property (nonatomic, strong) NSCache *iconCache;

/**
 * A refresh control used for "pull to refresh" behavior.
 */
@property (nonatomic, strong) UIRefreshControl *refreshControl;

/**
 * The refresh control is still animating.
 */
@property (nonatomic, assign) BOOL refreshControlAnimating;

/**
 * A concurrent dispatch queue to use for fetching icon images.
 */
@property (nonatomic, strong) dispatch_queue_t iconFetchQueue;

@end

@implementation UADefaultMessageCenterListViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.iconCache = [[NSCache alloc] init];
        self.iconCache.countLimit = kUAIconImageCacheMaxCount;
        self.iconCache.totalCostLimit = kUAIconImageCacheMaxByteCost;
        self.currentIconURLRequests = [NSMutableDictionary dictionary];
        self.refreshControl = [[UIRefreshControl alloc] init];
        self.iconFetchQueue = dispatch_queue_create("com.urbanairship.messagecenter.ListIconQueue", DISPATCH_QUEUE_CONCURRENT);

        // grab the default tint color from a dummy view
        self.defaultTintColor = [[UIView alloc] init].tintColor;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // if "Edit" has been localized, use it, otherwise use iOS's UIBarButtonSystemItemEdit
    if (UAMessageCenterLocalizedStringExists(@"ua_edit")) {
        self.editItem = [[UIBarButtonItem alloc] initWithTitle:UAMessageCenterLocalizedString(@"ua_edit")
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(editButtonPressed:)];
    } else {
        self.editItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                      target:self
                                                                      action:@selector(editButtonPressed:)];
    }
    
    self.cancelItem = [[UIBarButtonItem alloc]
                       initWithTitle:UAMessageCenterLocalizedString(@"ua_cancel")
                       style:UIBarButtonItemStyleDone
                       target:self
                       action:@selector(cancelButtonPressed:)];

    self.navigationItem.rightBarButtonItem = self.editItem;

    [self createToolbarItems];

    self.coverLabel.text = UAMessageCenterLocalizedString(@"ua_empty_message_list");

    if (self.style.listColor) {
        self.messageTable.backgroundColor = self.style.listColor;
    }

    if (self.style.cellSeparatorColor) {
        self.messageTable.separatorColor = self.style.cellSeparatorColor;
    }

    [self.refreshControl addTarget:self action:@selector(refreshStateChanged:) forControlEvents:UIControlEventValueChanged];

    UITableViewController *tableController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    tableController.view = self.messageTable;
    tableController.refreshControl = self.refreshControl;
    tableController.clearsSelectionOnViewWillAppear = false;

    if (self.style.listColor) {
        self.refreshControl.backgroundColor = self.style.listColor;
    }

    if (self.style.refreshTintColor) {
        self.refreshControl.tintColor = self.style.refreshTintColor;
    }

    // This allows us to use the UITableViewController for managing the refresh control, while keeping the
    // outer chrome of the list view controller intact
    [self addChildViewController:tableController];
    
    // get initial list of messages in the inbox
    [self copyMessages];

    // watch for changes to the message list
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageListUpdated)
                                                 name:UAInboxMessageListUpdatedNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.backBarButtonItem = nil;
    
    [self reload];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.editing) {
        return;
    }
    if (self.collapsed) {
        self.selectedMessage = nil;
        self.selectedIndexPath = nil;
    }
    [self handlePreviouslySelectedIndexPathsAnimated:YES];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UAInboxMessageListUpdatedNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.iconCache removeAllObjects];
}

- (void)setFilter:(NSPredicate *)filter {
    _filter = filter;
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    if ([self.messageViewController isKindOfClass:[UADefaultMessageCenterMessageViewController class]]) {
        ((UADefaultMessageCenterMessageViewController *)self.messageViewController).filter = self.filter;
    }
#pragma GCC diagnostic pop
}

- (void)refreshStateChanged:(UIRefreshControl *)sender {
    if (sender.refreshing) {
        self.refreshControlAnimating = YES;
        __weak id weakSelf = self;

        void (^retrieveMessageCompletionBlock)(void) = ^(void){
            dispatch_async(dispatch_get_main_queue(), ^{
                [CATransaction begin];
                [CATransaction setCompletionBlock: ^{
                    UADefaultMessageCenterListViewController *strongSelf = weakSelf;

                    // refresh animation has finished
                    strongSelf.refreshControlAnimating = NO;
                    [strongSelf chooseMessageDisplayAndReload];
                }];
                [sender endRefreshing];
                [CATransaction commit];
            });
        };

        [[UAirship inbox].messageList retrieveMessageListWithSuccessBlock:retrieveMessageCompletionBlock withFailureBlock:retrieveMessageCompletionBlock];
    } else {
        self.refreshControlAnimating = NO;
    }
}

- (void)createToolbarItems {

    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];

    self.selectAllButtonItem = [[UIBarButtonItem alloc] initWithTitle:UAMessageCenterLocalizedString(@"ua_select_all")
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(selectAllButtonPressed:)];

    // Override any inherited tint color, to avoid potential clashes
    self.selectAllButtonItem.tintColor = (self.style.selectAllButtonTitleColor) ? self.style.selectAllButtonTitleColor : self.defaultTintColor;


    self.deleteItem = [[UIBarButtonItem alloc] initWithTitle:UAMessageCenterLocalizedString(@"ua_delete")
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(batchUpdateButtonPressed:)];
    self.deleteItem.tintColor = (self.style.deleteButtonTitleColor) ? self.style.deleteButtonTitleColor : [UIColor redColor];

    self.markAsReadButtonItem = [[UIBarButtonItem alloc] initWithTitle:UAMessageCenterLocalizedString(@"ua_mark_read")
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self action:@selector(batchUpdateButtonPressed:)];

    // Override any inherited tint color, to avoid potential clashes
    self.markAsReadButtonItem.tintColor = (self.style.markAsReadButtonTitleColor) ? self.style.markAsReadButtonTitleColor : self.defaultTintColor;

    self.toolbarItems = @[self.selectAllButtonItem, flexibleSpace, self.deleteItem, flexibleSpace, self.markAsReadButtonItem];
}

- (void)reload {
    [self.messageTable reloadData];
    
    if (self.editing) {
        if (self.selectedMessageIDs.count > 0) {
            // re-select previously selected cells
            NSMutableArray *reSelectedMessageIDs = [[NSMutableArray alloc] init];
            for (UAInboxMessage *message in self.messages) {
                if ([self.selectedMessageIDs containsObject:message.messageID]) {
                    NSIndexPath *selectedIndexPath = [self indexPathForMessage:message];
                    if (selectedIndexPath) {
                        [self.messageTable selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                    }
                    [reSelectedMessageIDs addObject:message.messageID];
                }
            }
            [self.messageTable scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionNone animated:YES];
            self.selectedMessageIDs = reSelectedMessageIDs;
        }
    } else {
        [self handlePreviouslySelectedIndexPathsAnimated:NO];
    }

    // Cover up if necessary
    self.coverView.hidden = self.messages.count > 0;
    
    // Hide message view if necessary
    if (self.collapsed && (self.messages.count == 0) && (self.messageViewController == self.navigationController.visibleViewController)) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)handlePreviouslySelectedIndexPathsAnimated:(BOOL)animated {
    // If a cell was previously selected and there are messages to display
    if ((self.selectedMessage || self.selectedIndexPath) && (self.messages.count > 0)) {
        // find the index path for the message that is currently displayed
        NSIndexPath *indexPathOfCurrentlyDisplayedMessage = [self indexPathForMessage:self.messageViewController.message];
        if (indexPathOfCurrentlyDisplayedMessage) {
            // if the currently displayed message is still in the inbox list, select it
            self.selectedIndexPath = indexPathOfCurrentlyDisplayedMessage;
            self.selectedMessage = self.messageViewController.message;
        } else {
            // find the index path for the message that was selected
            NSIndexPath *indexPathofSelectedMessage = [self indexPathForMessage:self.selectedMessage];
            if (indexPathofSelectedMessage) {
                // if the selected message is still in the inbox list, select it
                self.selectedIndexPath = indexPathofSelectedMessage;
            } else {
                self.selectedIndexPath = [self validateIndexPath:self.selectedIndexPath];
                if (self.selectedIndexPath) {
                    self.selectedMessage = [self messageAtIndex:self.selectedIndexPath.row];
                } else {
                    self.selectedMessage = nil;
                }
            }
        }
        if (self.selectedIndexPath) {
            // make sure the row we want selected is selected
            self.selectedIndexPath = [self validateIndexPath:self.selectedIndexPath];
            if (!self.editing && !self.collapsed) {
                [self.messageTable selectRowAtIndexPath:self.selectedIndexPath animated:animated scrollPosition:UITableViewScrollPositionNone];
                [self.messageTable scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionNone animated:YES];
            }
        } else {
            // if we want no row selected, de-select row if there is one already selected
            [self deselectCurrentlySelectedIndexPathAnimated:animated];
        }
    } else {
        [self deselectCurrentlySelectedIndexPathAnimated:animated];
        self.selectedMessage = nil;
        self.selectedIndexPath = nil;
    }
}

- (void)deselectCurrentlySelectedIndexPathAnimated:(BOOL)animated {
    NSIndexPath *selectedIndexPath = [self.messageTable indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.messageTable deselectRowAtIndexPath:selectedIndexPath animated:animated];
    }
}

- (NSIndexPath *)validateIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return nil;
    }
    if (self.messages.count == 0) {
        return nil;
    }
    if (indexPath.row >= self.messages.count) {
        return [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:indexPath.section];
    }
    if (indexPath.row < 0) {
        return [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
    }
    return indexPath;
}

- (NSIndexPath *)indexPathForMessage:(UAInboxMessage *)message {
    if (!message) {
        return nil;
    }
    NSUInteger row = [self indexOfMessage:message];
    NSIndexPath *indexPath;
    if (row != NSNotFound) {
        indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    }
    return indexPath;
}

// Called when batch editing begins/ends
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];

    if (editing) {
        self.selectedMessageIDs = [NSMutableArray array];
    } else {
        self.selectedMessageIDs = nil;
    }

    // Set allowsMultipleSelectionDuringEditing to YES only while
    // editing. This allows multi-select AND swipe to delete.
    UITableView *strongMessageTable = self.messageTable;
    strongMessageTable.allowsMultipleSelectionDuringEditing = editing;

    [self.navigationController setToolbarHidden:!editing animated:animated];

    __weak id weakSelf = self;

    // wait until after animation has completed before selecting previously selected row
    if (!editing) {
        if (animated) {
            [CATransaction begin];
            [CATransaction setCompletionBlock: ^{
                // cancel animation has finished
                [weakSelf handlePreviouslySelectedIndexPathsAnimated:NO];
            }];
        }
    }
    [strongMessageTable setEditing:editing animated:animated];
    
    if (!editing) {
        if (animated) {
            [CATransaction commit];
        } else {
            [self handlePreviouslySelectedIndexPathsAnimated:NO];
        }
    }
}

- (void)refreshAfterBatchUpdate {
    // end editing
    self.cancelItem.enabled = YES;
    [self cancelButtonPressed:nil];

    // force button update
    [self refreshBatchUpdateButtons];
}

/**
 * Returns the number of unread messages in the specified set of index paths for the current table view.
 */
- (NSUInteger)countOfUnreadMessagesInIndexPaths:(NSArray *)indexPaths {
    NSUInteger count = 0;
    for (NSIndexPath *path in indexPaths) {
        if ([self messageAtIndex:path.row].unread) {
            ++count;
        }
    }
    return count;
}

- (void)displayMessage:(UAInboxMessage *)message {
    [self displayMessage:message onError:nil];
}

- (void)displayMessage:(UAInboxMessage *)message onError:(void (^)(void))errorCompletion {
    if (message.isExpired) {
        UA_LDEBUG(@"Message expired");
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:UAMessageCenterLocalizedString(@"ua_connection_error")
                                                                       message:UAMessageCenterLocalizedString(@"ua_mc_failed_to_load")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:UAMessageCenterLocalizedString(@"ua_ok")
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  if (errorCompletion) {
                                                                      errorCompletion();
                                                                  }
                                                              }];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        message = nil;
    }
    
    self.selectedMessage = message;
    
    // create a messageViewController if we don't already have one
    if (!self.messageViewController) {
        [self createMessageViewController];
    }
    
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    if ([self.messageViewController isKindOfClass:[UADefaultMessageCenterMessageViewController class]]) {
        ((UADefaultMessageCenterMessageViewController *)self.messageViewController).filter = self.filter;
    }
#pragma GCC diagnostic pop
    
    [self.messageViewController loadMessage:message onlyIfChanged:YES];
    
    [self displayMessageViewController];
}

- (void)displayMessageForID:(NSString *)messageID {

    __weak id weakSelf = self;

    [self displayMessageForID:messageID onError:^{
        UADefaultMessageCenterListViewController *strongSelf = weakSelf;

        [strongSelf.messageTable deselectRowAtIndexPath:self.selectedIndexPath animated:NO];
        strongSelf.selectedMessage = nil;
        strongSelf.selectedIndexPath = nil;
        
        // Hide message view if necessary
        if (strongSelf.collapsed && (strongSelf.messageViewController == strongSelf.navigationController.visibleViewController)) {
            [strongSelf.navigationController popViewControllerAnimated:YES];
        }
    }];
}

- (void)displayMessageForID:(NSString *)messageID onError:(void (^)(void))errorCompletion {
    // See if the message is available on the device
    UAInboxMessage *message = [[UAirship inbox].messageList messageForID:messageID];
    if (message) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [self displayMessage:message onError:errorCompletion];
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        return;
    }

    // message is not available in the device's inbox
    self.selectedIndexPath = nil;

    // create a messageViewController if we don't already have one
    if (!self.messageViewController) {
        [self createMessageViewController];
    }
    
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    if ([self.messageViewController isKindOfClass:[UADefaultMessageCenterMessageViewController class]]) {
        ((UADefaultMessageCenterMessageViewController *)self.messageViewController).filter = self.filter;
    }
#pragma GCC diagnostic pop
    
    [self.messageViewController loadMessageForID:messageID onlyIfChanged:NO onError:errorCompletion];
    
    self.selectedMessage = self.messageViewController.message;

    [self displayMessageViewController];
}

- (void)createMessageViewController {
    // create a messageViewController
    __weak id weakSelf = self;
    void (^closeBlock)(BOOL) = ^(BOOL animated){
        
        UADefaultMessageCenterListViewController *strongSelf = weakSelf;
        
        if (!strongSelf) {
            return;
        }
        // Call the close block if present
        if (strongSelf.closeBlock) {
            strongSelf.closeBlock(animated);
        } else {
            // Fallback to displaying the inbox
            [strongSelf.navigationController popViewControllerAnimated:animated];
        }
    };
    
    if (UAirship.shared.config.useWKWebView) {
        self.messageViewController = [[UAMessageCenterMessageViewController alloc] initWithNibName:@"UAMessageCenterMessageViewController" bundle:[UAirship resources]];
    } else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        self.messageViewController = [[UADefaultMessageCenterMessageViewController alloc] initWithNibName:@"UADefaultMessageCenterMessageViewController" bundle:[UAirship resources]];
#pragma GCC diagnostic pop
    }
    self.messageViewController.closeBlock = closeBlock;
}

- (void)displayMessageViewController {
    // if message view is not already displaying, get it displayed
    if (self.collapsed && (self.messageViewController != self.navigationController.visibleViewController)) {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.messageViewController];

        if (self.style.navigationBarColor) {
            nav.navigationBar.barTintColor = self.style.navigationBarColor;
        }

        // Only apply opaque property if a style is set
        if (self.style) {
            nav.navigationBar.translucent = !self.style.navigationBarOpaque;
        }

        NSMutableDictionary *titleAttributes = [NSMutableDictionary dictionary];

        if (self.style.titleColor) {
            titleAttributes[NSForegroundColorAttributeName] = self.style.titleColor;
        }

        if (self.style.titleFont) {
            titleAttributes[NSFontAttributeName] = self.style.titleFont;
        }

        if (titleAttributes.count) {
            nav.navigationBar.titleTextAttributes = titleAttributes;
        }

        // note: not sure why this is necessary but the navigation controller isn't sized properly otherwise
        [nav.view layoutSubviews];
        [self showDetailViewController:nav sender:self];
    }
}


#pragma mark -
#pragma mark Button Action Methods

- (void)selectAllButtonPressed:(id)sender {

    UITableView *strongMessageTable = self.messageTable;
    NSInteger rows = [strongMessageTable numberOfRowsInSection:0];

    NSIndexPath *currentPath;
    if (strongMessageTable.indexPathsForSelectedRows.count == rows) {
        //everything is selected, so we deselect all
        for (NSInteger i = 0; i < rows; ++i) {
            currentPath = [NSIndexPath indexPathForRow:i inSection:0];
            [strongMessageTable deselectRowAtIndexPath:currentPath
                                              animated:NO];
            [self tableView:strongMessageTable didDeselectRowAtIndexPath:currentPath];
        }
    } else {
        // not everything is selected, so let's select all
        for (NSInteger i = 0; i < rows; ++i) {
            currentPath = [NSIndexPath indexPathForRow:i inSection:0];
            [strongMessageTable selectRowAtIndexPath:currentPath
                                            animated:NO
                                      scrollPosition:UITableViewScrollPositionNone];
            [self tableView:strongMessageTable didSelectRowAtIndexPath:currentPath];
        }
    }
}

- (void)editButtonPressed:(id)sender {

    self.navigationItem.leftBarButtonItem.enabled = NO;

    if ([UAirship inbox].messageList.isBatchUpdating) {
        return;
    }

    self.navigationItem.rightBarButtonItem = self.cancelItem;

    [self setEditing:YES animated:YES];

    // refresh need to be called after setEdit, because in iPad platform,
    // the trash button is decided by the table list's edit status.
    [self refreshBatchUpdateButtons];
}

- (void)cancelButtonPressed:(id)sender {
    self.navigationItem.leftBarButtonItem.enabled = YES;

    self.navigationItem.rightBarButtonItem = self.editItem;

    [self setEditing:NO animated:YES];
}

- (void)batchUpdateButtonPressed:(id)sender {
    NSMutableArray *selectedMessages = [NSMutableArray array];
    
    for (NSString *messageID in self.selectedMessageIDs) {
        // Add message by ID
        UAInboxMessage *selectedMessage = [[UAirship inbox].messageList messageForID:messageID];
        if (selectedMessage) {
            [selectedMessages addObject:selectedMessage];
        }
    }

    self.cancelItem.enabled = NO;

    __weak id weakSelf = self;
    if (sender == self.markAsReadButtonItem) {
        [[UAirship inbox].messageList markMessagesRead:selectedMessages completionHandler:^{
            dispatch_async(dispatch_get_main_queue(),^{
                [weakSelf refreshAfterBatchUpdate];
            });
        }];
    } else {
        [[UAirship inbox].messageList markMessagesDeleted:selectedMessages completionHandler:^{
            dispatch_async(dispatch_get_main_queue(),^{
                [weakSelf refreshAfterBatchUpdate];
            });
        }];
    }
}

- (void)refreshBatchUpdateButtons {
    if (self.editing) {
        NSString *deleteStr = UAMessageCenterLocalizedString(@"ua_delete");
        NSString *markReadStr = UAMessageCenterLocalizedString(@"ua_mark_read");

        UITableView *strongMessageTable = self.messageTable;
        NSUInteger count = strongMessageTable.indexPathsForSelectedRows.count;
        if (!count) {
            self.deleteItem.title = deleteStr;
            self.markAsReadButtonItem.title = markReadStr;
            self.deleteItem.enabled = NO;
            self.markAsReadButtonItem.enabled = NO;

        } else {
            self.deleteItem.title = [NSString stringWithFormat:@"%@ (%lu)", deleteStr, (unsigned long)count];

            NSUInteger unreadCountInSelection = [self countOfUnreadMessagesInIndexPaths:strongMessageTable.indexPathsForSelectedRows];
            self.markAsReadButtonItem.title = [NSString stringWithFormat:@"%@ (%lu)", markReadStr, (unsigned long)unreadCountInSelection];

            if ([UAirship inbox].messageList.isBatchUpdating) {
                self.deleteItem.enabled = NO;
                self.markAsReadButtonItem.enabled = NO;
            } else {
                self.deleteItem.enabled = YES;
                if (unreadCountInSelection) {
                    self.markAsReadButtonItem.enabled = YES;
                } else {
                    self.markAsReadButtonItem.enabled = NO;
                }
            }
        }

        if (strongMessageTable.indexPathsForSelectedRows.count < [strongMessageTable numberOfRowsInSection:0]) {
            self.selectAllButtonItem.title = UAMessageCenterLocalizedString(@"ua_select_all");
        } else {
            self.selectAllButtonItem.title = UAMessageCenterLocalizedString(@"ua_select_none");
        }
    }
}

#pragma mark -
#pragma mark Methods to manage copy of inbox message list

- (void)copyMessages {
    if (self.filter) {
        self.messages = [NSArray arrayWithArray:[[UAirship inbox].messageList.messages filteredArrayUsingPredicate:self.filter]];
    } else {
        self.messages = [NSArray arrayWithArray:[UAirship inbox].messageList.messages];
    }
}

- (UAInboxMessage *)messageAtIndex:(NSUInteger)index {
    if (index < self.messages.count) {
        return [self.messages objectAtIndex:index];
    } else {
        return nil;
    }
}

- (NSUInteger)indexOfMessage:(UAInboxMessage *)messageToFind {
    if (!messageToFind) {
        return NSNotFound;
    }
    
    for (NSUInteger index = 0;index<self.messages.count;index++) {
        UAInboxMessage *message = [self messageAtIndex:index];
        if ([messageToFind.messageID isEqualToString:message.messageID]) {
            return index;
        }
    }
    
    return NSNotFound;
}

- (UAInboxMessage *)messageForID:(NSString *)messageIDToFind {
    if (!messageIDToFind) {
        return nil;
    } else {
        for (UAInboxMessage *message in self.messages) {
            if ([messageIDToFind isEqualToString:message.messageID]) {
                return message;
            }
        }
        return nil;
    }
}

- (void)deleteMessageAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        //require an index path (for safety with literal below)
        return;
    }

    UAInboxMessage *message = [self messageAtIndex:indexPath.row];
    
    if (message) {
        __weak id weakSelf = self;
       [[UAirship inbox].messageList markMessagesDeleted:@[message] completionHandler:^{
           dispatch_async(dispatch_get_main_queue(),^{
               [weakSelf refreshAfterBatchUpdate];
           });
        }];
    }
}

- (UIImage *)placeholderIcon {
    if (self.style.placeholderIcon) {
        return self.style.placeholderIcon;
    }

    if (! _placeholderIcon) {
        _placeholderIcon =[UIImage imageNamed:@"UADefaultMessageCenterPlaceholderIcon.png" inBundle:[UAirship resources] compatibleWithTraitCollection:nil];
    }
    return _placeholderIcon;
}

#pragma mark -
#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSString *nibName = kUADefaultMessageCenterListCellNibName;
    NSBundle *bundle = [UAirship resources];

    UADefaultMessageCenterListCell *cell = (UADefaultMessageCenterListCell *)[tableView dequeueReusableCellWithIdentifier:nibName];

    if (!cell) {
        cell = [[bundle loadNibNamed:nibName owner:nil options:nil] firstObject];
    }

    cell.style = self.style;
    UAInboxMessage *message = [self messageAtIndex:indexPath.row];
    [cell setData:message];

    UIImageView *localImageView = cell.listIconView;
    UITableView *strongMessageTable = self.messageTable;

    if ([self.iconCache objectForKey:[self iconURLStringForMessage:message]]) {
        localImageView.image = [self.iconCache objectForKey:[self iconURLStringForMessage:message]];
    } else {
        if (!strongMessageTable.dragging && !strongMessageTable.decelerating) {
            [self retrieveIconForIndexPath:indexPath iconSize:localImageView.frame.size];
        }

        UIImage *placeholderIcon = self.placeholderIcon;

        CGRect frame = cell.listIconView.frame;

        // If a download is deferred or in progress, set a placeholder image
        localImageView.image = placeholderIcon;

        // Resize to match the original frame if needed
        cell.listIconView.frame = CGRectMake(frame.origin.x, frame.origin.y, CGRectGetWidth(frame), CGRectGetHeight(frame));
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
                                            forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (UITableViewCellEditingStyleDelete == editingStyle) {
        [self deleteMessageAtIndexPath:indexPath];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.messages.count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) {
        return UITableViewCellEditingStyleNone;
    } else {
        if (self.selectedIndexPath) {
            [self.messageTable selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
       return UITableViewCellEditingStyleDelete;
    }
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    if (self.selectedIndexPath) {
        [self.messageTable selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.selectedIndexPath) {
        [self.messageTable selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    UAInboxMessage *message = [self messageAtIndex:indexPath.row];

    if (self.editing) {
        [self.selectedMessageIDs addObject:message.messageID];
        [self refreshBatchUpdateButtons];
    } else {
        self.selectedMessage = message;
        self.selectedIndexPath = indexPath;

        __weak id weakSelf = self;

        [self displayMessage:message onError:^{
            UADefaultMessageCenterListViewController *strongSelf = weakSelf;

            strongSelf.selectedMessage = nil;
            strongSelf.selectedIndexPath = nil;
            [strongSelf.messageTable deselectRowAtIndexPath:indexPath animated:NO];
            [[UAirship inbox].messageList retrieveMessageListWithSuccessBlock:nil withFailureBlock:nil];
        }];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) {
        UAInboxMessage *message = [self messageAtIndex:indexPath.row];
        [self.selectedMessageIDs removeObject:message.messageID];
        [self refreshBatchUpdateButtons];
    }
}

#pragma mark -
#pragma mark NSNotificationCenter callbacks

- (void)messageListUpdated {
    __weak id weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        UADefaultMessageCenterListViewController *strongSelf = weakSelf;

        // copy the back-end list of messages as it can change from under the UI
        [strongSelf copyMessages];
        
        if (!strongSelf.refreshControlAnimating) {
            [strongSelf chooseMessageDisplayAndReload];
        }
    });
}

- (void)chooseMessageDisplayAndReload {
    if (self.messageViewController.message) {
        // Default is to show the message that was already displayed
        UAInboxMessage *messageToDisplay = [self messageForID:self.messageViewController.message.messageID];
        
        // if the previously displayed message no longer exists, try to show the message that was previously selected
        if (!messageToDisplay && self.selectedMessage) {
            messageToDisplay = [self messageForID:self.selectedMessage.messageID];
        }
        
        // if that message no longer exists, try to show the message now at the previously selected index
        if (!messageToDisplay && self.selectedIndexPath) {
            messageToDisplay = [self messageForID:[self messageAtIndex:[self validateIndexPath:self.selectedIndexPath].row].messageID];
        }
        [self.messageViewController loadMessage:messageToDisplay onlyIfChanged:YES];
        
        self.selectedMessage = messageToDisplay;
        
        if (!messageToDisplay) {
            if (self.collapsed && (self.messageViewController == self.navigationController.visibleViewController)) {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
    }
    
    [self reload];
    [self refreshBatchUpdateButtons];
}

#pragma mark -
#pragma mark List Icon Loading (UIScrollViewDelegate)

// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self retrieveImagesForOnscreenRows];
    }
}

// Compute the eventual resting view bounds (r), and retrieve images for those cells
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {

    CGRect r;
    r.origin = *targetContentOffset;
    r.size = self.view.bounds.size;

    NSArray *indexPaths = [self.messageTable indexPathsForRowsInRect:r];
    for (NSIndexPath *indexPath in indexPaths) {
        UITableViewCell *cell = [self.messageTable cellForRowAtIndexPath:indexPath];
        UA_LTRACE(@"Loading row %ld. Title: %@", (long)indexPath.row, [self messageAtIndex:indexPath.row].title);
        [self retrieveIconForIndexPath:indexPath iconSize:cell.imageView.frame.size];
    }
}

// Load the images when deceleration completes (though the end dragging should try to fetch these first)
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self retrieveImagesForOnscreenRows];
}

// A tap on the status bar will force a scroll to the top
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self retrieveImagesForOnscreenRows];
}

#pragma mark - UISplitViewControllerDelegate

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    // Only collapse onto the primary (list) controller if there's no currently selected message or we're in batch editing mode
    return !(self.selectedIndexPath || self.selectedMessage) || self.editing;
}

- (UIViewController *)primaryViewControllerForExpandingSplitViewController:(UISplitViewController *)splitViewController {
    self.collapsed = NO;
    // Delay selection by a beat, to allow rotation to finish

    __weak id weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf handlePreviouslySelectedIndexPathsAnimated:YES];
    });
    // Returning nil causes the split view controller to default to the the existing primary view controller
    return nil;
}

- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController {
    self.collapsed = YES;
    // Returning nil causes the split view controller to default to the the existing secondary view controller
    return nil;
}

#pragma mark - List Icon Load + Fetch

/**
 * Scales a source image to the provided size.
 */
- (UIImage *)scaleImage:(UIImage *)source toSize:(CGSize)size {

    CGFloat sourceWidth = source.size.width;
    CGFloat sourceHeight = source.size.height;

    CGFloat widthFactor = size.width / sourceWidth;
    CGFloat heightFactor = size.height / sourceHeight;
    CGFloat maxFactor = MAX(widthFactor, heightFactor);

    CGFloat scaledWidth = truncf(sourceWidth * maxFactor);
    CGFloat scaledHeight = truncf(sourceHeight * maxFactor);

    CGAffineTransform transform = CGAffineTransformMakeScale(maxFactor, maxFactor);
    CGSize transformSize = CGSizeApplyAffineTransform(source.size, transform);

    // Note: passing 0.0 causes the function below to use the scale factor of the main screen
    CGFloat transformScaleFactor = 0.0;

    UIGraphicsBeginImageContextWithOptions(transformSize, NO, transformScaleFactor);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);

    [source drawInRect:CGRectMake(0, 0, scaledWidth, scaledHeight)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return scaledImage;
}

/**
 * Retrieve the list view icon for all the currently visible index paths.
 */
- (void)retrieveImagesForOnscreenRows {
    NSArray *visiblePaths = [self.messageTable indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths) {
        UITableViewCell *cell = [self.messageTable cellForRowAtIndexPath:indexPath];
        [self retrieveIconForIndexPath:indexPath iconSize:cell.imageView.frame.size];
    }
}

/**
 * Retrieves the list view icon for a given index path, if available.
 */
- (void)retrieveIconForIndexPath:(NSIndexPath *)indexPath iconSize:(CGSize)iconSize {

    UAInboxMessage *message = [self messageAtIndex:indexPath.row];

    NSString *iconListURLString = [self iconURLStringForMessage:message];

    if (!iconListURLString) {
        // Nothing to do here
        return;
    }

    // If the icon isn't already in the cache
    if (![self.iconCache objectForKey:iconListURLString]) {

        NSURL *iconListURL = [NSURL URLWithString:iconListURLString];

        // Tell the cache to remember the URL
        [UAURLProtocol addCachableURL:iconListURL];

        // NOTE: All add/remove operations on the cache & in-progress set should be done
        // on the main thread. They'll be cleared below in a dispatch_async/main queue block.

        // Next, check to see if we're currently requesting the icon
        // Add the index path to the set of paths to update when a request is completed and then proceed if necessary
        NSMutableSet *currentRequestedIndexPaths = [self.currentIconURLRequests objectForKey:iconListURLString];
        if (currentRequestedIndexPaths.count) {
            [currentRequestedIndexPaths addObject:indexPath];
            // Wait for the in-flight request to finish
            return;
        } else {
            // No in-flight request. Add and continue.
            [self.currentIconURLRequests setValue:[NSMutableSet setWithObject:indexPath] forKey:iconListURLString];
        }

        __weak UADefaultMessageCenterListViewController *weakSelf = self;
        dispatch_async(self.iconFetchQueue, ^{

            UA_LTRACE(@"Fetching RP Icon: %@", iconListURLString);

            // Note: this decodes the source image at full size
            NSData *iconImageData = [NSData dataWithContentsOfURL:iconListURL];
            UIImage *iconImage = [UIImage imageWithData:iconImageData];
            iconImage = [weakSelf scaleImage:iconImage toSize:iconSize];

            dispatch_async(dispatch_get_main_queue(), ^{
                // Recapture self for the duration of this block
                UADefaultMessageCenterListViewController *strongSelf = weakSelf;

                // Place the icon image in the cache and reload the row
                if (iconImage) {

                    NSUInteger sizeInBytes = CGImageGetHeight(iconImage.CGImage) * CGImageGetBytesPerRow(iconImage.CGImage);

                    [strongSelf.iconCache setObject:iconImage forKey:iconListURLString];
                    UA_LTRACE(@"Added image to cache (%@) with size in bytes: %lu", iconListURL, (unsigned long)sizeInBytes);

                    // Update cells directly rather than forcing a reload (which deselects)
                    UADefaultMessageCenterListCell *cell;
                    for (NSIndexPath *indexPath in (NSSet *)[strongSelf.currentIconURLRequests objectForKey:iconListURLString]) {
                        cell = (UADefaultMessageCenterListCell *)[strongSelf.messageTable cellForRowAtIndexPath:indexPath];
                        cell.listIconView.image = iconImage;
                    }
                }
                
                // Clear the request marker
                [strongSelf.currentIconURLRequests removeObjectForKey:iconListURLString];
            });
        });
    }
}

/**
 * Returns the URL for a given message's list view icon (or nil if not set).
 */
- (NSString *)iconURLStringForMessage:(UAInboxMessage *) message {
    NSDictionary *icons = [message.rawMessageObject objectForKey:@"icons"];
    return [icons objectForKey:@"list_icon"];
}

@end
