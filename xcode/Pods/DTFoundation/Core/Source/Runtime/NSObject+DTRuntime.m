//
//  NSObject_DTRuntime.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 4/25/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <objc/runtime.h>
#import "DTObjectBlockExecutor.h"

@implementation NSObject (DTRuntime)

static char DTRuntimeDeallocBlocks;

#pragma mark - Blocks

- (void)addDeallocBlock:(void(^)(void))block
{
    // don't accept NULL block
    NSParameterAssert(block);
    
    NSMutableArray *deallocBlocks = objc_getAssociatedObject(self, &DTRuntimeDeallocBlocks);

    // add array of dealloc blocks if not existing yet
    if (!deallocBlocks)
    {
        deallocBlocks = [[NSMutableArray alloc] init];
        
        objc_setAssociatedObject(self, &DTRuntimeDeallocBlocks, deallocBlocks, OBJC_ASSOCIATION_RETAIN);
    }
    
    DTObjectBlockExecutor *executor = [DTObjectBlockExecutor blockExecutorWithDeallocBlock:block];
    
    [deallocBlocks addObject:executor];
}

+ (BOOL)addInstanceMethodWithSelectorName:(NSString *)selectorName block:(void(^)(id))block
{
    // don't accept nil name
    NSParameterAssert(selectorName);
    
    // don't accept NULL block
    NSParameterAssert(block);
    
    // See http://stackoverflow.com/questions/6357663/casting-a-block-to-a-void-for-dynamic-class-method-resolution

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_7
    void *impBlockForIMP = (void *)objc_unretainedPointer(block);
#else
    id impBlockForIMP = (__bridge id)(__bridge void *)(block);
#endif
    
    IMP myIMP = imp_implementationWithBlock(impBlockForIMP);
    
    SEL selector = NSSelectorFromString(selectorName);
    return class_addMethod(self, selector, myIMP, "v@:");
}

#pragma mark - Method Swizzling

+ (void)swizzleMethod:(SEL)selector withMethod:(SEL)otherSelector
{
	// my own class is being targetted
	Class myClass = [self class];
	
	// get the methods from the selectors
	Method originalMethod = class_getInstanceMethod(myClass, selector);
    Method otherMethod = class_getInstanceMethod(myClass, otherSelector);
	
    if (class_addMethod(myClass, selector, method_getImplementation(otherMethod), method_getTypeEncoding(otherMethod)))
	{
		class_replaceMethod(myClass, otherSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
	}
	else
	{
		method_exchangeImplementations(originalMethod, otherMethod);
	}
}

+ (void)swizzleClassMethod:(SEL)selector withMethod:(SEL)otherSelector
{
	// my own class is being targetted
	Class myClass = [self class];
	
	// get the methods from the selectors
	Method originalMethod = class_getClassMethod(myClass, selector);
    Method otherMethod = class_getClassMethod(myClass, otherSelector);
	
//    if (class_addMethod(c, selector, method_getImplementation(otherMethod), method_getTypeEncoding(otherMethod)))
//	{
//		class_replaceMethod(c, otherSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
//	}
//	else
//	{
		method_exchangeImplementations(originalMethod, otherMethod);
//	}

}

@end
