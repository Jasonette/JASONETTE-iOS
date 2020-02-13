//
//  UIWebView+DTFoundation.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 25.05.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/**
 Some convenient functions that can be also achieved if you know JavaScript, but are way more easy to remember like this.
 */

@interface UIWebView (DTFoundation)

/**
 Getting the current document's title
 @returns A string with the document title
 */
- (NSString *)documentTitle;

@end
