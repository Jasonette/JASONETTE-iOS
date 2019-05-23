//
//  UIView+RMActionController.m
//  RMActionController-Demo
//
//  Created by Roland Moers on 19.11.16.
//  Copyright © 2016 Roland Moers. All rights reserved.
//

#import "UIView+RMActionController.h"

@implementation UIView (RMActionController)

+ (UIView *)seperatorView {
    UIView *seperatorView = [[UIView alloc] initWithFrame:CGRectZero];
    seperatorView.backgroundColor = [UIColor grayColor];
    seperatorView.translatesAutoresizingMaskIntoConstraints = NO;
    
    return seperatorView;
}

@end
