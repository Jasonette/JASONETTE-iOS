//
//  UITableView+Screenshot.m
//  Kiwi
//
//  Created by Marcin Stepnowski on 10/11/14.
//  Copyright (c) 2014 Marcin Stepnowski. All rights reserved.
//

#import "UIScrollView+DHSmartScreenshot.h"
#import "UIView+DHSmartScreenshot.h"

@implementation UIScrollView (DHSmartScreenshot)

-(UIImage*)screenshotOfVisibleContent{
    CGRect croppingRect = self.bounds;
    croppingRect.origin = self.contentOffset;
    return [self screenshotForCroppingRect: croppingRect];
}

@end
