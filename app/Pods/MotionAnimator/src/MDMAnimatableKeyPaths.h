/*
 Copyright 2017-present The Material Motion Authors. All Rights Reserved.

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

#import <Availability.h>
#import <Foundation/Foundation.h>

// This macro is introduced in Xcode 9.
#ifndef CF_TYPED_ENUM // What follows is backwards compat for Xcode 8 and below.
#if __has_attribute(swift_wrapper)
#define CF_TYPED_ENUM __attribute__((swift_wrapper(enum)))
#else
#define CF_TYPED_ENUM
#endif
#endif

/**
 A representation of an animatable key path.

 This is NOT an exhaustive list of animatable properties; it only documents properties that are
 officially supported by the animator. If you animate unsupported properties then the resulting
 behavior is undefined.

 Each property documents whether or not it supports being animated additively. This affects the
 behavior of animations when a MDMMotionAnimator's additive property is enabled. Properties that
 support additive animations can change direction mid-way through the animation while appearing
 to preserve momentum. Properties that do not support additive animation will instantly start
 animating towards the new toValue.
 */
NS_SWIFT_NAME(AnimatableKeyPath)
typedef NSString * const MDMAnimatableKeyPath CF_TYPED_ENUM;

/**
 Anchor point.

 Equivalent UIView property: N/A
 Equivalent CALayer property: anchorPoint
 Expected value type: CGPoint or NSValue (containing a CGPoint).
 Additive animation supported: No.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathAnchorPoint NS_SWIFT_NAME(anchorPoint);

/**
 Background color.

 Equivalent UIView property: backgroundColor
 Equivalent CALayer property: backgroundColor
 Expected value type: UIColor or CGColor.
 Additive animation supported: No.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathBackgroundColor NS_SWIFT_NAME(backgroundColor);

/**
 Bounds.

 Equivalent UIView property: bounds
 Equivalent CALayer property: bounds
 Expected value type: CGRect or NSValue (containing a CGRect).
 Additive animation supported: Yes.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathBounds NS_SWIFT_NAME(bounds);

/**
 Border width.

 Equivalent UIView property: N/A
 Equivalent CALayer property: borderWidth
 Expected value type: CGFloat or NSNumber.
 Additive animation supported: Yes.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathBorderWidth NS_SWIFT_NAME(borderWidth);

/**
 Border color.

 Equivalent UIView property: N/A
 Equivalent CALayer property: borderColor
 Expected value type: UIColor or CGColor.
 Additive animation supported: No.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathBorderColor NS_SWIFT_NAME(borderColor);

/**
 Corner radius.

 Equivalent UIView property: N/A
 Equivalent CALayer property: cornerRadius
 Expected value type: CGFloat or NSNumber.
 Additive animation supported: Yes.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathCornerRadius NS_SWIFT_NAME(cornerRadius);

/**
 Height.

 Equivalent UIView property: bounds.size.height
 Equivalent CALayer property: bounds.size.height
 Expected value type: CGFloat or NSNumber.
 Additive animation supported: Yes.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathHeight NS_SWIFT_NAME(height);

/**
 Opacity.

 Equivalent UIView property: alpha
 Equivalent CALayer property: opacity
 Expected value type: CGFloat or NSNumber.
 Additive animation supported: Yes.
 TODO( https://github.com/material-motion/motion-animator-objc/issues/61 ):
      Disable additive animations for opacity.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathOpacity NS_SWIFT_NAME(opacity);

/**
 Position.

 Equivalent UIView property: center if the layer's anchorPoint is 0.5, 0.5. N/A otherwise.
 Equivalent CALayer property: position
 Expected value type: CGPoint or NSValue (containing a CGPoint).
 Additive animation supported: Yes.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathPosition NS_SWIFT_NAME(position);

/**
 Rotation.

 Equivalent UIView property: transform.rotation.z
 Equivalent CALayer property: transform.rotation.z
 Expected value type: CGFloat or NSNumber.
 Additive animation supported: Yes.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathRotation NS_SWIFT_NAME(rotation);

/**
 Scale.

 Uniform scale along both the x and y axis.

 Equivalent UIView property: transform.scale
 Equivalent CALayer property: transform.scale
 Expected value type: CGFloat or NSNumber.
 Additive animation supported: Yes.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathScale NS_SWIFT_NAME(scale);

/**
 Shadow color.

 Equivalent UIView property: N/A
 Equivalent CALayer property: shadowColor
 Expected value type: UIColor or CGColor.
 Additive animation supported: No.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathShadowColor NS_SWIFT_NAME(shadowColor);

/**
 Shadow offset.

 Equivalent UIView property: N/A
 Equivalent CALayer property: shadowOffset
 Expected value type: CGSize or NSValue (containing a CGSize).
 Additive animation supported: Yes.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathShadowOffset NS_SWIFT_NAME(shadowOffset);

/**
 Shadow opacity.

 Equivalent UIView property: N/A
 Equivalent CALayer property: shadowOpacity
 Expected value type: CGFloat or NSNumber.
 Additive animation supported: Yes.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathShadowOpacity NS_SWIFT_NAME(shadowOpacity);

/**
 Shadow radius.

 Equivalent UIView property: N/A
 Equivalent CALayer property: shadowRadius
 Expected value type: CGFloat or NSNumber.
 Additive animation supported: Yes.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathShadowRadius NS_SWIFT_NAME(shadowRadius);

/**
 Stroke start.

 Equivalent UIView property: N/A
 Equivalent CALayer property: N/A
 Equivalent CAShapeLayer property: strokeStart
 Expected value type: CGFloat or NSNumber.
 Additive animation supported: Yes.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathStrokeStart NS_SWIFT_NAME(strokeStart);

/**
 Stroke end.

 Equivalent UIView property: N/A
 Equivalent CALayer property: N/A
 Equivalent CAShapeLayer property: strokeEnd
 Expected value type: CGFloat or NSNumber.
 Additive animation supported: Yes.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathStrokeEnd NS_SWIFT_NAME(strokeEnd);

/**
 Transform.

 Equivalent UIView property: transform (2d only)
 Equivalent CALayer property: transform (3d)
 Expected value type: CGAffineTransform, CATransform or NSValue with either transform type.
                      CGAffineTransform value types will be converted to CATransform.
 Additive animation supported: Yes.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathTransform NS_SWIFT_NAME(transform);

/**
 Width.

 Equivalent UIView property: bounds.size.width
 Equivalent CALayer property: bounds.size.width
 Expected value type: CGFloat or NSNumber.
 Additive animation supported: Yes.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathWidth NS_SWIFT_NAME(width);

/**
 X position.

 Equivalent UIView property: center.x if the layer's anchorPoint.x is 0.5. N/A otherwise.
 Equivalent CALayer property: position.x
 Expected value type: CGFloat or NSNumber.
 Additive animation supported: Yes.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathX NS_SWIFT_NAME(x);

/**
 Y position.

 Equivalent UIView property: center.y if the layer's anchorPoint.y is 0.5. N/A otherwise.
 Equivalent CALayer property: position.y
 Expected value type: CGFloat or NSNumber.
 Additive animation supported: Yes.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathY NS_SWIFT_NAME(y);

/**
 Z position.

 Equivalent UIView property: N/A
 Equivalent CALayer property: zPosition
 Expected value type: CGFloat or NSNumber.
 Additive animation supported: Yes.
 */
FOUNDATION_EXPORT MDMAnimatableKeyPath MDMKeyPathZ NS_SWIFT_NAME(z);
