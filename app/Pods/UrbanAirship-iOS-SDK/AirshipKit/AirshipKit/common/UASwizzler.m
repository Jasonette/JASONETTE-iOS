/* Copyright 2017 Urban Airship and Contributors */

#import "UAGlobal.h"
#import "UASwizzler+Internal.h"
#import <objc/runtime.h>

@interface UASwizzler()
@property (nonatomic, assign) Class class;
@property (nonatomic, strong) NSMutableDictionary *originalMethods;
@end

@implementation UASwizzler

- (instancetype)initWithClass:(Class)class {
    self = [super init];

    if (self) {
        self.class = class;
        self.originalMethods = [NSMutableDictionary dictionary];
    }

    return self;
}

+ (instancetype)swizzlerForClass:(Class)class {
    return [[UASwizzler alloc] initWithClass:class];
}

- (void)swizzle:(SEL)selector protocol:(Protocol *)protocol implementation:(IMP)implementation {
    Method method = class_getInstanceMethod(self.class, selector);
    if (method) {
        UA_LDEBUG(@"Swizzling implementation for %@ class %@", NSStringFromSelector(selector), self.class);
        IMP existing = method_setImplementation(method, implementation);
        if (implementation != existing) {
            [self storeOriginalImplementation:existing selector:selector];
        }
    } else {
        struct objc_method_description description = protocol_getMethodDescription(protocol, selector, NO, YES);
        UA_LDEBUG(@"Adding implementation for %@ class %@", NSStringFromSelector(selector), self.class);
        class_addMethod(self.class, selector, implementation, description.types);
    }
}

- (void)swizzle:(SEL)selector implementation:(IMP)implementation {
    Method method = class_getInstanceMethod(self.class, selector);
    if (method) {
        UA_LDEBUG(@"Swizzling implementation for %@ class %@", NSStringFromSelector(selector), self.class);
        IMP existing = method_setImplementation(method, implementation);
        if (implementation != existing) {
            [self storeOriginalImplementation:existing selector:selector];
        }
    } else {
        UA_LDEBUG(@"Unable to swizzle method for %@ class %@, method not found.", NSStringFromSelector(selector), self.class);
    }
}

- (void)unswizzle {
    for (NSString *selectorString in [self.originalMethods allKeys]) {
        SEL selector = NSSelectorFromString(selectorString);
        Method method = class_getInstanceMethod(self.class, selector);
        IMP originalImplementation = [self originalImplementation:selector];

        if (originalImplementation) {
            UA_LDEBUG(@"Unswizzling implementation for %@ class %@", NSStringFromSelector(selector), self.class);
            method_setImplementation(method, originalImplementation);
        }
    }

    [self.originalMethods removeAllObjects];
}

- (void)storeOriginalImplementation:(IMP)implementation selector:(SEL)selector {
    NSString *selectorString = NSStringFromSelector(selector);
    self.originalMethods[selectorString] = [NSValue valueWithPointer:implementation];
}

- (IMP)originalImplementation:(SEL)selector {
    NSString *selectorString = NSStringFromSelector(selector);

    NSValue *value = self.originalMethods[selectorString];
    if (!value) {
        return nil;
    }

    IMP implementation;
    [value getValue:&implementation];
    return implementation;
}

@end
