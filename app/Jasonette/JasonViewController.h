//
//  JasonViewController.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "UIBarButtonItem+Badge.h"
#import "RussianDollView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "JasonHelper.h"
#import "UIView+JasonComponentPayload.h"
#import <HMSegmentedControl/HMSegmentedControl.h>
#import <JDStatusBarNotification/JDStatusBarNotification.h>
#import "Jason.h"
#import <SWTableViewCell/SWTableViewCell.h>
#import <SZTextView/SZTextView.h>
#import "JasonHorizontalSection.h"
#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import <DHSmartScreenshot/DHSmartScreenshot.h>
#import <DTCoreText/DTCoreText.h>
#import <PHFComposeBarView/PHFComposeBarView.h>
#import <DAKeyboardControl/DAKeyboardControl.h>
#import <SVPullToRefresh/SVPullToRefresh.h>
#import "JasonLayout.h"
#import "JasonLayer.h"
#import "JasonComponentFactory.h"
#import "JasonComponent.h"
#include "Constants.h"
#ifdef ADS
#import <GoogleMobileAds/GoogleMobileAds.h>
#endif

@interface JasonViewController : UIViewController <TTTAttributedLabelDelegate, UISearchBarDelegate, RussianDollView, SWTableViewCellDelegate, UISearchResultsUpdating, PHFComposeBarViewDelegate, UITableViewDelegate, UITableViewDataSource
#ifdef ADS
    , GADBannerViewDelegate, GADInterstitialDelegate
#endif
>

@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSDictionary *options;
@property (nonatomic, strong) NSDictionary *callback;
@property (nonatomic, strong) NSDictionary *nav;
@property (nonatomic, strong) NSDictionary *current_cache;
@property (nonatomic, strong) NSMutableArray *log;
@property (nonatomic, strong) NSMutableArray *playing;
@property (nonatomic, strong) UIView *background;

@property (strong, nonatomic) NSDictionary *parser;
@property (nonatomic, strong) NSDictionary *data;
@property (strong, nonatomic) NSMutableDictionary *old_header;
@property (strong, nonatomic) NSMutableDictionary *old_footer;

@property (nonatomic, strong) NSArray *layers;
@property (nonatomic, strong) NSMutableArray *sections;
@property (nonatomic, strong) NSArray *rows;
@property (nonatomic, assign) BOOL isModal;
@property (nonatomic, strong) NSMutableDictionary *action_callback;
@property (nonatomic, strong) NSMutableDictionary *events;
@property (strong, nonatomic) NSDictionary *style;
@property (strong, nonatomic) NSDictionary *rendered;
@property (strong, nonatomic) NSDictionary *original;
@property (nonatomic, assign) BOOL contentLoaded;
@property (nonatomic, assign) BOOL touching;
@property (nonatomic, assign) BOOL fresh;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) BOOL offline;
@property (nonatomic, assign) BOOL isFinal;
@property (strong, nonatomic) NSMutableDictionary *menu;
@property (strong, nonatomic) NSMutableDictionary *form;
@property (strong, nonatomic) NSMutableDictionary *requires;
@property (strong, nonatomic) NSMutableDictionary *timers;
@property (strong, nonatomic) NSMutableDictionary *audios;

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) UISearchController *searchController;
#ifdef ADS
@property (strong, nonatomic) GADBannerView *bannerAd;
@property (strong, nonatomic) GADInterstitial * interestialAd;
#endif
- (void)reload: (NSDictionary *)res final: (BOOL) final;

@end
