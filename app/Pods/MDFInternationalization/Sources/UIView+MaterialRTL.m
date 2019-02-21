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

#import "UIView+MaterialRTL.h"

#import <objc/runtime.h>

#define MDF_BASE_SDK_EQUAL_OR_ABOVE(x) \
  (defined(__IPHONE_##x) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_##x))

// UISemanticContentAttribute was added in iOS SDK 9.0 but is available on devices running earlier
// version of iOS. We ignore the partial-availability warning that gets thrown on our use of this
// symbol.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

static inline UIUserInterfaceLayoutDirection
    MDFUserInterfaceLayoutDirectionForSemanticContentAttributeRelativeToLayoutDirection(
        UISemanticContentAttribute semanticContentAttribute,
        UIUserInterfaceLayoutDirection userInterfaceLayoutDirection) {
  switch (semanticContentAttribute) {
    case UISemanticContentAttributeUnspecified:
      return userInterfaceLayoutDirection;
    case UISemanticContentAttributePlayback:
    case UISemanticContentAttributeSpatial:
    case UISemanticContentAttributeForceLeftToRight:
      return UIUserInterfaceLayoutDirectionLeftToRight;
    case UISemanticContentAttributeForceRightToLeft:
      return UIUserInterfaceLayoutDirectionRightToLeft;
  }
  NSCAssert(NO, @"Invalid enumeration value %i.", (int)semanticContentAttribute);
  return userInterfaceLayoutDirection;
}

@interface UIView (MaterialRTLPrivate)

// On iOS 9 and above, mdf_semanticContentAttribute is backed by UIKit's semanticContentAttribute.
// On iOS 8 and below, mdf_semanticContentAttribute is backed by an associated object.
@property(nonatomic, setter=mdf_setAssociatedSemanticContentAttribute:)
    UISemanticContentAttribute mdf_associatedSemanticContentAttribute;

@end

@implementation UIView (MaterialRTL)

- (UISemanticContentAttribute)mdf_semanticContentAttribute {
#if MDF_BASE_SDK_EQUAL_OR_ABOVE(9_0)
  if ([self respondsToSelector:@selector(semanticContentAttribute)]) {
    return self.semanticContentAttribute;
  } else
#endif  // MDF_BASE_SDK_EQUAL_OR_ABOVE(9_0)
  {
    return self.mdf_associatedSemanticContentAttribute;
  }
}

- (void)mdf_setSemanticContentAttribute:(UISemanticContentAttribute)semanticContentAttribute {
#if MDF_BASE_SDK_EQUAL_OR_ABOVE(9_0)
  if ([self respondsToSelector:@selector(semanticContentAttribute)]) {
    self.semanticContentAttribute = semanticContentAttribute;
  } else
#endif  // MDF_BASE_SDK_EQUAL_OR_ABOVE(9_0)
  {
    self.mdf_associatedSemanticContentAttribute = semanticContentAttribute;
  }

  // Invalidate the layout.
  [self setNeedsLayout];
}

- (UIUserInterfaceLayoutDirection)mdf_effectiveUserInterfaceLayoutDirection {
#if MDF_BASE_SDK_EQUAL_OR_ABOVE(10_0)
  if ([self respondsToSelector:@selector(effectiveUserInterfaceLayoutDirection)]) {
    return self.effectiveUserInterfaceLayoutDirection;
  } else {
    return [UIView mdf_userInterfaceLayoutDirectionForSemanticContentAttribute:
                       self.mdf_semanticContentAttribute];
  }
#else
  return [UIView mdf_userInterfaceLayoutDirectionForSemanticContentAttribute:
                     self.mdf_semanticContentAttribute];
#endif  // MDF_BASE_SDK_EQUAL_OR_ABOVE(10_0)
}

+ (UIUserInterfaceLayoutDirection)mdf_userInterfaceLayoutDirectionForSemanticContentAttribute:
        (UISemanticContentAttribute)attribute {
#if MDF_BASE_SDK_EQUAL_OR_ABOVE(9_0)
  if ([self
          respondsToSelector:@selector(userInterfaceLayoutDirectionForSemanticContentAttribute:)]) {
    return [self userInterfaceLayoutDirectionForSemanticContentAttribute:attribute];
  } else
#endif  // MDF_BASE_SDK_EQUAL_OR_ABOVE(9_0)
  {
    // If we are running in the context of an app, we query [UIApplication sharedApplication].
    // Otherwise use a default of Left-to-Right.
    UIUserInterfaceLayoutDirection applicationLayoutDirection =
        UIUserInterfaceLayoutDirectionLeftToRight;
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    // Can I use kAppBundleIdentifier ?
    if ([bundlePath hasSuffix:@".app"]) {
      // We can't call sharedApplication directly or an error gets thrown for app extensions.
      UIApplication *application =
          [[UIApplication class] performSelector:@selector(sharedApplication)];
      applicationLayoutDirection = application.userInterfaceLayoutDirection;
    }
    return [self
        mdf_userInterfaceLayoutDirectionForSemanticContentAttribute:attribute
                                          relativeToLayoutDirection:applicationLayoutDirection];
  }
}

+ (UIUserInterfaceLayoutDirection)
    mdf_userInterfaceLayoutDirectionForSemanticContentAttribute:
        (UISemanticContentAttribute)semanticContentAttribute
                                      relativeToLayoutDirection:
                                          (UIUserInterfaceLayoutDirection)layoutDirection {
#if MDF_BASE_SDK_EQUAL_OR_ABOVE(10_0)
  if ([self
          respondsToSelector:@selector(userInterfaceLayoutDirectionForSemanticContentAttribute:
                                                                     relativeToLayoutDirection:)]) {
    return [self userInterfaceLayoutDirectionForSemanticContentAttribute:semanticContentAttribute
                                               relativeToLayoutDirection:layoutDirection];
  } else {
    return MDFUserInterfaceLayoutDirectionForSemanticContentAttributeRelativeToLayoutDirection(
        semanticContentAttribute, layoutDirection);
  }
#else
  return MDFUserInterfaceLayoutDirectionForSemanticContentAttributeRelativeToLayoutDirection(
      semanticContentAttribute, layoutDirection);
#endif  // MDF_BASE_SDK_EQUAL_OR_ABOVE(10_0)
}

@end

@implementation UIView (MaterialRTLPrivate)

- (UISemanticContentAttribute)mdf_associatedSemanticContentAttribute {
  NSNumber *semanticContentAttributeNumber =
      objc_getAssociatedObject(self, @selector(mdf_semanticContentAttribute));
  if (semanticContentAttributeNumber != nil) {
    return [semanticContentAttributeNumber integerValue];
  }
  return UISemanticContentAttributeUnspecified;
}

- (void)mdf_setAssociatedSemanticContentAttribute:
        (UISemanticContentAttribute)semanticContentAttribute {
  objc_setAssociatedObject(self, @selector(mdf_semanticContentAttribute),
                           @(semanticContentAttribute), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma clang diagnostic pop
