//
//  DTScriptExpression.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 10/17/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTScriptExpression.h"
#import "DTScriptVariable.h"
#import "NSScanner+DTScripting.h"
#import "DTLog.h"


@implementation DTScriptExpression
{
	NSArray *_parameters;
	NSArray *_parameterNames;
	DTScriptVariable *_receiver;
	SEL _selector;
}

+ (DTScriptExpression *)scriptExpressionWithString:(NSString *)string
{
	return [[DTScriptExpression alloc] initWithString:string];
}

- (id)initWithString:(NSString *)string
{
	self = [super init];
	
	if (self)
	{
		if (![self _parseString:string])
		{
			return nil;
		}
	}
	
	return self;
}

- (NSString *)description
{
	NSMutableString *retStr = [NSMutableString string];
	
	[retStr appendString:@"["];
	[retStr appendString:_receiver.name];
	[retStr appendString:@" "];
	
	NSMutableString *parameterStr = [NSMutableString string];
	
	if ([_parameters count])
	{
		[self enumerateParametersWithBlock:^(NSString *name, DTScriptVariable *variable, BOOL *stop) {
			if ([parameterStr length])
			{
				[parameterStr appendString:@" "];
			}
			
			NSString *variableText = nil;
			
			if (variable.value)
			{
				if ([variable.value isKindOfClass:[NSString class]])
				{
					variableText = [NSString stringWithFormat:@"@\"%@\"", variable.value];
				}
				else if ([variable.value isKindOfClass:[NSNull class]])
				{
					variableText = @"nil";
				}
				else if ([variable.value isKindOfClass:[NSDecimalNumber class]])
				{
					variableText = [variable.value description];
				}
				else if ([variable.value isKindOfClass:[NSNumber class]])
				{
					BOOL b = [variable.value boolValue];
					
					variableText = b?@"YES":@"NO";
				}
			}
			else
			{
				variableText = variable.name;
			}
			
			[parameterStr appendFormat:@"%@:%@", name, variableText];
		}];
	}
	else
	{
		[retStr appendString:NSStringFromSelector(_selector)];
	}
	
	[retStr appendString:parameterStr];
	[retStr appendString:@"]"];
	
	return retStr;
}

- (BOOL)_parseString:(NSString *)string
{
	NSScanner *scanner = [[NSScanner alloc] initWithString:string];
	
	NSMutableArray *paramArray = [NSMutableArray array];
	NSMutableArray *paramNameArray = [NSMutableArray array];
	
	NSMutableString *selector = [NSMutableString string];
	
	if (![scanner scanString:@"[" intoString:nil])
	{
		DTLogError(@"No [ at position %d in string '%@'", (int)[scanner scanLocation], string);
		return NO;
	}
	
	DTScriptVariable *receiver = nil;
	
	if (![scanner scanScriptVariable:&receiver])
	{
		DTLogError(@"No receiver at position %d in string '%@'", (int)[scanner scanLocation], string);
		return NO;
	}

	// store receiver variable for later resolving
	_receiver = receiver;
	
	NSString *method = nil;
	if (![scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&method])
	{
		DTLogError(@"No method name at position %d in string '%@'", (int)[scanner scanLocation], string);
		return NO;
	}
	
	[selector appendString:method];
	
	[paramNameArray addObject:method];
	
	// decide, either the method has no parameters, then there is a ] or there is a :
	
	NSString *decider = nil;
	if (![scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@":]"] intoString:&decider])
	{
		DTLogError(@"No ] or : at position %d in string '%@'", (int)[scanner scanLocation], string);
		return NO;
	}
	
	if ([decider isEqualToString:@":"])
	{
		[selector appendString:@":"];
		
		DTScriptVariable *parameter = nil;
		
		if ([scanner scanScriptVariable:&parameter])
		{
			[paramArray addObject:parameter];
		}
			
		// either a new parameter name, or a ]
		
		NSString *parameterName = nil;
		
		if ([scanner scanString:@"]" intoString:nil])
		{
			// done
		}
		else
		{
			while (![scanner isAtEnd] && ![scanner scanString:@"]" intoString:nil])
			{
				if ([scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&parameterName])
				{
					[selector appendString:parameterName];
					
					[paramNameArray addObject:parameterName];
					
					// additional parameters HAVE to have a colon and parameter
					
					if (![scanner scanString:@":" intoString:nil])
					{
						DTLogError(@"No : at position %d in string '%@'", (int)[scanner scanLocation], self);
						return NO;
					}
					
					[selector appendString:@":"];
					
					DTScriptVariable *variable = nil;
					
					if ([scanner scanScriptVariable:&variable])
					{
						[paramArray addObject:variable];
					}
					else
					{
						DTLogError(@"Illegal character in parameter at position %d in string '%@'", (int)[scanner scanLocation], string);
						return NO;
					}
				}
				else
				{
					DTLogError(@"Illegal character in parameter at position %d in string '%@'", (int)[scanner scanLocation], string);
					return NO;
				}
			}
		}
	}
	
	// store selector string
	_selector = NSSelectorFromString(selector);
	
	// store params
	_parameters = paramArray;
	_parameterNames = paramNameArray;
	
	return YES;
}

- (void)enumerateParametersWithBlock:(DTScriptExpressionParameterEnumerationBlock)block
{
	for (NSUInteger i=0; i<[_parameters count]; i++)
	{
		NSString *name = [_parameterNames objectAtIndex:i];
		DTScriptVariable *variable = [_parameters objectAtIndex:i];
		
		BOOL stop = NO;

		block(name, variable, &stop);
		
		if (stop)
		{
			break;
		}
	}
}

#pragma mark - Properties

- (SEL)selector
{
	return _selector;
}

@synthesize parameters = _parameters;
@synthesize receiver = _receiver;

@end
