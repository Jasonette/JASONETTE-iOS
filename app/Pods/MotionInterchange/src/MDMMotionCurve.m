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

#import "MDMMotionCurve.h"

MDMMotionCurve MDMMotionCurveMakeBezier(CGFloat p1x, CGFloat p1y, CGFloat p2x, CGFloat p2y) {
  return _MDMBezier(p1x, p1y, p2x, p2y);
}

MDMMotionCurve MDMMotionCurveMakeSpring(CGFloat mass, CGFloat tension, CGFloat friction) {
  return MDMMotionCurveMakeSpringWithInitialVelocity(mass, tension, friction, 0);
}

MDMMotionCurve MDMMotionCurveMakeSpringWithInitialVelocity(CGFloat mass,
                                                           CGFloat tension,
                                                           CGFloat friction,
                                                           CGFloat initialVelocity) {
  return _MDMSpringWithInitialVelocity(mass, tension, friction, initialVelocity);
}

MDMMotionCurve MDMMotionCurveFromTimingFunction(CAMediaTimingFunction *timingFunction) {
  float pt1[2];
  float pt2[2];
  [timingFunction getControlPointAtIndex:1 values:pt1];
  [timingFunction getControlPointAtIndex:2 values:pt2];
  return MDMMotionCurveMakeBezier(pt1[0], pt1[1], pt2[0], pt2[1]);
}

MDMMotionCurve MDMMotionCurveReversedBezier(MDMMotionCurve motionCurve) {
  MDMMotionCurve reversed = motionCurve;
  if (motionCurve.type == MDMMotionCurveTypeBezier) {
    reversed.data[0] = 1 - motionCurve.data[2];
    reversed.data[1] = 1 - motionCurve.data[3];
    reversed.data[2] = 1 - motionCurve.data[0];
    reversed.data[3] = 1 - motionCurve.data[1];
  }
  return reversed;
}
