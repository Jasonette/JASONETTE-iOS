//
//  JDStatusBarView.m
//  JDStatusBarNotificationExample
//
//  Created by Markus on 04.12.13.
//  Copyright (c) 2013 Markus. All rights reserved.
//

#import "JDStatusBarLayoutMarginHelper.h"

UIEdgeInsets JDStatusBarRootVCLayoutMargin(void)
{
  UIEdgeInsets layoutMargins = [[[[[UIApplication sharedApplication] keyWindow] rootViewController] view] layoutMargins];
  if (layoutMargins.top > 8 && layoutMargins.bottom > 8) {
    return layoutMargins;
  } else {
    return UIEdgeInsetsZero;  // ignore default margins
  }
}
