// Copyright 2015-present the Material Components for iOS authors. All Rights Reserved.
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

/**
 UIApplication extension for working with sharedApplication inside of app extensions.
 */
@interface UIApplication (MDCAppExtensions)

/**
 Returns sharedApplication if it is available otherwise returns nil.

 This is a wrapper around sharedApplication which is safe to compile and use in app extensions.
 */
+ (UIApplication *)mdc_safeSharedApplication;

/**
 Returns YES if called inside an application extension otherwise returns NO.
 */
+ (BOOL)mdc_isAppExtension;

@end
