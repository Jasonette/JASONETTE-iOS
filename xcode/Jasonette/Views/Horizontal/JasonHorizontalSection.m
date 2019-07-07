//
//  JasonHorizontalSection.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonHorizontalSection.h"
@interface JasonHorizontalSection (){
    UIImage *placeholder_image;
}
@end

@implementation JasonHorizontalSection

- (void)awakeFromNib {
    [super awakeFromNib];

    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.minimumLineSpacing = 0.0;
    flowLayout.minimumInteritemSpacing = 0.0;
    flowLayout.sectionInset = UIEdgeInsetsZero;
    _collectionView.contentInset = UIEdgeInsetsZero;
    [_collectionView registerNib:[UINib nibWithNibName:@"JasonHorizontalSectionItem" bundle:nil] forCellWithReuseIdentifier:@"JasonHorizontalSectionItem"];
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self.items objectAtIndex:[indexPath row]];
    return [self getItemCell:item forCollectionView:collectionView atIndexPath:indexPath];
    
}
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    float width = 100.0f;
    float height = 100.0f;
    NSDictionary *item = [self.items objectAtIndex:[indexPath row]];
    
    item = [JasonComponentFactory applyStylesheet:item];
    NSDictionary *style = item[@"style"];
    
    if(style){
        if(style[@"width"]){
            NSString * widthStr = style[@"width"];
            width = [JasonHelper pixelsInDirection:@"horizontal" fromExpression:widthStr];
        }
        if(style[@"height"]){
            NSString * heightStr = style[@"height"];
            height = [JasonHelper pixelsInDirection:@"vertical" fromExpression:heightStr];
        }
    }
    
    return CGSizeMake(width, height);
}

- (void)setCollectionData:(NSArray *)items{
    _items = items;
    [_collectionView setContentOffset:CGPointZero animated:NO];
    [_collectionView reloadData];
}


- (UICollectionViewCell*)getItemCell:(NSDictionary *)item forCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath{
    NSString *cellType = @"JasonHorizontalSectionItem";
    JasonHorizontalSectionItem *cell = (JasonHorizontalSectionItem *)[collectionView dequeueReusableCellWithReuseIdentifier:cellType forIndexPath:indexPath];

    UIStackView *layout;

    if(!cell){
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellType owner:self options:nil];
        cell = [nib objectAtIndex:0];        
    }
    
    if (cell.contentView.subviews.count == 0)
    {
        layout = [[UIStackView alloc] init];
        [cell.contentView addSubview:layout];
        NSString *horizontal_vfl = [NSString stringWithFormat:@"|-0@%f-[layout]-0@%f-|", UILayoutPriorityRequired, UILayoutPriorityRequired];
        NSString *vertical_vfl = [NSString stringWithFormat:@"V:|-0@%f-[layout]-0@%f-|", UILayoutPriorityRequired, UILayoutPriorityRequired];
        [cell.contentView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:horizontal_vfl options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"layout": layout}]];
        [cell.contentView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:vertical_vfl options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"layout": layout}]];
    } else {
        layout = cell.contentView.subviews.firstObject;
    }
    NSDictionary *layout_generator = [JasonLayout fill:layout with:item atIndexPath:indexPath withForm:nil];
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
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,[style[@"width"] floatValue], [style[@"height"] floatValue])];
            cell.backgroundView = imageView;
            cell.backgroundView.backgroundColor = [UIColor clearColor];
            [imageView sd_setImageWithURL:[NSURL URLWithString:style[@"background"]] placeholderImage:placeholder_image completed:^(UIImage *i, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            }];
        } else {
            cell.backgroundColor = [JasonHelper colorwithHexString:style[@"background"] alpha:1.0];
        }
    } else {
        cell.backgroundColor = [UIColor clearColor];
    }
    
    [cell.contentView setNeedsLayout];
    [cell.contentView layoutIfNeeded];
    
    return cell;
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self.items objectAtIndex:indexPath.row];
    NSDictionary *action = item[@"action"];
    NSDictionary *href = item[@"href"];
    if(action){
        [[Jason client] call:action];
    } else if (href){
        [[Jason client] go:href];
    } else {
        // Do nothing
    }
    
}

@end
