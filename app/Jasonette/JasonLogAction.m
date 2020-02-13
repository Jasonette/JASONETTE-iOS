//
//  JasonLogAction.m
//  Jasonette
//
//  Copyright © 2016 seletz. All rights reserved.
//

@import os.log;
#import "JasonLogAction.h"

@implementation JasonLogAction
- (void)info {
    if(self.options){
        NSString *message = self.options[@"text"];
        os_log(OS_LOG_DEFAULT, "%s", [message UTF8String]);
    }
    [[Jason client] success];
}
- (void)debug {
    if(self.options){
        NSString *message = self.options[@"text"];
        os_log(OS_LOG_DEFAULT, "%s", [message UTF8String]);
        NSLog(@"DEBUG: %@", message);
    }
    [[Jason client] success];
}
- (void)error {
    if(self.options){
        NSString *message = self.options[@"text"];
        os_log(OS_LOG_DEFAULT, "%s", [message UTF8String]);
        NSLog(@"ERROR: %@", message);
    }
    [[Jason client] success];
}

@end
