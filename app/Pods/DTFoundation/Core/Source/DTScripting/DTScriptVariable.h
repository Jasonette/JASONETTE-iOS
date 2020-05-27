//
//  DTScriptValue.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 10/18/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/**
 Class to represent a variable or parameter in a Objective-C scripting expression
 */
@interface DTScriptVariable : NSObject

/**
 Creates a new script variable with a given name and value
 @param name The name for the variable
 @param value The value for the variable
 */
+ (id)scriptVariableWithName:(NSString *)name value:(id)value;

/**
 The name of the receiver
 */
@property (nonatomic, copy) NSString *name;


/**
 The current value of the receiver
 */
@property (nonatomic, strong) id value;

@end
