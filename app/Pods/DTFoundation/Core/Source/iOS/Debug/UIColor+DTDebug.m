//
//  UIColor+DTDebug.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 01.03.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "UIColor+DTDebug.h"

@implementation UIColor (DTDebug)

+ (UIColor *)randomColor
{
    CGFloat red = (arc4random()%256)/256.0;
    CGFloat green = (arc4random()%256)/256.0;
    CGFloat blue = (arc4random()%256)/256.0;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

@end
