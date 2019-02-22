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

#import <UIKit/UIKit.h>

/**
 Leading autoresizing mask based on layoutDirection. 'Leading' is 'Left' in
 UIUserInterfaceLayoutDirectionLeftToRight, 'Right' otherwise.

 @param layoutDirection The layout direction to consider when computing the autoresizing mask.
 @return The leading margin part of an autoresizing mask.
 */
FOUNDATION_EXPORT UIViewAutoresizing MDFLeadingMarginAutoresizingMaskForLayoutDirection(
    UIUserInterfaceLayoutDirection layoutDirection);

/**
 Trailing autoresizing masks based on layoutDirection. 'Trailing' is 'Right' in
 UIUserInterfaceLayoutDirectionLeftToRight, 'Left' otherwise.

 @param layoutDirection The layout direction to consider to compute the autoresizing mask.
 @return The trailing margin part of an autoresizing mask.
 */
FOUNDATION_EXPORT UIViewAutoresizing MDFTrailingMarginAutoresizingMaskForLayoutDirection(
    UIUserInterfaceLayoutDirection layoutDirection);

/**
 The frame to use when actually laying out a view in its superview.

 A view is conceptually positioned within its superview in terms of leading/trailing. When it's time
 to actually lay out (i.e. setting frames), you position the frame as you usually would, but if you
 are in the opposite layout direction you call this function to return a rect that has been flipped
 around the vertical axis.

 @note Example: Flipping the frame of a subview 50pts wide at 10pts from the leading edge of a
 bounding view.

 CGRect frame = CGRectMake(10, originY, 50, height);
 CGFloat containerWidth = CGRectGetWidth(self.bounds);
 if (layoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
   frame = MDFRectFlippedHorizontally(frame, containerWidth);
 }

 In LTR, frame is { { 10, originY }, { 50, height } } in a 100 wide bounding view.
 +----------------------------------------100----------------------------------------+
 |                                                                                   |
 | 10 +--------------------50--------------------+                                   |
 |    |                                          |                                   |
 |    +------------------------------------------+                                   |
 |                                                                                   |
 +----------------------------------------100----------------------------------------+

 In RTL, frame is { { 40, originY }, { 50, height } }.
 +----------------------------------------100----------------------------------------+
 |                                                                                   |
 |                                40 +--------------------50--------------------+    |
 |                                   |                                          |    |
 |                                   +------------------------------------------+    |
 |                                                                                   |
 +----------------------------------------100----------------------------------------+

 @param frame The frame to convert.
 @param containerWidth The superview's bounds's width.
 @return The frame mirrored around the vertical axis.
 */
FOUNDATION_EXPORT CGRect MDFRectFlippedHorizontally(CGRect frame, CGFloat containerWidth);


/**
 Creates a UIEdgeInsets instance with its left and right values exchanged.

 @param insets The insets we are intending to flip horizontally.
 @return Insets with the right and left values exchanged.
 */
FOUNDATION_EXPORT UIEdgeInsets MDFInsetsFlippedHorizontally(UIEdgeInsets insets);

/**
 Creates a UIEdgeInsets instance from the parameters while obeying layoutDirection.

 If layoutDirection is UIUserInterfaceLayoutDirectionLeftToRight, then the left inset is leading and
 the right inset is trailing, otherwise they are reversed.

 @param top The top inset.
 @param leading The leading inset.
 @param bottom The bottom inset.
 @param trailing The trailing inset.
 @return Insets in terms of left/right, already internationalized based on the layout direction.
 */
FOUNDATION_EXPORT UIEdgeInsets MDFInsetsMakeWithLayoutDirection(CGFloat top,
                                                                CGFloat leading,
                                                                CGFloat bottom,
                                                                CGFloat trailing,
                                                                UIUserInterfaceLayoutDirection layoutDirection);
