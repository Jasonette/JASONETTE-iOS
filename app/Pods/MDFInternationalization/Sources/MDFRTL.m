/*
 Copyright 2016-present Google Inc. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MDFRTL.h"

UIViewAutoresizing MDFLeadingMarginAutoresizingMaskForLayoutDirection(
    UIUserInterfaceLayoutDirection layoutDirection) {
  switch (layoutDirection) {
    case UIUserInterfaceLayoutDirectionLeftToRight:
      return UIViewAutoresizingFlexibleLeftMargin;
    case UIUserInterfaceLayoutDirectionRightToLeft:
      return UIViewAutoresizingFlexibleRightMargin;
  }
  NSCAssert(NO, @"Invalid enumeration value %i.", (int)layoutDirection);
  return UIViewAutoresizingFlexibleLeftMargin;
}

UIViewAutoresizing MDFTrailingMarginAutoresizingMaskForLayoutDirection(
    UIUserInterfaceLayoutDirection layoutDirection) {
  switch (layoutDirection) {
    case UIUserInterfaceLayoutDirectionLeftToRight:
      return UIViewAutoresizingFlexibleRightMargin;
    case UIUserInterfaceLayoutDirectionRightToLeft:
      return UIViewAutoresizingFlexibleLeftMargin;
  }
  NSCAssert(NO, @"Invalid enumeration value %i.", (int)layoutDirection);
  return UIViewAutoresizingFlexibleRightMargin;
}

CGRect MDFRectFlippedHorizontally(CGRect frame, CGFloat containerWidth) {
  CGRect flippedRect = CGRectStandardize(frame);
  CGFloat leadingInset = CGRectGetMinX(flippedRect);
  CGFloat width = CGRectGetWidth(flippedRect);
  flippedRect.origin.x = containerWidth - leadingInset - width;

  return flippedRect;
}

UIEdgeInsets MDFInsetsFlippedHorizontally(UIEdgeInsets insets) {
  UIEdgeInsets flippedInsets = insets;
  flippedInsets.left = insets.right;
  flippedInsets.right = insets.left;

  return flippedInsets;
}

UIEdgeInsets MDFInsetsMakeWithLayoutDirection(CGFloat top,
                                              CGFloat leading,
                                              CGFloat bottom,
                                              CGFloat trailing,
                                              UIUserInterfaceLayoutDirection layoutDirection) {
  switch (layoutDirection) {
    case UIUserInterfaceLayoutDirectionLeftToRight:
      return UIEdgeInsetsMake(top, leading, bottom, trailing);
    case UIUserInterfaceLayoutDirectionRightToLeft:
      return UIEdgeInsetsMake(top, trailing, bottom, leading);
  }
  NSCAssert(NO, @"Invalid enumeration value %i.", (int)layoutDirection);
  return UIEdgeInsetsMake(top, leading, bottom, trailing);
}
