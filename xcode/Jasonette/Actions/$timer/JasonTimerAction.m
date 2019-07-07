//
//  JasonTimerAction.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonTimerAction.h"

@implementation JasonTimerAction
- (void)start{
    if(!self.VC.timers){
        self.VC.timers = [[NSMutableDictionary alloc] init];
    }
    if(self.options){
        NSTimeInterval interval = (NSTimeInterval)[self.options[@"interval"] doubleValue];
        NSString *name = self.options[@"name"];
        BOOL repeats = NO;
        if(self.options[@"repeats"]){
            repeats = YES;
        }
        
        // If there's a pre-existing timer with the name, stop it.
        if(self.VC.timers[name]){
            [self.VC.timers[name] invalidate];
        }
        
        NSDictionary *action = self.options[@"action"];
        //NSTimer *timer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(func:) userInfo:action repeats:repeats];
        //NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(func:) userInfo:action repeats:repeats];
        NSTimer *timer = [NSTimer timerWithTimeInterval:interval
                                                 target:self
                                               selector:@selector(func:)
                                               userInfo:action repeats:repeats];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];

        self.VC.timers[name] = timer;
    }
    [[Jason client] success];
}
- (void)func: (NSTimer *)timer{
    NSDictionary *action = timer.userInfo;
    if([Jason client].touching) {
    } else {
        if(action && action.count > 0){
            [[Jason client] call:action];
        }
    }
}
- (void)stop{
    if(!self.VC.timers){
        self.VC.timers = [[NSMutableDictionary alloc] init];
    }
    if(self.options){
        NSString *name = self.options[@"name"];
        if(name){
            if(self.VC.timers[name]){
                [self.VC.timers[name] invalidate];
                [self.VC.timers removeObjectForKey:name];
            }
        } else {
            // if name doesn't exist, just stop all timers
            for(NSString *timer_name in self.VC.timers){
                NSTimer *timer = self.VC.timers[timer_name];
                [timer invalidate];
                [self.VC.timers removeObjectForKey:timer_name];
            }
        }
    }
    [[Jason client] success];
}

@end
