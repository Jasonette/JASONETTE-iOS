//
//  DTPieProgressIndicator.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 16.05.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/**
 A Progress indicator shaped like a pie chart. If you don't specify a color then the current tintColor is used. This is useful when using it as a subview of a UIVisualEffectsView with vibrancy effect. Then all subviews using tintColor have the vibrancy applied.
 */

@interface DTPieProgressIndicator : UIView

/**
 The progress in percent
 */
@property (nonatomic, assign) float progressPercent;

/**
 The color of the pie
 */
@property (nonatomic, strong) UIColor *color;

/**
 Creates a pie progress indicator of the correct size
 */
+ (DTPieProgressIndicator *)pieProgressIndicator;

@end
