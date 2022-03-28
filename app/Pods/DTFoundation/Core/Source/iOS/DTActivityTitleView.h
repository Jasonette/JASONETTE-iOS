//
//  DTActivityTitleView.h
//  DTFoundation
//
//  Created by Rene Pirringer on 12.09.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <Availability.h>
#import <TargetConditionals.h>

#if TARGET_OS_IPHONE && !TARGET_OS_WATCH

#import <UIKit/UIKit.h>

/**
 Alternative view for showing titles with a configurable activity indicator
 instead of default title view in navigationItem.
 */
@interface DTActivityTitleView : UIView

/**
 Title that is shown
 */
@property (nonatomic, copy) NSString *title;

/**
 When busy is set to YES the activity indicator starts spinning
 When set to NO the activity indicator stops spinning
 */
@property (nonatomic, assign) BOOL busy;

@end

#endif
