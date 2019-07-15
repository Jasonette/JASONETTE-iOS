//
//  JasonConstraintsViewController.m
//  Jasonette
//
//  Created by Camilo Castro on 15-07-19.
//  Copyright © 2019 Jasonette. All rights reserved.
//

#import "JasonConstraintsViewController.h"

@interface JasonConstraintsViewController ()

@end

@implementation JasonConstraintsViewController

- (void) loadBounds {
    [self.fullscreen setNeedsDisplay];
    
    NSLog(@"Loaded Frame %@", NSStringFromCGRect(self.fullscreen.frame));
}

+ (CGRect) fullScreenBounds
{
    UIStoryboard * storyboard = [UIStoryboard
                                 storyboardWithName:@"JasonConstraints"
                                 bundle:nil];
    
    JasonConstraintsViewController * controller = [storyboard instantiateViewControllerWithIdentifier:@"fullscreen"];
    
    [controller loadBounds];
    
    UIView * fullscreen = controller.fullscreen;
    
    storyboard = nil;
    controller = nil;
    
    return fullscreen.frame;
}

@end
