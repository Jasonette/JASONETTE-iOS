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
        DTLogWarning(@"Empty className given");
        className = @"";
    }

    Class class = NSClassFromString (className);

    if (!class) {
        NSString * prefix = [[NSBundle mainBundle] infoDictionary][@"CFBundleExecutable"];
        // Swift Classes contains the bundle executable as prefix
        className = [NSString stringWithFormat:@"%@.%@", prefix, className];
        class = NSClassFromString (className);
    }
    
    if(!class) {
        // Search in the services for a lowercase string className
        class = [[Jason client].services[[className lowercaseString]] class];
    }

    if (!class) {
        DTLogWarning (@"Class %@ not found", className);
        class = nil;
    }

    return class;
}

@end
