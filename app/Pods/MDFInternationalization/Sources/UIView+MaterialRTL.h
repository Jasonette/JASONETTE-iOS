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
 Complete backporting of iOS 9's `-[UIView semanticContentAttribute]` and
 `+[UIView userInterfaceLayoutDirectionForSemanticContentAttribute:]`, and iOS 10's
 `-[UIView effectiveUserInterfaceLayoutDirection]` and
 `+[UIView userInterfaceLayoutDirectionForSemanticContentAttribute:relativeToLayoutDirection:]`.
 */



@interface UIView (MaterialRTL)

// UISemanticContentAttribute was added in iOS SDK 9.0 but is available on devices running earlier
// version of iOS. We ignore the partial-availability warning that gets thrown on our use of this
// symbol.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

/**
 A semantic description of the view's contents, used to determine whether the view should be flipped
 when switching between left-to-right and right-to-left layouts.

 @note Default:
   - iOS 8 and below: UISemanticContentAttributeUnspecified.
   - iOS 9 and above: same as -[UIView semanticContentAttribute]
 */
@property(nonatomic, setter=mdf_setSemanticContentAttribute:)
    UISemanticContentAttribute mdf_semanticContentAttribute;

/**
 The user interface layout direction appropriate for arranging the immediate content of this view.

 Always consult the mdf_effectiveUserInterfaceLayoutDirection of the view whose immediate content is
 being arranged or drawn. Do not assume that the value propagates through the view's subtree.

 @note
   - iOS 9 and below: same as +[UIView mdf_userInterfaceLayoutDirectionForSemanticContentAttribute:]
   - iOS 10 and above: same as -[UIView effectiveUserInterfaceLayoutDirection]
 */
@property(nonatomic, readonly)
    UIUserInterfaceLayoutDirection mdf_effectiveUserInterfaceLayoutDirection;

/**
 Returns the layout direction implied by the provided semantic content attribute relative to the
 application-wide layout direction (as returned by
 UIApplication.sharedApplication.userInterfaceLayoutDirection). However, if it's being called from
 an iOS 8 extension, it will return left-to-right every time.

 @param semanticContentAttribute The semantic content attribute.
 @return The layout direction.
 */
+ (UIUserInterfaceLayoutDirection)mdf_userInterfaceLayoutDirectionForSemanticContentAttribute:
        (UISemanticContentAttribute)semanticContentAttribute;

/**
 Returns the layout direction implied by the provided semantic content attribute relative to the
 provided layout direction. For example, when provided a layout direction of
 RightToLeft and a semantic content attribute of Playback, this method returns LeftToRight. Layout
 and drawing code can use this method to determine how to arrange elements, but might find it easier
 to query the container view's mdf_effectiveUserInterfaceLayoutDirection property instead.

 @param semanticContentAttribute The semantic content attribute.
 @param layoutDirection The layout direction to consider.
 @return The implied layout direction.
 */
+ (UIUserInterfaceLayoutDirection)
    mdf_userInterfaceLayoutDirectionForSemanticContentAttribute:
        (UISemanticContentAttribute)semanticContentAttribute
                                      relativeToLayoutDirection:
                                          (UIUserInterfaceLayoutDirection)layoutDirection;

#pragma clang diagnostic pop

@end
