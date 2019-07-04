//
//  PHFDelegateChain.m
//  PHFDelegateChain
//
//  Created by Philipe Fatio on 28.05.12.
//  Copyright (c) 2012 loqize.me. All rights reserved.
//

#import "PHFDelegateChain.h"

const CFArrayCallBacks kPHFWeakArrayCallBacks = {0, NULL, NULL, CFCopyDescription, CFEqual};

@interface PHFDelegateChain (Helpers)

- (NSArray *)__objectsRespondingToSelector:(SEL)selector;
- (id)__firstObjectRespondingToSelector:(SEL)selector;

@end

@implementation PHFDelegateChain {
    NSMutableArray *_objects;
    Protocol *_protocol;
}

@synthesize breaking = _breaking;

+ (id)delegateChainWithObjects:(id)firstObject, ... {
    NSMutableArray *objects = [NSMutableArray array];
    va_list args;
    va_start(args, firstObject);
    for (NSString *object = firstObject; object != nil; object = va_arg(args, id)) {
        [objects addObject:object];
    }
    va_end(args);
    
    return [[self alloc] __initWithObjectsInArray:objects];
}

- (id)__initWithObjectsInArray:(NSArray *)objects {
    [self __setObjects:objects];
    return self;
}

- (NSMutableArray *)__objects {
    return _objects;
}

- (void)__setObjects:(NSMutableArray *)objects {
    _objects = (__bridge_transfer id)CFArrayCreateMutable(0, [objects count], &kPHFWeakArrayCallBacks);
    [_objects addObjectsFromArray:objects];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
	id object = [self __firstObjectRespondingToSelector:selector];
    if (!object)
        [NSException raise:NSInvalidArgumentException format:@"%@ was unable to handle %@ because none of the objects %.@ responds to it.", self, NSStringFromSelector(selector), _objects];
    return [object methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    // If the chain is breaking or if a method is non void, it will only be invoked on the first responding object.
    // Since void methods don't return anything, they have a return length of 0.
    if (_breaking || [[invocation methodSignature] methodReturnLength]) {
        id object = [self __firstObjectRespondingToSelector:[invocation selector]];
        [invocation setTarget:object];
        [invocation invoke];
    } else {
        NSArray *objects = [self __objectsRespondingToSelector:[invocation selector]];
        for (id object in objects) {
            [invocation setTarget:object];
            [invocation invoke];
        }
    }
}

- (BOOL)respondsToSelector:(SEL)selector {
    return [self __firstObjectRespondingToSelector:selector] != nil;
}

- (BOOL)conformsToProtocol:(Protocol *)protocol {
    for (id object in _objects)
        if ([object conformsToProtocol:protocol])
            return YES;
    return NO;
}

#pragma mark - Helpers

- (NSArray *)__objectsRespondingToSelector:(SEL)selector {
	NSIndexSet *indexes = [_objects indexesOfObjectsPassingTest:^BOOL(id object, NSUInteger index, BOOL *stop){
		return [object respondsToSelector:selector];
	}];
    
	return [_objects objectsAtIndexes:indexes];
}

- (id)__firstObjectRespondingToSelector:(SEL)selector {
	id object = nil;
    
	NSUInteger index = [_objects indexOfObjectPassingTest:^BOOL(id object, NSUInteger index, BOOL *stop){
		return [object respondsToSelector:selector];
	}];
    
	if (index != NSNotFound)
		object = [_objects objectAtIndex:index];
    
	return object;
}

@end