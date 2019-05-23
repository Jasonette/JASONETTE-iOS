//
//  UIScreen+DTFoundation.m
//  DTFoundation
//
//  Created by Johannes Marbach on 16.10.17.
//  Copyright © 2017 Cocoanetics. All rights reserved.
//

#import "UIScreen+DTFoundation.h"

@implementation UIScreen (DTFoundation)

- (UIInterfaceOrientation)orientation {
    CGPoint point = [self.coordinateSpace convertPoint:CGPointZero toCoordinateSpace:self.fixedCoordinateSpace];
    if (point.x == 0 && point.y == 0) {
        return UIInterfaceOrientationPortrait;
    } else if (point.x != 0 && point.y != 0) {
        return UIInterfaceOrientationPortraitUpsideDown;
    } else if (point.x == 0 && point.y != 0) {
        return UIInterfaceOrientationLandscapeLeft;
    } else if (point.x != 0 && point.y == 0) {
        return UIInterfaceOrientationLandscapeRight;
    } else {
        return UIInterfaceOrientationUnknown;
    }
}

@end
