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

#import "UIImage+MaterialRTL.h"

#import <CoreGraphics/CoreGraphics.h>
#import <CoreImage/CoreImage.h>

/** Returns the horizontally flipped version of the given UIImageOrientation. */
static UIImageOrientation MDFRTLMirroredOrientation(UIImageOrientation sourceOrientation) {
  switch (sourceOrientation) {
    case UIImageOrientationUp:
      return UIImageOrientationUpMirrored;
    case UIImageOrientationDown:
      return UIImageOrientationDownMirrored;
    case UIImageOrientationLeft:
      return UIImageOrientationLeftMirrored;
    case UIImageOrientationRight:
      return UIImageOrientationRightMirrored;
    case UIImageOrientationUpMirrored:
      return UIImageOrientationUp;
    case UIImageOrientationDownMirrored:
      return UIImageOrientationDown;
    case UIImageOrientationLeftMirrored:
      return UIImageOrientationLeft;
    case UIImageOrientationRightMirrored:
      return UIImageOrientationRight;
  }
  NSCAssert(NO, @"Invalid enumeration value %i.", (int)sourceOrientation);
  return UIImageOrientationUpMirrored;
}

/**
 Returns a copy of the image actually flipped. The orientation and scale are consumed, while the
 rendering mode is ported to the new image.
 */
static UIImage *MDFRTLFlippedImage(UIImage *image) {
  CGSize size = image.size;
  CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);

  UIGraphicsBeginImageContextWithOptions(rect.size, NO, image.scale);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetShouldAntialias(context, true);
  CGContextSetInterpolationQuality(context, kCGInterpolationHigh);

  // Note: UIKit's and CoreGraphics coordinates systems are flipped vertically (UIKit's Y axis goes
  // down, while CoreGraphics' goes up).
  switch (image.imageOrientation) {
    case UIImageOrientationUp:
      CGContextScaleCTM(context, -1, -1);
      CGContextTranslateCTM(context, -rect.size.width, -rect.size.height);
      break;
    case UIImageOrientationDown:
      // Orientation down is equivalent to a 180º rotation. The difference in coordinates systems is
      // thus sufficient and nothing needs to be down to flip the image.
      break;
    case UIImageOrientationLeft:
      CGContextRotateCTM(context, -(CGFloat)M_PI_2);
      CGContextTranslateCTM(context, -rect.size.width, 0);
      break;
    case UIImageOrientationRight:
      CGContextRotateCTM(context, (CGFloat)M_PI_2);
      CGContextTranslateCTM(context, 0, -rect.size.width);
      break;
    case UIImageOrientationUpMirrored:
      CGContextScaleCTM(context, 1, -1);
      CGContextTranslateCTM(context, 0, -rect.size.height);
      break;
    case UIImageOrientationDownMirrored:
      CGContextScaleCTM(context, -1, 1);
      CGContextTranslateCTM(context, -rect.size.width, 0);
      break;
    case UIImageOrientationLeftMirrored:
      CGContextRotateCTM(context, -(CGFloat)M_PI_2);
      CGContextTranslateCTM(context, -rect.size.width, 0);
      CGContextScaleCTM(context, -1, 1);
      CGContextTranslateCTM(context, -rect.size.width, 0);
      break;
    case UIImageOrientationRightMirrored:
      CGContextRotateCTM(context, (CGFloat)M_PI_2);
      CGContextTranslateCTM(context, 0, -rect.size.width);
      CGContextScaleCTM(context, -1, 1);
      CGContextTranslateCTM(context, -rect.size.width, 0);
      break;
    default:
      NSCAssert(NO, @"Invalid enumeration value %i.", (int)image.imageOrientation);
  }

  // If the UIImage is not backed by a CGImage, create one from the CIImage
  if (image.CGImage) {
    CGContextDrawImage(context, rect, image.CGImage);
  } else if (image.CIImage) {
    CIImage *coreImage = image.CIImage;
    CIContext *coreImageContext = [CIContext context];
    CGImageRef coreGraphicsImage =
        [coreImageContext createCGImage:coreImage fromRect:coreImage.extent];
    if (coreGraphicsImage) {
      CGContextDrawImage(context, rect, coreGraphicsImage);
      CFRelease(coreGraphicsImage);
      coreGraphicsImage = NULL;
    }
  } else {
    NSCAssert(NO, @"Unable to flip image without a CGImage or CIImage backing store");
  }

  UIImage *drawnImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  // Port the rendering mode.
  UIImage *flippedImage = [drawnImage imageWithRenderingMode:image.renderingMode];
  return flippedImage;
}

@implementation UIImage (MaterialRTL)

- (UIImage *)mdf_imageWithHorizontallyFlippedOrientation {
  // On iOS 10 and above, UIImage supports the imageWithHorizontallyFlippedOrientation method.
  // Otherwise, we manually manipulate the image.
  if ([self respondsToSelector:@selector(imageWithHorizontallyFlippedOrientation)]) {
    //TODO: (#22) Replace with @availability when we adopt Xcode 9 as our minimum supported version.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
    return [self imageWithHorizontallyFlippedOrientation];
#pragma clang diagnostic pop
  } else {
    UIImage *mirroredImage;
    UIImageOrientation mirroredOrientation = MDFRTLMirroredOrientation(self.imageOrientation);
    if (self.CGImage) {
      CGImageRef _Nonnull image = (CGImageRef _Nonnull)self.CGImage;
      mirroredImage = [[self class] imageWithCGImage:image
                                               scale:self.scale
                                         orientation:mirroredOrientation];
    } else if (self.CIImage) {
      CIImage * _Nonnull image = (CIImage * _Nonnull)self.CIImage;
      mirroredImage = [[self class] imageWithCIImage:image
                                               scale:self.scale
                                         orientation:mirroredOrientation];
    }

    // If we were unsuccessful, manually flip the image using a Core Graphics context
    if (!mirroredImage) {
      mirroredImage = MDFRTLFlippedImage(self);
    }

    // On iOS9- [UIImage imageWithCGImage:scale:orientation:] loses the rendering mode.
    // Restore it if the new renderingMode does not match the current renderingMode.
    if (mirroredImage.renderingMode != self.renderingMode) {
      mirroredImage = [mirroredImage imageWithRenderingMode:self.renderingMode];
    }

    return mirroredImage;
  }
}

@end
