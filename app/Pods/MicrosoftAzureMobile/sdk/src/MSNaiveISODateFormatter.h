// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>


#pragma mark * MSDateFormatter Public Interface


// An NSDateFormatter for a naive implementation of the ISO 8061 date format
// that uses the format string: yyyy-MM-dd'T'HH:mm:ss.SSS'Z'
@interface MSNaiveISODateFormatter : NSDateFormatter

// A singleton instance of the MSNaiveISODateFormatter.
+(MSNaiveISODateFormatter *)naiveISODateFormatter;
+(MSNaiveISODateFormatter *)naiveISODateNoFractionalSecondsFormatter;

@end
