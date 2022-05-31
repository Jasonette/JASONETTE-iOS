//
// DTFoundation 
//
// Created by rene on 25.11.13.
// Copyright 2013 Drobnik.com. All rights reserved.
//
// 
//

#import <Availability.h>
#import <TargetConditionals.h>

#if TARGET_OS_IPHONE && !TARGET_OS_WATCH

#import <UIKit/UIKit.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIGestureRecognizerSubclass.h>


@interface DTSidePanelPanGestureRecognizer : UIPanGestureRecognizer
@end

#endif
