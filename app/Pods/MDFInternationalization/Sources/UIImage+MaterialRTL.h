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
 Backporting of iOS 10's [UIImage imageWithHorizontallyFlippedOrientation].
 */

@interface UIImage (MaterialRTL)

/**
 On iOS 10 and above, calls [UIImage imageWithHorizontallyFlippedOrientation].
 Otherwise manually flips the image and returns the result.

 @return A horizontally mirrored version of this image.
 */
- (nonnull UIImage *)mdf_imageWithHorizontallyFlippedOrientation;

@end
