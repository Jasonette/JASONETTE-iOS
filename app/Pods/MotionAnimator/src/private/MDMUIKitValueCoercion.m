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

#import "MDMUIKitValueCoercion.h"

#import <UIKit/UIKit.h>

static BOOL IsCGAffineTransformType(id someValue) {
  if ([someValue isKindOfClass:[NSValue class]]) {
    NSValue *asValue = (NSValue *)someValue;
    const char *objCType = @encode(CGAffineTransform);
    return strncmp(asValue.objCType, objCType, strlen(objCType)) == 0;
  }
  return NO;
}

NSArray* MDMCoerceUIKitValuesToCoreAnimationValues(NSArray *values) {
  if ([[values firstObject] isKindOfClass:[UIColor class]]) {
    NSMutableArray *convertedArray = [NSMutableArray arrayWithCapacity:values.count];
    for (UIColor *color in values) {
      [convertedArray addObject:(id)color.CGColor];
    }
    values = convertedArray;

  } else if ([[values firstObject] isKindOfClass:[UIBezierPath class]]) {
    NSMutableArray *convertedArray = [NSMutableArray arrayWithCapacity:values.count];
    for (UIBezierPath *bezierPath in values) {
      [convertedArray addObject:(id)bezierPath.CGPath];
    }
    values = convertedArray;

  } else if (IsCGAffineTransformType([values firstObject])) {
    NSMutableArray *convertedArray = [NSMutableArray arrayWithCapacity:values.count];
    for (NSValue *value in values) {
      CATransform3D asTransform3D = CATransform3DMakeAffineTransform(value.CGAffineTransformValue);
      [convertedArray addObject:[NSValue valueWithCATransform3D:asTransform3D]];
    }
    values = convertedArray;
  }
  return values;
}
