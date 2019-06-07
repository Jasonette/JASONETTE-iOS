//
//  JasonHorizontalSection.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "JasonHelper.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "JasonHorizontalSectionItem.h"
#import "Jason.h"
#import "JasonComponentFactory.h"
#import "JasonLayout.h"
#import "UIView+JasonComponentPayload.h"
#import <TTTAttributedLabel/TTTAttributedLabel.h>

@interface JasonHorizontalSection : UITableViewCell <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSArray *items;
@property (strong, nonatomic) NSDictionary *style;
@property (strong, nonatomic) NSDictionary *stylesheet;
@end
