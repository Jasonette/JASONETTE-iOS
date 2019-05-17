//
//  RMActionControllerTransition.h
//  RMActionController-Demo
//
//  Created by Roland Moers on 19.11.16.
//  Copyright © 2016 Roland Moers. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, RMActionControllerTransitionStyle) {
    RMActionControllerTransitionStylePresenting,
    RMActionControllerTransitionStyleDismissing
};

@interface RMActionControllerTransition : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) RMActionControllerTransitionStyle animationStyle;

@end
