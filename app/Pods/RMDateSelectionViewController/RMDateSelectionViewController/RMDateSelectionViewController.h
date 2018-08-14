//
//  RMDateSelectionViewController.h
//  RMDateSelectionViewController
//
//  Created by Roland Moers on 26.10.13.
//  Copyright (c) 2013-2015 Roland Moers
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <RMActionController/RMActionController.h>

/**
 *  RMDateSelectionViewController is an iOS control for selecting a date using UIDatePicker in a UIActionSheet like fashon. When a RMDateSelectionViewController is shown the user gets the opportunity to select a date using a UIDatePicker.
 *
 *  RMDateSelectionViewController supports bouncing effects when animating the date selection view controller. In addition, motion effects are supported while showing the date selection view controller. Both effects can be disabled by using the properties called disableBouncingWhenShowing and disableMotionEffects.
 *
 *  On iOS 8 and later Apple opened up their API for blurring the background of UIViews. RMDateSelectionViewController makes use of this API. The type of the blur effect can be changed by using the blurEffectStyle property. If you want to disable the blur effect you can do so by using the disableBlurEffects property.
 *
 *  @warning RMDateSelectionViewController is not designed to be reused. Each time you want to display a RMDateSelectionViewController a new instance should be created. If you want to set a specific date before displaying, you can do so by using the datePicker property.
 */
@interface RMDateSelectionViewController : RMActionController <UIDatePicker *>

/**
 *  The UIDatePicker instance used by RMDateSelectionViewController.
 *
 *  Use this property to access the date picker and to set options like minuteInterval and others.
 */
@property (nonatomic, readonly) UIDatePicker *datePicker;

@end
