//
//  JasonStack.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface JasonStack : NSObject
@property (nonatomic, strong) NSMutableArray *items;

/** @name Static Initializer */
#pragma mark Static Initializer
+ (id)stack;

/** @name Access methods */
#pragma mark Access methods
- (void)push:(id)object;
- (id)pop;

@end
