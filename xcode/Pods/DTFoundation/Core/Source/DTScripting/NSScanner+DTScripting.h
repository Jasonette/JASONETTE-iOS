//
//  NSScanner+DTScripting.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 10/18/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

@class DTScriptVariable;

/**
 Category for `NSScanner` to deal with Objective-C script
 */
@interface NSScanner (DTScripting)

/**
 Attempts to scan at the current scan location for a script expression. 
 
 Script Expressions can be, an NSString, nil, a number, a boolean, or a variable name
 @param variable Output parameter to receive a scanned script variable
 @returns `YES` if successful
 */
- (BOOL)scanScriptVariable:(DTScriptVariable **)variable;

@end
