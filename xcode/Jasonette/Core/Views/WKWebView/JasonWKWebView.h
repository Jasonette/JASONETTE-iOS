//
//  JasonWKWebView.h
//  Jasonette
//
//  Created by Camilo Castro on 13-07-19.
//  Copyright © 2019 Jasonette. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JasonViewController.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Handles the standard configuration for WKWebViews
 */
@interface JasonWKWebView : NSObject

/**
 Calculates the correct bounds for the controller depending on the device constraints

 @param controller JasonViewController instance
 @param device [UIDevice device]
 @return CGRect with bounds
 */
+ (CGRect) getBoundsForController:(nonnull JasonViewController *) controller inDevice:(nonnull UIDevice *) device;
@end

NS_ASSUME_NONNULL_END
