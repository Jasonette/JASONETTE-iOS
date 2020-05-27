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

#import "UIApplication+MDCAppExtensions.h"

@implementation UIApplication (MDCAppExtensions)

+ (UIApplication *)mdc_safeSharedApplication {
  static UIApplication *application;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (![self mdc_isAppExtension]) {
      // We can't call sharedApplication directly or else this won't build for app extensions.
      application = [[UIApplication class] performSelector:@selector(sharedApplication)];
    }
  });
  return application;
}

+ (BOOL)mdc_isAppExtension {
  static BOOL isAppExtension;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    isAppExtension =
        [[[NSBundle mainBundle] executablePath] rangeOfString:@".appex/"].location != NSNotFound;
  });
  return isAppExtension;
}

@end
