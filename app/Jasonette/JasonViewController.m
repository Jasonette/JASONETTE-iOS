//
//  JasonViewController.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonViewController.h"

@interface JasonViewController ()
{
    NSInteger selectedIndex;
    NSMutableArray *rowcount;
    NSMutableArray *headers;
//    NSMutableArray *layers;
    NSString *search_url;
    NSString *search_field_name;
    NSString *back_url;
    UIImage *placeholder_image;
    NSDictionary *tabs;
    NSDictionary *search_action;
    NSDictionary *chat_input;
    NSMutableArray *toolbarActions;
    NSMutableDictionary *indexPathsForImage;
    UIImageView *backgroundImageView;
    NSArray *raw_sections;
    PHFComposeBarView *composeBarView;
    CGFloat keyboardSize;
    NSInteger download_image_counter;
    BOOL isEditing;
    BOOL isSearching;
    BOOL hasError;
    BOOL top_aligned;
    NSMutableDictionary *estimatedRowHeightCache;
    UIView *empty_view;
    CGFloat original_height;
    CGFloat original_bottom_inset;
    BOOL need_to_adjust_frame;
    UIView *currently_focused;
    #ifdef ADS
    NSTimer *intrestialAdTimer;
    #endif
}
@end

@implementation JasonViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    original_height = self.view.frame.size.height;
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    [self.view addSubview:self.tableView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"H:|[tableView]|" options:0 metrics:nil views:@{@"tableView": self.tableView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"V:|[tableView]|" options:0 metrics:nil views:@{@"tableView": self.tableView}]];

    if(self.url){
        NSString *normalized_url = [JasonHelper normalized_url:self.url forOptions:self.options];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:normalized_url];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
        if(!fileExists){
            [[Jason client] loadViewByFile: @"file://loading.json" asFinal:NO];
        }
    } else {
        [[Jason client] loadViewByFile: @"file://loading.json" asFinal:NO];
    }
    empty_view = [[UIView alloc] initWithFrame:CGRectZero];

    estimatedRowHeightCache = [[NSMutableDictionary alloc] init];
    
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    // Avoid gray background
    self.tableView.backgroundView = [UIView new];

    self.tableView.estimatedRowHeight = 30.0;
    self.tableView.estimatedSectionHeaderHeight = 30.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" " style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    [self.tableView setSeparatorColor:[JasonHelper colorwithHexString:@"#f5f5f5" alpha:1.0]];
    rowcount = [[NSMutableArray alloc] init];
    selectedIndex = 0;
    isEditing = NO;
    keyboardSize = 0;
    
    self.contentLoaded = NO;
    self.style = [[NSDictionary alloc] init];
    self.events = [[NSMutableDictionary alloc] init];
    self.action_callback= [[NSMutableDictionary alloc] init];
    self.callback = [[NSDictionary alloc] init];
    self.sections = [[NSMutableArray alloc] init];
    self.rows = [[NSArray alloc] init];
    
    self.form = [[NSMutableDictionary alloc] init];
    self.requires = [[NSMutableDictionary alloc] init];
    self.tableView.delaysContentTouches = false;

    self.automaticallyAdjustsScrollViewInsets = YES;
    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"finishRefreshing" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishRefreshing) name:@"finishRefreshing" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"focusSearch" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusSearch) name:@"focusSearch" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"blur" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blur) name:@"blur" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"updateForm" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateForm:) name:@"updateForm" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"setupIndexPathsForImage" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupIndexPathsForImage:) name:@"setupIndexPathsForImage" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide) name:UIKeyboardDidHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"unlock" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unlock) name:@"unlock" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"scrollToBottom" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollToBottom) name:@"scrollToBottom" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"scrollToTop" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollToTop) name:@"scrollToTop" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"adjustViewForKeyboard" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustViewForKeyboard:) name:@"adjustViewForKeyboard" object:nil];
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
}
- (void)adjustViewForKeyboard:(NSNotification *)notification{
    currently_focused = notification.userInfo[@"view"];
    need_to_adjust_frame = YES;
}
- (void)updateForm:(NSNotification *)notification {
    NSDictionary *kv = notification.userInfo;
    for(NSString *key in kv){
        self.form[key] = kv[key];
    }
}
- (void)setupIndexPathsForImage:(NSNotification *)notification {
    NSString *url = notification.userInfo[@"url"];
    NSIndexPath *indexPath = notification.userInfo[@"indexPath"];
    if(indexPathsForImage[url]){
        [(NSMutableSet*)indexPathsForImage[url] addObject:indexPath];
    } else {
        indexPathsForImage[url] = [[NSMutableSet alloc] initWithObjects:indexPath, nil];
    }
}

- (void)unlock{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated: YES];
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [Jason client].touching = YES;
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [Jason client].touching = NO;
}
- (void)blur{
    if(self.searchController){
        if(self.searchController.isActive){
            [self.searchController setActive:NO];
        }
    }
    [self.view endEditing:YES];
}

// Handling text input from footer.input
- (void)textViewDidChange:(UITextView *)textView
{
    if(textView.payload && textView.payload[@"name"]){
        self.form[textView.payload[@"name"]] = textView.text;
    }
}

// Handling the updated frame when keyboard shows up
- (void)keyboardDidHide{
    
    #ifdef ADS
        [self adjustBannerPosition];
    #endif
    isEditing = NO;
}
- (void)keyboardDidShow:(NSNotification *)notification {
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    if(need_to_adjust_frame){
        // Only for 'textarea' type
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, kbSize.height, self.tableView.contentInset.right);
        self.tableView.contentInset = contentInsets;
        self.tableView.scrollIndicatorInsets = contentInsets;
        
        if(!isEditing){
            CGRect aRect = self.view.frame;
            aRect.size.height -= kbSize.height;
            CGRect currently_focused_frame = [currently_focused convertRect:currently_focused.bounds toView:self.tableView];
            if(!CGRectContainsRect(aRect, currently_focused_frame)){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView scrollRectToVisible:currently_focused_frame animated:YES];
                });
            }
        }
    }
    else {
        if(!top_aligned){
            [self scrollToBottom];
        }
    }
#ifdef ADS
    [self adjustBannerPosition];
#endif
    isEditing = YES;
    
}
- (void)keyboardWillHide:(NSNotification *)notification {
    if(need_to_adjust_frame){
        need_to_adjust_frame = NO;
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, original_bottom_inset, self.tableView.contentInset.right);
        self.tableView.contentInset = contentInsets;
        self.tableView.scrollIndicatorInsets = contentInsets;
    }
}


- (BOOL)prefersStatusBarHidden {
    return self.navigationController.isNavigationBarHidden;
}

- (void)viewDidLayoutSubviews
{
    // fix for iOS7 bug in UITabBarController
    self.extendedLayoutIncludesOpaqueBars = YES;
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    hasError = NO;
    self.playing = [[NSMutableArray alloc] init];
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    if(self.searchController){
        self.tableView.tableHeaderView = self.searchController.searchBar;
    }
    [[Jason client] attach:self];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[Jason client] detach:self];
}


#pragma mark - Header Cell
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSDictionary *header = [headers objectAtIndex:section];
    if(header && [header count] > 0){
        if(header[@"type"]){
            if([header[@"type"] isEqualToString:@"tab"]){
                header = [JasonComponentFactory applyStylesheet:header];
                if(header[@"style"] && header[@"style"][@"height"]){
                    NSString *height = header[@"style"][@"height"];
                    return [JasonHelper pixelsInDirection:@"vertical" fromExpression:height];
                }
                return 40.0f;
            } else {
                header = [JasonComponentFactory applyStylesheet:header];
                if(header[@"style"] && header[@"style"][@"height"]){
                    return [JasonHelper pixelsInDirection:@"vertical" fromExpression:header[@"style"][@"height"]];
                }
            }
            return UITableViewAutomaticDimension;
        } else {
            return 30.0;
        }
    } else {
        return 0.0;
    }
}
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1000000 inSection:section];
    CGFloat f = [self getEstimatedHeight:indexPath defaultHeight:60.0f];
    return f;
}


- (JasonHorizontalSection *)getHorizontalSectionItem:(NSDictionary *)row forTableView: (UITableView *)tableView atIndexPath: (NSIndexPath *)indexPath{
    JasonHorizontalSection *cell = [tableView dequeueReusableCellWithIdentifier:@"JasonHorizontalSection"];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"JasonHorizontalSection" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    NSMutableDictionary *style;
    if(row[@"style"]){
        style = [row[@"style"] mutableCopy];
    } else {
        style = [@{} mutableCopy];
    }
    
    
    NSArray *items = row[@"items"];
    
    
    // Find height of this section by looking at heights of the children
    // Find the max value
    float max_height = 0;
    for(int i = 0 ; i < items.count ; i++){
        NSDictionary *item = [JasonComponentFactory applyStylesheet:items[i]];
        NSDictionary *item_style = item[@"style"];
        if(item_style){
            NSString *height = item_style[@"height"];
            if(height){
                CGFloat fl_height = [JasonHelper pixelsInDirection:@"vertical" fromExpression:height];
                if(fl_height > max_height){
                    max_height = fl_height;
                }
            }
        }
    }
    
    [cell setItems:items];
    [cell setStyle:style];
    [cell setStylesheet:self.style];
    
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *) cell.collectionView.collectionViewLayout;
    if(style[@"spacing"]){
        flowLayout.minimumInteritemSpacing = [JasonHelper pixelsInDirection:@"horizontal" fromExpression:style[@"spacing"]];
        flowLayout.minimumLineSpacing =  [JasonHelper pixelsInDirection:@"horizontal" fromExpression:style[@"spacing"]];
    }
    
    // Padding Handling
    NSString *padding_left;
    NSString *padding_right;
    NSString *padding_top;
    NSString *padding_bottom;
    if(style[@"padding"]){
        NSString *padding = style[@"padding"];
        padding_left = padding;
        padding_top = padding;
        padding_right = padding;
        padding_bottom = padding;
    }

    if(style[@"padding_left"]) padding_left = style[@"padding_left"];
    if(style[@"padding_right"]) padding_right = style[@"padding_right"];
    if(style[@"padding_top"]) padding_top = style[@"padding_top"];
    if(style[@"padding_bottom"]) padding_bottom = style[@"padding_bottom"];
    
    cell.collectionView.contentInset = UIEdgeInsetsMake([JasonHelper pixelsInDirection:@"vertical" fromExpression:padding_top], [JasonHelper pixelsInDirection:@"horizontal" fromExpression:padding_left], [JasonHelper pixelsInDirection:@"vertical" fromExpression:padding_bottom], [JasonHelper pixelsInDirection:@"horizontal" fromExpression:padding_right]);


    
    cell.tintColor = [JasonHelper colorwithHexString:style[@"color"] alpha:1.0];
    cell.accessoryView.tintColor = cell.tintColor;
    
    
    if(style[@"background"]){
        cell.backgroundColor = [JasonHelper colorwithHexString:style[@"background"] alpha:1.0];
    } else {
        cell.backgroundColor = [UIColor clearColor];
    }
    
    [cell.contentView setNeedsLayout];
    [cell.contentView layoutIfNeeded];
    
    if (![self estimatedHeightExists:indexPath]) {
        if(max_height && max_height > 0){
            [self setEstimatedHeight:indexPath height:max_height];
        }
    }
   return cell;
}
-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSDictionary *header = [headers objectAtIndex:section];
    
    // Faux indexpath just for caching height
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1000000 inSection:section];
    
    if(header && [header count] > 0){
        static NSString *headerIdentifier = @"HeaderCell";
        NSString *type = header[@"type"];
        if(type && [type isEqualToString:@"tabs"]){
            SWTableViewCell *cell = (SWTableViewCell *)[tableView dequeueReusableCellWithIdentifier:headerIdentifier];
            if(cell == nil){
                cell = [[SWTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:headerIdentifier];
            }
            // Segmented Controller
            NSArray *buttons = header[@"items"];
            NSMutableArray *button_names = [[NSMutableArray alloc] init];
            for(NSDictionary *button in buttons){
                [button_names addObject:button[@"text"]];
            }
            HMSegmentedControl *segmentedControl = [[HMSegmentedControl alloc] initWithSectionTitles:button_names];
            
            
            NSInteger tabs_height = cell.frame.size.height;
            UIColor *tabs_selection_color = nil;
            UIColor *tabs_background_color = nil;
            UIColor *tabs_foreground_color = nil;
            
            header = [JasonComponentFactory applyStylesheet: header];
            NSDictionary *style = header[@"style"];
            
            if(style){
                if(style[@"height"]){
                    NSString *height = style[@"height"];
                    tabs_height = [JasonHelper pixelsInDirection:@"vertical" fromExpression:height];
                }
                if(style[@"tintColor"]){   // deprecated. use tint_color
                    tabs_selection_color = [JasonHelper colorwithHexString:style[@"tintColor"] alpha:1.0];
                }
                if(style[@"tint_color"]){
                    tabs_selection_color = [JasonHelper colorwithHexString:style[@"tint_color"] alpha:1.0];
                }
                if(style[@"background"]){
                    tabs_background_color = [JasonHelper colorwithHexString:style[@"background"] alpha:1.0];
                }
                if(style[@"color"]){
                    tabs_foreground_color = [JasonHelper colorwithHexString:style[@"color"] alpha:1.0];
                }
            }
            segmentedControl.frame = CGRectMake(0, 0, self.view.frame.size.width, tabs_height);
            if(tabs_selection_color){
                segmentedControl.selectionIndicatorColor = tabs_selection_color;
            }
            if(tabs_background_color){
                segmentedControl.backgroundColor = tabs_background_color;
            }
            if(tabs_foreground_color){
                segmentedControl.titleTextAttributes = @{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:12.0], NSForegroundColorAttributeName: tabs_foreground_color};
            } else {
                segmentedControl.titleTextAttributes = @{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:12.0]};
            }
            
            segmentedControl.selectedSegmentIndex = selectedIndex;
            segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
            segmentedControl.tag = section;
            [segmentedControl addTarget:self action:@selector(segmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
            [cell addSubview:segmentedControl];
            
            [cell.contentView setNeedsLayout];
            [cell.contentView layoutIfNeeded];
            if (![self estimatedHeightExists:indexPath]) {
                CGSize cellSize = [cell systemLayoutSizeFittingSize:CGSizeMake(self.view.frame.size.width, 0) withHorizontalFittingPriority:1000.0 verticalFittingPriority:50.0];
                [self setEstimatedHeight:indexPath height:cellSize.height];
            }
            return cell;
        } else {
            SWTableViewCell *cell = (SWTableViewCell *)[self getVerticalSectionItem:header forTableView:tableView atIndexPath:indexPath];
            return cell;
        }
    }
    return nil;
}
- (void)segmentedControlChangedValue:(HMSegmentedControl *)segmentedControl {

    NSDictionary *header = [headers objectAtIndex:segmentedControl.tag];
    NSArray *buttons = header[@"items"];
    selectedIndex = (long)segmentedControl.selectedSegmentIndex;
    NSDictionary *button = [buttons objectAtIndex:selectedIndex];
    if(button[@"url"]){
        self.url = button[@"url"];
        [[Jason client] reload];
    }
}
#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([cell respondsToSelector:@selector(setSeparatorInset:)] && [cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)] && [cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
        [cell setPreservesSuperviewLayoutMargins:NO];
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (BOOL)isHorizontal:(NSDictionary *)s{
    NSString *type = s[@"type"];
    return (type && [type isEqualToString:@"horizontal"]);
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *s = [self.sections objectAtIndex:section];
    if([self isHorizontal: s]){
        return 1;
    } else {
        return [[rowcount objectAtIndex:section] integerValue];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @try {
        NSDictionary *s = [self.sections objectAtIndex:indexPath.section];
        NSArray *rows = s[@"items"];
        if([self isHorizontal: s]){
            
            return [self getHorizontalSectionItem:s forTableView:tableView atIndexPath:indexPath];
        } else {
            NSDictionary *item = [rows objectAtIndex:indexPath.row];
            return [self getVerticalSectionItem:item forTableView:tableView atIndexPath:indexPath];
        }
    }
    @catch (NSException *e){
        NSDictionary *item = @{
               @"type": @"vertical",
               @"style": @{
                       @"spacing": @"5"
               },
               @"components": @[
                  @{
                      @"type": @"label",
                      @"text": @"Error",
                      @"style": @{ @"size": @"30", @"align": @"center", @"padding": @"10" }
                  }, @{
                    @"type": @"label",
                    @"text": @"Something went wrong.",
                    @"style": @{ @"size": @"12", @"align": @"center", @"padding": @"10" }
                  }
              ]
          };
        hasError = YES;
        return [self getVerticalSectionItem:item forTableView:tableView atIndexPath:indexPath];
    }
}


/********************************
 * Helper
 ********************************/


- (UITableViewCell*)getVerticalSectionItem:(NSDictionary *)item forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath{

    // "signature" => generate a unique signature to identify prototype items.
    NSString *signature = [JasonHelper getSignature:item];
    item = [JasonComponentFactory applyStylesheet: item];
    
    SWTableViewCell *cell = (SWTableViewCell *)[tableView dequeueReusableCellWithIdentifier:signature];
    UIStackView *layout;
    if (cell == nil)
    {
        cell = [[SWTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:signature];
        layout = [[UIStackView alloc] init];
        [cell.contentView addSubview:layout];

        NSString *horizontal_vfl = [NSString stringWithFormat:@"|-0@%f-[layout]-0@%f-|", UILayoutPriorityRequired, UILayoutPriorityRequired];
        NSString *vertical_vfl = [NSString stringWithFormat:@"V:|-0@%f-[layout]-0@%f-|", UILayoutPriorityRequired, UILayoutPriorityRequired];
        [cell.contentView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:horizontal_vfl options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"layout": layout}]];
        [cell.contentView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:vertical_vfl options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"layout": layout}]];
    } else {
        layout = cell.contentView.subviews.firstObject;
    }
    NSDictionary *layout_generator = [JasonLayout fill:layout with:item atIndexPath:indexPath withForm:self.form];

    // Build layout and add to cell
    NSMutableDictionary *style = layout_generator[@"style"];

    // Z-index handling
    if(style[@"z_index"]){
        int z = [style[@"z_index"] intValue];
        cell.layer.transform = CATransform3DMakeTranslation(0, 0, z);
    } else {
        cell.layer.transform = CATransform3DMakeTranslation(0, 0, 0);
    }
    
    // Background Color / Color handling
    // Currently background only at cell level (layouts don't have background)
    if(style[@"background"]){
        if([style[@"background"] hasPrefix:@"http"]){
            CGFloat h = [JasonHelper pixelsInDirection:@"vertical" fromExpression:style[@"height"]];
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,cell.frame.size.width, h)];
            cell.backgroundView = imageView;
            cell.backgroundView.backgroundColor = [UIColor clearColor];
            cell.backgroundView.opaque = NO;
            [imageView sd_setImageWithURL:[NSURL URLWithString:style[@"background"]] placeholderImage:placeholder_image completed:^(UIImage *i, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            }];
        } else {
            cell.backgroundColor = [JasonHelper colorwithHexString:style[@"background"] alpha:1.0];
        }
    } else {
        cell.backgroundColor = [UIColor clearColor];
    }
    
    
    // TableView-specific logic
    if(style[@"color"]){
        cell.tintColor = nil;
        cell.accessoryView.tintColor = nil;
        cell.tintColor = [JasonHelper colorwithHexString:style[@"color"] alpha:1.0];
        cell.accessoryView.tintColor = cell.tintColor;
    }
    if(item[@"href"]){
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        UIImage *disclosureImage = [UIImage imageNamed:@"Next"];
        disclosureImage = [JasonHelper colorize:disclosureImage into:cell.tintColor];
        disclosureImage = [JasonHelper scaleImage:disclosureImage ToSize:CGSizeMake(8,13)];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,8,13)];
        [imageView setImage:disclosureImage];
        cell.accessoryView = imageView;
        cell.accessoryView.layer.transform = CATransform3DMakeTranslation(0, 0, -1);
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        UIView *b = [[UIView alloc] init];
        b.backgroundColor = [JasonHelper darkerColorForColor:cell.backgroundColor];
        cell.selectedBackgroundView = b;
    } else if(item[@"action"]){
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        UIView *b = [[UIView alloc] init];
        b.backgroundColor = [JasonHelper darkerColorForColor:cell.backgroundColor];
        cell.selectedBackgroundView = b;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    if(item[@"menu"]){
        if(item[@"menu"][@"trigger"]){
            cell.rightUtilityButtons = [self rightButtons:item[@"menu"]];
            cell.delegate = self;
        } else if(item[@"menu"][@"items"]){
            if([item[@"menu"][@"items"] count] > 0){
                cell.rightUtilityButtons = [self rightButtons:item[@"menu"]];
                cell.delegate = self;
            }
        }
    }
    
    [cell.contentView setNeedsLayout];
    [cell.contentView layoutIfNeeded];
    
    
    if(indexPath){
        if (![self estimatedHeightExists:indexPath]) {
            CGSize cellSize = [cell systemLayoutSizeFittingSize:CGSizeMake(self.view.frame.size.width, 0) withHorizontalFittingPriority:1000.0 verticalFittingPriority:50.0];
            [self setEstimatedHeight:indexPath height:cellSize.height];
        }
    }
    return cell;
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *section = [self.sections objectAtIndex:indexPath.section];
    if([self isHorizontal: section]){
        @try{
            if([section[@"items"] count] > 0){
                // if the row has a style, honor that first.
                // If not, look to see if it has a class, if it does, look it up on style object
                section = [JasonComponentFactory applyStylesheet: section];
                NSDictionary *style = section[@"style"];
                if(style && style[@"height"]){
                    return [JasonHelper pixelsInDirection:@"vertical" fromExpression:style[@"height"]];
                }
                
                
                // Find height of this section by looking at heights of the children
                // Find the max value
                float max_height = 0;
                NSArray *items = section[@"items"];
                for(int i = 0 ; i < items.count ; i++){
                    NSDictionary *it = [JasonComponentFactory applyStylesheet: items[i]];
                    NSDictionary *it_style = it[@"style"];
                    if(it_style){
                        NSString *height = it_style[@"height"];
                        if(height){
                            CGFloat fl_height = [JasonHelper pixelsInDirection:@"vertical" fromExpression:height];
                            if(fl_height > max_height){
                                max_height = fl_height;
                            }
                        }
                    }
                }
                if(max_height > 0){
                    return max_height;
                } else {
                    return UITableViewAutomaticDimension;
                }
            } else {
                return 0.0f;
            }
        }
        @catch(NSException *e){
            hasError = YES;
            return UITableViewAutomaticDimension;
        }
    } else {
        @try{
            NSArray *rows = [[self.sections objectAtIndex:indexPath.section] valueForKey:@"items"];
            if(rows){
                NSDictionary *item = [rows objectAtIndex:indexPath.row];
                item = [JasonComponentFactory applyStylesheet:item];
                NSDictionary *style = item[@"style"];
                if(style && style[@"height"]){
                    return [JasonHelper pixelsInDirection:@"vertical" fromExpression:style[@"height"]];
                }
            } else {
                return 0.0f;
            }
        }
        @catch(NSException *e){
            hasError = YES;
            return UITableViewAutomaticDimension;
        }
    }
    return UITableViewAutomaticDimension;
}
-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    @try{
        NSDictionary *s = [self.sections objectAtIndex:indexPath.section];
        if([self isHorizontal: s]){
            NSDictionary *style = s[@"style"];
            if(style){
                if(style[@"height"]){
                    return [JasonHelper pixelsInDirection:@"vertical" fromExpression:style[@"height"]];
                }
            }
            return 100.0f;
        } else {
            return [self getEstimatedHeight:indexPath defaultHeight:60.0f];
        }
    }
    @catch(NSException *e){
        hasError = YES;
        return 100.0f;
    }
    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If Search Mode
    //   Go
    // Else
    //   If Editing
    //     Get rid of focus
    //   Else
    //     Go
    
    // IF it has error don't respond to events
    if(hasError){
        return;
    }
    
    if(isEditing && self.searchController.dimsBackgroundDuringPresentation){
        [self.view endEditing:YES];
        [self.tableView reloadData];
    } else {
        [self.view endEditing:YES];
        NSArray *rows = [[self.sections objectAtIndex:indexPath.section] valueForKey:@"items"];
        NSDictionary *item = [rows objectAtIndex:indexPath.row];
        
        if(item[@"action"]){
            NSMutableDictionary *action = [item[@"action"] mutableCopy];
            @try{
                NSMutableDictionary *options;
                if(action[@"options"] && [action[@"options"] count] > 0){
                    options = [action[@"options"] mutableCopy];
                } else {
                    options = [[NSMutableDictionary alloc] init];
                }
                action[@"options"] = options;
            }
            @catch(NSException *e){
                [action removeObjectForKey:@"options"];
            }
            [[Jason client] call:action];
        } else if (item[@"href"]){
            NSMutableDictionary *href = [item[@"href"] mutableCopy];
            @try{
                NSMutableDictionary *options;
                if(href[@"options"] && [href[@"options"] count] > 0){
                    options = [href[@"options"] mutableCopy];
                    href[@"options"] = options;
                }
            }
            @catch(NSException *e){
                [href removeObjectForKey:@"options"];
            }
            [[Jason client] go:href];
        } else {
            // Do nothing
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissSearchInput" object:nil];
}





#pragma mark - UISearchController
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    
    [self scan];

}
- (void)scan{
    NSString *query = [NSString stringWithFormat:@"\"text\":\".*%@.*\"", self.searchController.searchBar.text];
    NSError  *error = nil;
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern: query options:NSRegularExpressionCaseInsensitive error:&error];

    NSMutableArray *search_results = [[NSMutableArray alloc] init];
    NSError *err;
    for(int i = 0 ; i < raw_sections.count ; i++){
        NSMutableDictionary *section = [raw_sections[i] mutableCopy];
        NSMutableArray *new_items = [[NSMutableArray alloc] init];
        if([section[@"items"] isKindOfClass:[NSArray class]]){
            for(int j = 0 ; j < [section[@"items"] count] ; j++){
                NSDictionary *item = section[@"items"][j];
                [item description];
                NSData * jsonData = [NSJSONSerialization dataWithJSONObject:item options:0 error:&err];
                NSString * str = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

                NSArray* matches = [regex matchesInString:str options:0 range: NSMakeRange(0, str.length)];
                if(matches && matches.count > 0){
                    [new_items addObject:item];
                }
            }
        }
        section[@"items"] = new_items;
        [search_results addObject:section];
    }
    [self reloadSections: search_results];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    self.searchController.searchBar.text = @"";
    [[Jason client] reload];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [self search:searchBar.text];
}
- (void)search:(NSString*)text{
    if(self.searchController){
        NSString *searchString = text;
        self.form[search_field_name] = searchString;
        self.searchController.active = NO;
        [[Jason client] call:search_action];
    }
}
- (void)focusSearch{
    if(self.searchController){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.searchController.searchBar becomeFirstResponder];
        });
    }
}

- (NSDictionary *)clean:(NSDictionary *)body{
    NSArray *keys = [body allKeys];
    NSMutableDictionary *newBody = [[NSMutableDictionary alloc] init];
    for(NSString *key in keys){
        if([key isEqualToString:@"$ignore"]){
            
        } else {
            if([body[key] isKindOfClass:[NSArray class]]){
                newBody[key] = [self cleanArray:body[key]];
            } else if ([body[key] isKindOfClass:[NSDictionary class]]){
                newBody[key] = [self clean:body[key]];
            } else {
                newBody[key] = body[key];
            }
        }
    }
    return newBody;
}

- (NSArray *)cleanArray:(NSArray*)arr{
    NSMutableArray *newArray = [[NSMutableArray alloc] init];
    for(int i = 0 ; i < arr.count ; i++){
        if([arr[i] isKindOfClass:[NSArray class]]){
            // Array
            [newArray addObject:[self cleanArray:arr[i]]];
        } else if ([arr[i] isKindOfClass:[NSDictionary class]]){
            // Object
            [newArray addObject:[self clean:arr[i]]];
        } else {
            // String
            [newArray addObject:arr[i]];
        }
    }
    return newArray;
}

- (void)loadAssets: (NSDictionary *)body{
    JasonViewController* weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    
        NSArray *keys = [body allKeys];
        for(NSString *key in keys){
            if([body[key] isKindOfClass:[NSArray class]]){
                // Array => Array traversal
                NSArray *children = (NSArray *)body[key];
                for(int i = 0 ; i < children.count ; i++){
                    if([children[i] isKindOfClass:[NSDictionary class]] || [children[i] isKindOfClass:[NSArray class]]){
                        [self loadAssets:children[i]];
                    } else {
                        [self loadAssets:@{@"string": children[i]}];
                    }
                }
            } else if([body[key] isKindOfClass:[NSDictionary class]]){
                // NSDictinoary
                [self loadAssets:body[key]];
            } else {
                if([body[key] isKindOfClass:[NSString class]]){
                    // String => Terminal Node
                    if([key isEqualToString:@"url"]){
                        // it's a url!
                        // see if it's an image type
                        if(body[@"type"]){
                            if([body[@"type"] isEqualToString:@"image"] || [body[@"type"] isEqualToString:@"button"]){
                                
                                if(body[@"style"]) {
                                    // [Image load optimization] Don't load assets if
                                    // 1. height exists or
                                    // 2. width + ratio exist
                                    if(body[@"style"][@"height"]) {
                                        return;
                                    } else if (body[@"style"][@"width"] && body[@"style"][@"ratio"]) {
                                        return;
                                    }
                                }
                                
                                // it's an image. Let's download!
                                NSString *url = body[key];
                                if(![url containsString:@"{{"] && ![url containsString:@"}}"]){
                                    download_image_counter++;
                                    SDWebImageManager *manager = [SDWebImageManager sharedManager];
                                    NSDictionary *session = [JasonHelper sessionForUrl:url];
                                    if(session && session.count > 0 && session[@"header"]){
                                        for(NSString *key in session[@"header"]){
                                            [manager.imageDownloader setValue:session[@"header"][key] forHTTPHeaderField:key];
                                        }
                                    }
                                    if(body[@"header"] && [body[@"header"] count] > 0){
                                        for(NSString *key in body[@"header"]){
                                            [manager.imageDownloader setValue:body[@"header"][key] forHTTPHeaderField:key];
                                        }
                                    }
                                    [manager.imageDownloader downloadImageWithURL:[NSURL URLWithString:url] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) { } completed:^(UIImage *i, NSData *data, NSError *error, BOOL finished) {
                                        download_image_counter--;
                                        if(!error){
                                            JasonComponentFactory.imageLoaded[url] = [NSValue valueWithCGSize:i.size];
                                        }
                                        //[self.tableView visibleCells];
                                        NSArray *indexPathArray = weakSelf.tableView.indexPathsForVisibleRows;
                                        NSMutableSet *visibleIndexPaths = [[NSMutableSet alloc] initWithArray: indexPathArray];
                                        [visibleIndexPaths intersectSet:(NSSet *)indexPathsForImage[url]];
                                        if(visibleIndexPaths.count > 0){
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [weakSelf.tableView reloadData];
                                            });
                                        }
                                        if(!top_aligned){
                                            if(download_image_counter == 0){
                                                [weakSelf scrollToBottom];
                                            }
                                        }
                                    }];
                                }
                            }
                        }
                    }
                }
            }
        }
    });
}
- (void)finishRefreshing{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView.pullToRefreshView stopAnimating];
    });
}
- (void)refresh {
    if(self.events[@"$pull"]){
            NSDictionary *pull_event = self.events[@"$pull"];
            [[Jason client] call:pull_event];
    }
}


- (void)reload: (NSDictionary *)body final: (BOOL)final{
    indexPathsForImage = [[NSMutableDictionary alloc] init];
    isSearching = NO;
    [self finishRefreshing];
    download_image_counter = 0;
    //keyboardSize = 0;
    
    // Set the stylesheet
    JasonComponentFactory.stylesheet = [self.style mutableCopy];
    JasonComponentFactory.stylesheet[@"$default"] = @{@"color": self.view.tintColor};
    
    JasonLayout.stylesheet = [self.style mutableCopy];
    JasonLayout.stylesheet[@"$default"] = @{@"color": self.view.tintColor};
    
    JasonLayer.stylesheet = [self.style mutableCopy];
    JasonLayer.stylesheet[@"$default"] = @{@"color": self.view.tintColor};
    
    @try{
        dispatch_async(dispatch_get_main_queue(), ^{
        
            [self setupHeader: body];
            [self setupLayers:body];
            [self setupFooter: body];
            [self setupSections:body];
            #ifdef ADS
            [self setupAds:body];
            #endif
            
        
            if(self.isModal){
                // Swipe down to dismiss modal
                UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
                [self.view addGestureRecognizer:pinchRecognizer];
                self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0);

            }
        
            original_bottom_inset = self.tableView.contentInset.bottom;
            if(final) self.isFinal = final;
        });
    }
    @catch(NSException *e){
        [[Jason client] call:@{@"type": @"$cache.reset", @"options": @{@"url": self.url}}];
        NSLog(@"Exception while rendering...");
        NSLog(@"Stack = %@", [JasonMemory client]._stack);
        NSLog(@"Register = %@", [JasonMemory client]._register);
    }
    
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGFloat threshold = -130.0f;
    if(self.events[@"$pull"]){
        if(!self.tabBarController.tabBar.hidden || chat_input){
            threshold = -100.0f;
        } else {
            threshold = -170.0f;
        }
    }
    
    // Swipe down to close modal
    if([self.tabBarController presentingViewController] && scrollView.isDragging && scrollView.contentOffset.y < threshold){
        [[Jason client] cancel];
    }
}
- (void) pinch:(UIPinchGestureRecognizer *)recognizer{
    if(recognizer.scale < 0.3){
        [[Jason client] cancel];
    }
}

- (void)scrollToTop{
    if(self.tableView.numberOfSections >= 1){
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        });
    }
}
- (void)scrollToBottom{
    if(self.tableView.numberOfSections >= 1){
        NSInteger lastSectionIndex = self.tableView.numberOfSections - 1;
        NSInteger lastRowIndex = [self.tableView numberOfRowsInSection:lastSectionIndex] - 1;
        if(lastRowIndex >= 0){
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lastRowIndex inSection:lastSectionIndex];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
            });
        }
    }
}

// CHAT INPUT RELATED
- (void)composeBarViewDidPressButton:(PHFComposeBarView *)c{
    if(chat_input){
        if(chat_input[@"name"] || chat_input[@"textfield"][@"name"]){
            [c setText:@""];
            [[Jason client] call:chat_input[@"right"][@"action"]];
        }
    }
}
- (void)composeBarViewDidPressUtilityButton:(PHFComposeBarView *)c{
    if(chat_input){
        if(chat_input[@"name"] || chat_input[@"textfield"][@"name"]){
            [[Jason client] call:chat_input[@"left"][@"action"]];
        }
    }
}
- (void)setupHeader: (NSDictionary *)body{
    
    
    // NAV (deprecated. See 'header' below)
    NSDictionary *nav = body[@"nav"];
    if(nav){
    
        NSArray *navComponents = nav[@"items"];
        // only handles components specific to TableView (search/tabs).
        // common component (menu) is handled in Jason.m
        tabs = nil;

        for(NSDictionary *component in navComponents){
            NSString *type = component[@"type"];
            if(type){
                if([type isEqualToString:@"search"]){
                    
                    
                    search_action = component[@"action"];
                    search_field_name = component[@"name"];
                    NSString *search_placeholder = component[@"placeholder"];
                    NSDictionary *stylized_component = [JasonComponentFactory applyStylesheet: component];
                    NSDictionary *style = stylized_component[@"style"];
                    
                    if(!self.searchController){
                        self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
                    }
                    // style
                    NSString *theme = style[@"theme"];
                    if([theme isEqualToString:@"light"]){
                        self.searchController.dimsBackgroundDuringPresentation = NO;
                    } else {
                        self.searchController.dimsBackgroundDuringPresentation = YES;
                    }
                    
                    NSString *dark = style[@"dark"];
                    if(dark){
                        self.searchController.dimsBackgroundDuringPresentation = YES;
                    } else {
                        self.searchController.dimsBackgroundDuringPresentation = NO;
                    }
                    
                    // When there's no action, use the default search behavior
                    if(!search_action){
                        self.searchController.searchResultsUpdater = self;
                        self.searchController.dimsBackgroundDuringPresentation = NO;
                    }
                    self.searchController.searchBar.delegate = self;
                    
                    NSString *backgroundColorStr = style[@"background"];
                    UIColor *backgroundColor = self.navigationController.navigationBar.backgroundColor;
                    if(backgroundColorStr){
                        backgroundColor = [JasonHelper colorwithHexString:backgroundColorStr alpha:1.0];
                    }
                    
                    NSString *colorStr = style[@"color"];
                    UIColor *color = self.navigationController.navigationBar.tintColor;
                    if(colorStr){
                        color = [JasonHelper colorwithHexString:colorStr alpha:1.0];
                    }
                    
                    if(search_placeholder){
                        self.searchController.searchBar.placeholder = search_placeholder;
                    }

                    UIView *subViews =  [[self.searchController.searchBar subviews] firstObject];
                    for(UIView *subView in [subViews subviews]) {
                        if([subView conformsToProtocol:@protocol(UITextInputTraits)]) {
                            [(UITextField *)subView setEnablesReturnKeyAutomatically:NO];
                            [(UITextField *)subView setTextColor:color];
                        }
                    }
                    
                    
                    self.searchController.searchBar.returnKeyType = UIReturnKeyGo;
                    self.searchController.searchBar.barTintColor = backgroundColor;
                    self.searchController.searchBar.tintColor = color;//keyColor;
                    self.searchController.searchBar.backgroundColor = backgroundColor;
                    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
                    
                    // Search bar textfield styling
                    NSArray *searchBarSubViews = [[self.searchController.searchBar.subviews objectAtIndex:0] subviews];
                    for (UIView *view in searchBarSubViews) {
                        if([view isKindOfClass:[UITextField class]])
                        {
                            UITextField *textField = (UITextField*)view;
                            UIImageView *imgView = (UIImageView*)textField.leftView;
                            imgView.image = [imgView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                            imgView.tintColor = color;
                            NSDictionary *placeholderAttributes = @{ NSForegroundColorAttributeName: color, NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:15] };
                            textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchController.searchBar.placeholder
                                                                                                        attributes:placeholderAttributes];
                        }
                    }

                    if(!self.tableView.tableHeaderView) {
                        self.tableView.tableHeaderView = self.searchController.searchBar;
                    }
                    self.searchController.hidesNavigationBarDuringPresentation = NO;

                    [self.searchController.searchBar sizeToFit];

                } else if([type isEqualToString:@"tabs"]){
                    tabs = component;
                }
            }
        }
    } else if (body[@"header"]){
        
        
        // Header (Replacement for nav)
        NSDictionary *header = body[@"header"];
        if(header){
        
            // only handles components specific to TableView (search/tabs).
            // common component (menu) is handled in Jason.m
            tabs = nil;

            for(NSString *type in [header allKeys]){
                if(type){
                    if([type isEqualToString:@"search"]){
                        NSDictionary *component = [JasonComponentFactory applyStylesheet:header[type]];
                        
                        search_action = component[@"action"];
                        search_field_name = component[@"name"];
                        NSString *search_placeholder = component[@"placeholder"];
                        NSDictionary *style = component[@"style"];
                        
                        if(!self.searchController){
                            self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
                        }
                        // style
                        NSString *theme = style[@"theme"];
                        if([theme isEqualToString:@"light"]){
                            self.searchController.dimsBackgroundDuringPresentation = NO;
                        } else {
                            self.searchController.dimsBackgroundDuringPresentation = YES;
                        }
                        
                        // When there's no action, use the default search behavior
                        if(!search_action){
                            self.searchController.searchResultsUpdater = self;
                            self.searchController.dimsBackgroundDuringPresentation = NO;
                        }
                        self.searchController.searchBar.delegate = self;
                        
                        NSString *backgroundColorStr = style[@"background"];
                        UIColor *backgroundColor = self.navigationController.navigationBar.backgroundColor;
                        if(backgroundColorStr){
                            backgroundColor = [JasonHelper colorwithHexString:backgroundColorStr alpha:1.0];
                        }
                        
                        NSString *colorStr = style[@"color"];
                        UIColor *color = self.navigationController.navigationBar.tintColor;
                        if(colorStr){
                            color = [JasonHelper colorwithHexString:colorStr alpha:1.0];
                        }
                        
                        if(search_placeholder){
                            self.searchController.searchBar.placeholder = search_placeholder;
                        }

                        UIView *subViews =  [[self.searchController.searchBar subviews] firstObject];
                        for(UIView *subView in [subViews subviews]) {
                            if([subView conformsToProtocol:@protocol(UITextInputTraits)]) {
                                [(UITextField *)subView setEnablesReturnKeyAutomatically:NO];
                                [(UITextField *)subView setTextColor:color];
                            }
                        }
                        
                        self.searchController.searchBar.returnKeyType = UIReturnKeyGo;
                        self.searchController.searchBar.barTintColor = backgroundColor;
                        self.searchController.searchBar.tintColor = color;
                        self.searchController.searchBar.backgroundColor = backgroundColor;
                        self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
                        
                        // Search bar textfield styling
                        NSArray *searchBarSubViews = [[self.searchController.searchBar.subviews objectAtIndex:0] subviews];
                        for (UIView *view in searchBarSubViews) {
                            if([view isKindOfClass:[UITextField class]])
                            {
                                UITextField *textField = (UITextField*)view;
                                UIImageView *imgView = (UIImageView*)textField.leftView;
                                imgView.image = [imgView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                                imgView.tintColor = color;
                                NSDictionary *placeholderAttributes = @{ NSForegroundColorAttributeName: color, NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:15] };
                                textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchController.searchBar.placeholder
                                                                                                            attributes:placeholderAttributes];
                            }
                        }

                        if(!self.tableView.tableHeaderView) {
                            self.tableView.tableHeaderView = self.searchController.searchBar;
                        }
                        self.searchController.hidesNavigationBarDuringPresentation = NO;

                        [self.searchController.searchBar sizeToFit];

                    } else if([type isEqualToString:@"tabs"]){
                        NSDictionary *component = [JasonComponentFactory applyStylesheet:header[type]];
                        tabs = component;
                    }
                }
            }
        }
    } else {
        self.tableView.tableHeaderView = nil;
    }
}

- (void)setupLayers: (NSDictionary *)body{
    for(UIView *v in self.layers){
        [v removeFromSuperview];
    }
    self.layers = [JasonLayer setupLayers: body withView:self.view];
}
- (void)setupSections:(NSDictionary *)body{
    
    raw_sections = body[@"sections"];
    
    if(!raw_sections){
        [self.view sendSubviewToBack:self.tableView];
    }
    
    JasonComponentFactory.imageLoaded = [[NSMutableDictionary alloc] init];
    
    // Get rid of all nodes pruned out by #if templating
    // => Need to search for any keys that include {{}} and get rid of it from the object or array
    
    NSDictionary *style = body[@"style"];

    top_aligned = YES;
    if(style){
        NSString *border = style[@"border"];
        if(border){
            if([border isEqualToString: @"none"] || [border isEqualToString:@"0"]){
                self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
                [self.tableView setSeparatorColor:[UIColor clearColor]];
            } else {
                // it's a color code;
                [self.tableView setSeparatorColor:[JasonHelper colorwithHexString:border alpha:1.0]];
            }
        }
        
        
        
        NSString *align = style[@"align"];
        if(align && [align isEqualToString:@"bottom"]){
            top_aligned = NO;
        }
    } else {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.separatorColor = [JasonHelper colorwithHexString:@"rgb(224,224,224)" alpha:1.0];
        self.view.backgroundColor = [UIColor whiteColor];
    }
    self.tableView.backgroundColor = [UIColor clearColor];
    
    
    id weakSelf = self;
    [weakSelf loadAssets:body];
    
    if(self.events[@"$pull"]){
        [self.tableView addPullToRefreshWithActionHandler:^{
            [weakSelf refresh];
        }];
        if(style){
            NSString *cl = style[@"color"];
            if(cl){
                UIColor *refresh_color = [JasonHelper colorwithHexString:cl alpha:1.0];
                self.tableView.pullToRefreshView.arrowColor = refresh_color;
                self.tableView.pullToRefreshView.textColor = refresh_color;
                self.tableView.pullToRefreshView.activityIndicatorViewColor = refresh_color;
            }
        }
    }
    
    [self reloadSections: raw_sections];
}
- (void)reloadSections:(NSArray *)sections{
    if(sections && [sections isKindOfClass:[NSArray class]]){
        self.sections = [sections mutableCopy];
    } else {
        // Render even when no body has been passed
        self.sections = [[NSMutableArray alloc] init];
    }
    
    rowcount = [[NSMutableArray alloc] init];
    headers = [[NSMutableArray alloc] init];
    NSInteger total_rowcount = 0;
    
    if(tabs){
        [self.sections insertObject:@{@"header": tabs} atIndex:0];
    }
    
    
    for(NSDictionary *section in self.sections){
        NSMutableDictionary *header = section[@"header"];
        NSNumber *rowcount_for_section = [NSNumber numberWithLong:[section[@"items"] count]];
        [rowcount addObject:rowcount_for_section];
        total_rowcount = total_rowcount + [rowcount_for_section longValue];
        if(!header || [[NSNull null] isEqual:header]){
            // No header
            [headers addObject:@{}];
        } else {
            [headers addObject:section[@"header"]];
        }
    }
    [self.tableView reloadData];
    if(!top_aligned){
        [self scrollToBottom];
    }
    
}
- (void)setupFooter: (NSDictionary *)body{
    
    if(body[@"footer"] && body[@"footer"][@"input"]){
        
        
        chat_input = body[@"footer"][@"input"];
        if(chat_input){

            //JasonViewController *weakSelf = self;
            __weak JasonViewController *weakSelf = self;

            [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
                CGFloat m = MIN(original_height, keyboardFrameInView.origin.y);
                if(opening || (closing && m >= weakSelf.view.frame.size.height)){
                    CGRect newViewFrame = CGRectMake(weakSelf.view.frame.origin.x, weakSelf.view.frame.origin.y, weakSelf.view.frame.size.width, m);
                    weakSelf.view.frame = newViewFrame;
                }
            }];
            
            // textfield logic
            
            NSDictionary *field;
            if(chat_input[@"textfield"]){
                field = chat_input[@"textfield"];
            } else {
                field = chat_input; // to be deprecated
            }
            
            if(!composeBarView){
                CGRect viewBounds = [self.view bounds];
                CGRect frame = CGRectMake(0.0f,
                                          viewBounds.size.height - PHFComposeBarViewInitialHeight,
                                          viewBounds.size.width,
                                          PHFComposeBarViewInitialHeight);
                composeBarView = [[PHFComposeBarView alloc] initWithFrame:frame];
                if(field[@"name"]){
                    composeBarView.textView.payload = [@{@"name": field[@"name"]} mutableCopy];
                }
                [composeBarView setDelegate:self];
                [self.view addSubview:composeBarView];
                [self.view bringSubviewToFront:composeBarView];
            }
            
            
            // First set the background style. The order is important because we will override some background colors below
            if(chat_input[@"style"]){
                if(chat_input[@"style"][@"background"]){
                    [self force_background:chat_input[@"style"][@"background"] intoView:composeBarView];
                }
            }
            
            // input field styling
            if(field[@"style"]){
                
                //PHFComposeBarView hack to find relevant views and apply style
                //[JasonHelper force_background:@"#000000" intoView:composeBarView];
                for(UIView *v in composeBarView.subviews){
                    for(UIView *vv in v.subviews){
                        if([vv isKindOfClass:[UITextView class]]){
                            vv.superview.layer.borderWidth = 0;
                            for(UIView *vvv in vv.superview.subviews){
                                
                                // textfield background
                                if(field[@"style"][@"background"]){
                                    vvv.backgroundColor = [JasonHelper colorwithHexString:field[@"style"][@"background"] alpha:1.0];
                                }
                                
                                // placeholder color
                                if([vvv isKindOfClass:[UILabel class]]){
                                    // placeholder label
                                    ((UILabel*)vvv).textColor = [JasonHelper colorwithHexString:field[@"style"][@"color:placeholder"] alpha:1.0];
                                }
                            }
                            break;
                        }
                    }
                }
                
                // text color
                if(field[@"style"][@"color"]){
                    composeBarView.textView.textColor = [JasonHelper colorwithHexString:field[@"style"][@"color"] alpha:1.0];
                }
                    
            }
            
            if(field[@"placeholder"]){
                [composeBarView setPlaceholder:field[@"placeholder"]];
            }
            
            if(chat_input[@"left"]){
                if(chat_input[@"left"][@"image"]){
                    if([chat_input[@"left"][@"image"] containsString:@"file://"]){
                        NSString *localImageName = [chat_input[@"left"][@"image"] substringFromIndex:7];
                        UIImage *localImage = [UIImage imageNamed:localImageName];
                        // colorize
                        if(chat_input[@"left"][@"style"] && chat_input[@"left"][@"style"][@"color"]){
                            UIColor *newColor = [JasonHelper colorwithHexString:chat_input[@"left"][@"style"][@"color"] alpha:1.0];
                            localImage = [JasonHelper colorize:localImage into:newColor];
                        }
                        UIImage *resizedImage = [JasonHelper scaleImage:localImage ToSize:CGSizeMake(30,30)];
                        [composeBarView setUtilityButtonImage:resizedImage];
                    } else {
                        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                            SDWebImageManager *manager = [SDWebImageManager sharedManager];
                            [manager downloadImageWithURL:[NSURL URLWithString:chat_input[@"left"][@"image"]]
                                                  options:0
                                                 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                     // progression tracking code
                                                 }
                                                completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                    
                                                    // colorize
                                                    if(chat_input[@"left"][@"style"] && chat_input[@"left"][@"style"][@"color"]){
                                                        UIColor *newColor = [JasonHelper colorwithHexString:chat_input[@"left"][@"style"][@"color"] alpha:1.0];
                                                        image = [JasonHelper colorize:image into:newColor];
                                                    }
                                                    
                                                    UIImage *resizedImage = [JasonHelper scaleImage:image ToSize:CGSizeMake(30,30)];
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        [composeBarView setUtilityButtonImage:resizedImage];
                                                    });
                                                }
                             ];
                        });
                        
                    }
                }
            }
            if(chat_input[@"right"]){
                if(chat_input[@"right"][@"text"]){
                    
                    /*
                    // handle color
                    if(chat_input[@"right"][@"style"] && chat_input[@"right"][@"style"][@"color"]){
                        [composeBarView setButtonTintColor:[JasonHelper colorwithHexString:chat_input[@"right"][@"style"][@"color"] alpha:1.0]];
                    }
                     */
                    
                    NSArray *buttons = [JasonHelper childOf:composeBarView withClassName:@"PHFComposeBarView_Button"];
                    for(UIButton *button in buttons){
                        if([button.subviews.firstObject isKindOfClass:[UILabel class]]){
                            
                            // set "color"
                            if(chat_input[@"right"][@"style"] && chat_input[@"right"][@"style"][@"color"]){
                                [button setTitleColor:[JasonHelper colorwithHexString:chat_input[@"right"][@"style"][@"color"] alpha:1.0] forState:UIControlStateNormal];
                            }
                            
                            // set "color:disabled"
                            if(chat_input[@"right"][@"style"] && chat_input[@"right"][@"style"][@"color:disabled"]){
                                [button setTitleColor:[JasonHelper colorwithHexString:chat_input[@"right"][@"style"][@"color:disabled"] alpha:1.0] forState:UIControlStateDisabled];
                            } else {
                                // default
                                [button setTitleColor:[JasonHelper colorwithHexString:chat_input[@"right"][@"style"][@"color"] alpha:1.0] forState:UIControlStateDisabled];
                            }
                        }
                    }
                    
                    [composeBarView setButtonTitle:chat_input[@"right"][@"text"]];
                }
            }
            
            // The background for the entire footer input
            if(chat_input[@"style"]){
                if(chat_input[@"style"][@"background"]){
                    composeBarView.backgroundColor = [JasonHelper colorwithHexString:chat_input[@"style"][@"background"] alpha:1.0];
                }
            }

        }
        
        
    }
}
- (void)force_background: (NSString *) color intoView: (UIView *) view{
    if([view isKindOfClass:[UIToolbar class]]){
        [(UIToolbar *)view setBackgroundImage:[UIImage new]
                      forToolbarPosition:UIToolbarPositionAny
                              barMetrics:UIBarMetricsDefault];
        [(UIToolbar *)view setBackgroundColor:[UIColor clearColor]];
    } else if([view isKindOfClass:[UITextView class]]){
        // don't do anything
    } else {
        view.backgroundColor = [JasonHelper colorwithHexString:color alpha:1.0];
        if(view.subviews && view.subviews.count > 0){
            for(UIView *v in view.subviews){
                [self force_background:color intoView:v];
            }
        }
    }
}

/********************************
 * Google AdMob
 ********************************/

#ifdef ADS
- (void)setupAds: (NSDictionary *)body
{
    if(body[@"ads"]){
        
        NSArray * adData = body[@"ads"];
        if(adData.count > 0){
            for (int i = 0 ; i < adData.count ; i++){
                NSDictionary *selectedAd = [adData objectAtIndex:i];
                NSString * adType = selectedAd[@"type"];
               
                
                if([adType isEqualToString:@"admob"] && selectedAd[@"options"] && selectedAd[@"options"][@"type"] && selectedAd[@"options"][@"unitId"]){
                    
                    NSDictionary *options = selectedAd[@"options"];
                    NSString *adUnitId = options[@"unitId"];
                    NSString *type = options[@"type"];
                    if([type isEqualToString:@"banner"]){
                        self.bannerAd = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];
                        CGPoint adPoint = CGPointMake(0, self.view.frame.size.height - self.bannerAd.frame.size.height);
                       
                        if(body[@"footer"]){
                            adPoint = CGPointMake(0, self.view.frame.size.height - self.bannerAd.frame.size.height - self.tabBarController.tabBar.frame.size.height);
                        }
                        
                        NSString * adUnitID = adUnitId;
                        self.bannerAd.frame = CGRectMake( adPoint.x,
                                                         adPoint.y,
                                                         self.bannerAd.frame.size.width,
                                                         self.bannerAd.frame.size.height );
                        
                        self.bannerAd.autoresizingMask =
                        UIViewAutoresizingFlexibleLeftMargin |
                        UIViewAutoresizingFlexibleTopMargin |
                        UIViewAutoresizingFlexibleWidth |
                        UIViewAutoresizingFlexibleRightMargin;
                        
                        self.bannerAd.adUnitID = adUnitID; //Test Id: a14dccd0fb24d45
                        self.bannerAd.rootViewController = self;
                        self.bannerAd.delegate = self;
                        [self.view addSubview:self.bannerAd];
                        
                        GADRequest * admobRequest = [[GADRequest alloc] init];
                        admobRequest.testDevices = @[
                                                     // TODO: Add your device/simulator test identifiers here. Your device identifier is printed to
                                                     // the console when the app is launched.
                                                     kGADSimulatorID
                                                     ];
                        [self.bannerAd loadRequest:admobRequest];
                    }
                    else if([type isEqualToString:@"interstitial"]){
                        self.interestialAd = [[GADInterstitial alloc] initWithAdUnitID:adUnitId];
                        self.interestialAd.delegate = self;
                        GADRequest * admobRequest = [[GADRequest alloc] init];
                        admobRequest.testDevices = @[
                                                     // TODO: Add your device/simulator test identifiers here. Your device identifier is printed to
                                                     // the console when the app is launched.
                                                     kGADSimulatorID
                                                     ];
                        [self.interestialAd loadRequest:admobRequest];
                        
                        intrestialAdTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(showInterstitialAd) userInfo:nil repeats:YES];
                        
                    }
                    
                }
                
            }
           
        }
    }

   
}
-(void) showInterstitialAd{
    if(self.interestialAd.isReady){
        [intrestialAdTimer invalidate];
        intrestialAdTimer = nil;
        [self.interestialAd presentFromRootViewController:self];
    }
}

-(void) adjustBannerPosition
{
    if(chat_input && self.bannerAd != nil){
        
        self.bannerAd.frame = CGRectMake(0, self.view.frame.size.height - self.bannerAd.frame.size.height - self.tabBarController.tabBar.frame.size.height, self.bannerAd.frame.size.width, self.bannerAd.frame.size.height);
    }
}
- (void) adView: (GADBannerView*) view didFailToReceiveAdWithError: (GADRequestError*) error{
    NSLog(@"Error on showing AD %@", error);
}
- (void) adViewDidReceiveAd: (GADBannerView*) view{
    NSLog(@"Suucess on showing ad");
    [self adjustBannerPosition];
}

- (void)interstitialDidReceiveAd:(GADInterstitial *)ad{
     NSLog(@"--->Suucess on showing interstitial ad");
}

/// Called when an interstitial ad request completed without an interstitial to
/// show. This is common since interstitials are shown sparingly to users.
- (void)interstitial:(GADInterstitial *)ad didFailToReceiveAdWithError:(GADRequestError *)error{
    NSLog(@" -->>Error on showing interstitial AD %@", error);
}

#endif

/********************************/





- (void)attributedLabel:(__unused TTTAttributedLabel *)label
   didSelectLinkWithURL:(NSURL *)url {
    SFSafariViewController *vc = [[SFSafariViewController alloc] initWithURL:url];
    [self.navigationController presentViewController:vc animated:YES completion:nil];
}


- (NSArray *)rightButtons: (NSDictionary *)menuObject
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    NSArray *menu;
    if(menuObject[@"trigger"]){
        NSString *menu_id = menuObject[@"trigger"];
        if(menu_id){
            if(menuObject[@"options"]){
                NSDictionary *event_action = self.events[menu_id];
                NSArray *menu_parser = event_action[@"options"];
                NSDictionary *realMenuObject = [JasonHelper parse: menuObject[@"options"] with:menu_parser];
                menu = realMenuObject[@"items"];
                if(!menu){
                    menu = @[];
                }
            } else {
                menu = @[];
            }
        } else {
            menu = @[];
        }
    } else {
        menu = menuObject[@"items"];
    }
    
    for(int i = 0 ; i < menu.count ; i++){
        NSDictionary *item = [JasonComponentFactory applyStylesheet:[menu objectAtIndex:i]];
        NSString *text = item[@"text"];
        UIColor *background = self.view.tintColor;
        NSDictionary *style = item[@"style"];
        if(style){
            if(style[@"background"]){
                NSString *background_str = style[@"background"];
                if(background_str){
                    background = [JasonHelper colorwithHexString:background_str alpha:1.0];
                }
            }
        }
        if(text && text.length >0){
            [rightUtilityButtons sw_addUtilityButtonWithColor:background title:text];
        }
        
    }
    
    return rightUtilityButtons;
}
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *section = [self.sections objectAtIndex:cellIndexPath.section];
    NSDictionary *item = [section[@"items"] objectAtIndex:cellIndexPath.row];
    NSDictionary *menuObject = item[@"menu"];
    NSArray *menu;
    
    if(menuObject[@"trigger"]){
        NSString *menu_id = menuObject[@"trigger"];
        if(menu_id){
            if(menuObject[@"options"]){
                NSDictionary *event_action = self.events[menu_id];
                NSArray *menu_parser = event_action[@"options"];
                NSDictionary *realMenuObject = [JasonHelper parse: menuObject[@"options"] with:menu_parser];
                menu = realMenuObject[@"items"];
                if(!menu){
                    menu = @[];
                }
            } else {
                menu = @[];
            }
        } else {
            menu = @[];
        }
    } else {
        menu = menuObject[@"items"];
    }
    
    
    if(menu && menu.count > 0){
        if([[menu objectAtIndex:index] valueForKey:@"action"]){
            [[Jason client] call:[[menu objectAtIndex:index] valueForKey:@"action"]];
        }
    }
}





// Self sizing cells cache logic
- (void) setEstimatedHeight:(NSIndexPath *) indexPath height:(CGFloat) height {
    [estimatedRowHeightCache setObject:@(height) forKey:[self cacheKeyForIndexPath:indexPath]];
}
- (CGFloat) getEstimatedHeight:(NSIndexPath *) indexPath defaultHeight:(CGFloat) defaultHeight {
    NSNumber *estimatedHeight = [estimatedRowHeightCache objectForKey:[self cacheKeyForIndexPath:indexPath]];
    if (estimatedHeight != nil) {
        return [estimatedHeight floatValue];
    }
    return defaultHeight;
}
- (BOOL) estimatedHeightExists:(NSIndexPath *) indexPath {
    if ([estimatedRowHeightCache objectForKey:[self cacheKeyForIndexPath:indexPath]] != nil) {
        return YES;
    }
    return NO;
}
-(void) clearEstimatedRowCacheForIndexPath:(NSIndexPath *) indexPath {
    [estimatedRowHeightCache removeObjectForKey:[self cacheKeyForIndexPath:indexPath]];
}
- (void) clearAllEstimatedRowCache {
    [estimatedRowHeightCache removeAllObjects];
}
- (void) estimatedReloadData{
    [self clearAllEstimatedRowCache];
    [self.tableView reloadData];
}
- (NSString *)cacheKeyForIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat:@"%ld-%ld", (long) indexPath.section, (long) indexPath.row];
}



@end
