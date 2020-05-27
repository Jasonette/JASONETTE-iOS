//
//  JasonNSSClassFromString.m
//  Jasonette
//
//  Created by Jasonelle Team on 07-07-19.
//  Copyright © 2019 Jasonette. All rights reserved.
//

#import "JasonNSClassFromString.h"
#import "JasonLogger.h"
#import "Jason.h"

@implementation JasonNSClassFromString

+ (nullable Class)classFromString:(nonnull NSString *)className
{
    if (!className || [className isEqualToString:@""]) {
        DTLogWarning (@"Empty className given");
        className = @"";
    }

    Class class = NSClassFromString (className);

    if (!class) {
        // Search in the services for a lowercase string className
        DTLogDebug (@"Searching class %@ in extensions as %@", className, [className lowercaseString]);
        class = [[Jason client].services[[className lowercaseString]] class];
    }

    if (!class) {
        NSString * prefix = [[NSBundle mainBundle] infoDictionary][@"CFBundleExecutable"];
        // Swift Classes contains the bundle executable as prefix
        NSString * swiftClassName = [NSString stringWithFormat:@"%@.%@", prefix, className];

        DTLogDebug (@"Searching class %@ in Swift Format %@", className, swiftClassName);
        class = NSClassFromString (swiftClassName);

        if (!class) {
            class = [[Jason client].services[[swiftClassName lowercaseString]] class];
        }
    }

    if (!class) {
        DTLogWarning (@"Class %@ not found", className);
        class = nil;
    } else {
        DTLogDebug (@"Class %@ found", NSStringFromClass (class));
    }

    return class;
}

@end
