//
//  RMActionControllerTransition.m
//  RMActionController-Demo
//
//  Created by Roland Moers on 19.11.16.
//  Copyright © 2016 Roland Moers. All rights reserved.
//

#import "RMActionControllerTransition.h"

#import "RMActionController+Private.h"

@implementation RMActionControllerTransition

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    if(self.animationStyle == RMActionControllerTransitionStylePresenting) {
        UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        if([toVC isKindOfClass:[RMActionController class]]) {
            RMActionController *actionController = (RMActionController *)toVC;
            
            if(actionController.disableBouncingEffects) {
                return 0.3f;
            } else {
                return 1.0f;
            }
        }
    } else if(self.animationStyle == RMActionControllerTransitionStyleDismissing) {
        return 0.3f;
    }
    
    return 1.0f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *containerView = [transitionContext containerView];
    
    if(self.animationStyle == RMActionControllerTransitionStylePresenting) {
        UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        if([toVC isKindOfClass:[RMActionController class]]) {
            RMActionController *actionController = (RMActionController *)toVC;
            
            [actionController setupTopContainersTopMarginConstraint];
            
            actionController.backgroundView.alpha = 0;
            [containerView addSubview:actionController.backgroundView];
            [containerView addSubview:actionController.view];
            
            NSDictionary *bindingsDict = @{@"BGView": actionController.backgroundView};
            
            [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[BGView]-(0)-|" options:0 metrics:nil views:bindingsDict]];
            [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[BGView]-(0)-|" options:0 metrics:nil views:bindingsDict]];
            
            [containerView addConstraint:[NSLayoutConstraint constraintWithItem:actionController.view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
            [containerView addConstraint:[NSLayoutConstraint constraintWithItem:actionController.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
            
            actionController.yConstraint = [NSLayoutConstraint constraintWithItem:actionController.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
            [containerView addConstraint:actionController.yConstraint];
            
            [containerView setNeedsUpdateConstraints];
            [containerView layoutIfNeeded];
            
            [containerView removeConstraint:actionController.yConstraint];
            actionController.yConstraint = [NSLayoutConstraint constraintWithItem:actionController.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
            [containerView addConstraint:actionController.yConstraint];
            
            [containerView setNeedsUpdateConstraints];
            
            CGFloat damping = 1.0f;
            CGFloat duration = 0.3f;
            if(!actionController.disableBouncingEffects) {
                damping = 0.6f;
                duration = 1.0f;
            }
            
            [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:damping initialSpringVelocity:1 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
                actionController.backgroundView.alpha = 1;
                
                [containerView layoutIfNeeded];
            } completion:^(BOOL finished) {
                [transitionContext completeTransition:YES];
            }];
        }
    } else if(self.animationStyle == RMActionControllerTransitionStyleDismissing) {
        UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        if([fromVC isKindOfClass:[RMActionController class]]) {
            RMActionController *actionController = (RMActionController *)fromVC;
            
            [containerView removeConstraint:actionController.yConstraint];
            actionController.yConstraint = [NSLayoutConstraint constraintWithItem:actionController.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
            [containerView addConstraint:actionController.yConstraint];
            
            [containerView setNeedsUpdateConstraints];
            
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                actionController.backgroundView.alpha = 0;
                
                [containerView layoutIfNeeded];
            } completion:^(BOOL finished) {
                [actionController.view removeFromSuperview];
                [actionController.backgroundView removeFromSuperview];
                
                actionController.hasBeenDismissed = NO;
                [transitionContext completeTransition:YES];
            }];
        }
    }
}

@end
