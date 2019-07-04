//
//  PHFDelegateChain.h
//  PHFDelegateChain
//
//  Created by Philipe Fatio on 28.05.12.
//  Copyright (c) 2012 loqize.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PHFDelegateChain : NSProxy

+ (id)delegateChainWithObjects:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION;
- (id)__initWithObjectsInArray:(NSArray *)objects;

@property (nonatomic, assign, getter=__isBreaking, setter=__setBreaking:) BOOL breaking;

- (NSMutableArray *)__objects;
- (void)__setObjects:(NSArray *)objects;

@end
