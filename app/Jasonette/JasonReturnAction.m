//
//  JasonReturnAction.m
//  Jasonette
//
//  Created by e on 1/4/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonReturnAction.h"

@implementation JasonReturnAction
// continue off where we left off from the caller action
// 
- (void)success {
    JasonMemory *memory = [JasonMemory client];
    NSDictionary *caller = memory._caller;
    
    // 1. propagate the memory._register to the next action
    // 2. set the stack with the caller's success action
    if(caller[@"success"]){
        [[Jason client] call: caller[@"success"] with:memory._register];
    } else {
        [[Jason client] finish];
    }
}
- (void)error{
    JasonMemory *memory = [JasonMemory client];
    NSDictionary *caller = memory._caller;
    
    // 1. propagate the memory._register to the next action
    // 2. set the stack with the caller's success action
    if(caller[@"error"]){
        [[Jason client] call: caller[@"error"] with:memory._register];
    } else {
        [[Jason client] finish];
    }
}
@end
