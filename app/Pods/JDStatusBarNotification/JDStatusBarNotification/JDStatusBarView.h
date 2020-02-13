//
//  JDStatusBarView.h
//  JDStatusBarNotificationExample
//
//  Created by Markus on 04.12.13.
//  Copyright (c) 2013 Markus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JDStatusBarStyle.h"

NS_ASSUME_NONNULL_BEGIN

@interface JDStatusBarView : UIView
@property (nonatomic, strong, readonly) UILabel *textLabel;
@property (nonatomic, strong, readonly) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, assign) CGFloat textVerticalPositionAdjustment;
@property (nonatomic, assign) JDStatusBarHeightForIPhoneX heightForIPhoneX;
@end

NS_ASSUME_NONNULL_END
