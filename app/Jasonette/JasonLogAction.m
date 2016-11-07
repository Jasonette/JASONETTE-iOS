//
//  JasonLogAction.m
//  Jasonette
//
//  Copyright © 2016 seletz. All rights reserved.
//

#include <asl.h>
#import "JasonLogAction.h"

@implementation JasonLogAction
- (void)info {
    if(self.options){
        NSString *message = self.options[@"text"];
        asl_log(NULL, NULL, ASL_LEVEL_INFO, "%s", [message UTF8String]);
    }
    [[Jason client] success];
}
- (void)debug {
    if(self.options){
        NSString *message = self.options[@"text"];
        asl_log(NULL, NULL, ASL_LEVEL_DEBUG, "%s", [message UTF8String]);
        NSLog(@"DEBUG: %@", message);
    }
    [[Jason client] success];
}
- (void)error {
    if(self.options){
        NSString *message = self.options[@"text"];
        asl_log(NULL, NULL, ASL_LEVEL_ERR, "%s", [message UTF8String]);
        NSLog(@"ERROR: %@", message);
    }
    [[Jason client] success];
}

@end
