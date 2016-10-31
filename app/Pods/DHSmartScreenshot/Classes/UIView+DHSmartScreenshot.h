//
//  UIView+DHSmartScreenshot.h
//  TableViewScreenshots
//
//  Created by Hernandez Alvarez, David on 11/30/13.
//  Copyright (c) 2013 David Hernandez. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (DHSmartScreenshot)

- (UIImage *)screenshot;
- (UIImage *)screenshotForCroppingRect:(CGRect)rect;

@end
