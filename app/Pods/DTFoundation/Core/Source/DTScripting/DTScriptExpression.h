//
//  DTScriptExpression.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 10/17/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTScriptVariable.h"

typedef void (^DTScriptExpressionParameterEnumerationBlock) (NSString *paramName, DTScriptVariable *variable, BOOL *stop);

/**
 Instances of this class represent a single Objective-C script expression
 */

@interface DTScriptExpression : NSObject


/**
 Creates a script expression from an `NSString`
 @param string A string representing an Object-C command including square brackets.
 */
+ (DTScriptExpression *)scriptExpressionWithString:(NSString *)string;

/**
 Creates a script expression from an `NSString`
 @param string A string representing an Object-C command including square brackets.
 */
- (id)initWithString:(NSString *)string;

/**
 The parameters of the script expression
 */
@property (nonatomic, readonly) NSArray *parameters;

/**
 Enumerates the script parameters and executes the block for each parameter.
 @param block The block to be executed for each parameter
 */
- (void)enumerateParametersWithBlock:(DTScriptExpressionParameterEnumerationBlock)block;

/**
 Accesses the receiver of the expression
 */
@property (nonatomic, readonly) DTScriptVariable *receiver;

/**
 The method selector
 */
- (SEL)selector;

@end
