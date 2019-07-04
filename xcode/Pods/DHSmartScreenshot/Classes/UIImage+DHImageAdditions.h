//
//  UIImage+ImageFromArrayUtils.h
//  TableViewScreenshots
//
//  Created by Hernandez Alvarez, David on 11/28/13.
//  Copyright (c) 2013 David Hernandez. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (DHImageUtils)

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;

@end

@interface UIImage (DHImageFromArrayUtils)

+ (UIImage *)verticalImageFromArray:(NSArray *)imagesArray;

@end
