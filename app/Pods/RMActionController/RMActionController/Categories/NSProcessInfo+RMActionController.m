//
//  NSProcessInfo+RMActionController.m
//  RMActionController-Demo
//
//  Created by Roland Moers on 19.11.16.
//  Copyright © 2016 Roland Moers. All rights reserved.
//

#import "NSProcessInfo+RMActionController.h"

@implementation NSProcessInfo (RMActionController)

+ (BOOL)runningAtLeastiOS9 {
    return [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){9, 0, 0}];
}

@end
