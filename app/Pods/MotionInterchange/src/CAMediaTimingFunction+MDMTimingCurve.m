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

#import "CAMediaTimingFunction+MDMTimingCurve.h"

@implementation CAMediaTimingFunction (MotionInterchangeExtension)

- (CAMediaTimingFunction *)mdm_reversed {
  float pt1[2];
  float pt2[2];
  [self getControlPointAtIndex:1 values:pt1];
  [self getControlPointAtIndex:2 values:pt2];

  float reversedPt1[2];
  float reversedPt2[2];
  reversedPt1[0] = 1 - pt2[0];
  reversedPt1[1] = 1 - pt2[1];
  reversedPt2[0] = 1 - pt1[0];
  reversedPt2[1] = 1 - pt1[1];
  return [CAMediaTimingFunction functionWithControlPoints:reversedPt1[0] :reversedPt1[1]
                                                         :reversedPt2[0] :reversedPt2[1]];
}

- (CGPoint)mdm_point1 {
  float point[2];
  [self getControlPointAtIndex:1 values:point];
  return CGPointMake(point[0], point[1]);
}

- (CGPoint)mdm_point2 {
  float point[2];
  [self getControlPointAtIndex:2 values:point];
  return CGPointMake(point[0], point[1]);
}

@end
