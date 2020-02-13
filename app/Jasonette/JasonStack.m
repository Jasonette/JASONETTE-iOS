//
//  JasonStack.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonStack.h"

@interface JasonStack ()

#pragma mark Properties

@end

@implementation JasonStack

#pragma mark Properties
- (NSMutableArray *)items {
	if (!_items) {
		_items = [[NSMutableArray alloc] init];
	}
	return _items;
}

#pragma mark Static Initializer
+ (id)stack {
    return [[JasonStack alloc] init];
}

#pragma mark Access methods
- (void)push:(id)object {
	if (object) {
		[self.items insertObject:object atIndex:0];
	}
}
- (id)pop {
	id object = nil;
    if ([self.items count] > 0) {
        object = [self.items objectAtIndex:0];
        [self.items removeObjectAtIndex:0];
    }
	return object;
}

#pragma mark Utilities
- (NSString *)description {
	return [self.items description];
}

@end
