// Copyright 2020-present the Material Components for iOS authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <UIKit/UIKit.h>

@class MDCActivityIndicator;

/**
 Delegate protocol for the MDCActivityIndicator.
 */
@protocol MDCActivityIndicatorDelegate <NSObject>

@optional
/**
 When stop is called, the spinner gracefully animates out using opacity and stroke width.
 This method is called after that fade-out animation completes.

 @param activityIndicator Caller
 */
- (void)activityIndicatorAnimationDidFinish:(nonnull MDCActivityIndicator *)activityIndicator;

/**
 When setIndicatorMode:animated: is called the spinner animates the transition from the current
 mode to the new mode. This method is called after the animation completes or immediately if no
 animation is requested.

 @param activityIndicator Caller
 */
- (void)activityIndicatorModeTransitionDidFinish:(nonnull MDCActivityIndicator *)activityIndicator;

@end
