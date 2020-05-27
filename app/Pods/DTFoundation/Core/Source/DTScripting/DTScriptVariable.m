//
//  DTScriptValue.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 10/18/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTScriptVariable.h"

@implementation DTScriptVariable
{
	NSString *_name;
	id _value;
}

- (id)initWithName:(NSString *)name value:(id)value
{
	self = [super init];
	
	if (self)
	{
		_name = name;
		_value = value;
	}
	
	return self;
}


+ (id)scriptVariableWithName:(NSString *)name value:(id)value
{
	return [[DTScriptVariable alloc] initWithName:name value:value];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ name='%@' value=='%@'>", NSStringFromClass([self class]), _name, _value];
}

#pragma mark - Properties

@synthesize name = _name;
@synthesize value = _value;

@end
