//
//  UIColor+NamedColors.h
//  Finalsite
//
//  Created by Kevin Spain on 9/6/19.
//  Copyright © 2019 Jasonette. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@implementation UIColor (UIColorNamedColors)

    + (UIColor *) colorPrimaryDark {
        if (@available(iOS 11.0, *)) {
            return [UIColor colorNamed:@"ColorPrimaryDark"];
        } else {
            return [UIColor colorWithRed:0.14 green:0.266 blue:0.387 alpha:1.0];
        }
    }

@end

NS_ASSUME_NONNULL_END
