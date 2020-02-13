//
//  RMAction+Private.h
//  RMActionController-Demo
//
//  Created by Roland Moers on 19.11.16.
//  Copyright © 2016 Roland Moers. All rights reserved.
//

#import "RMAction.h"

@interface RMAction ()

@property (nonatomic, weak, readwrite) RMActionController *controller;

@property (nonatomic, assign, readwrite) RMActionStyle style;

@property (nonatomic, copy) void (^handler)(RMActionController *controller);

- (BOOL)containsCancelAction;
- (void)executeHandlerOfCancelActionWithController:(RMActionController *)controller;

@end
