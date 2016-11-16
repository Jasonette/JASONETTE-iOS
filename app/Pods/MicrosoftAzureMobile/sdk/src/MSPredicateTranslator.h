// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>


#pragma mark * MSPredicateTranslator Public Interface


// The |MSPredicateTranslator| traverses the abstract syntax tree of an
// |NSPredicate| instance and builds the filter portion of a query string.
@interface MSPredicateTranslator : NSObject

// Returns the filter portion of a query string translated from the
// given |NSPRedicate|. Will return a nil value and a non-nil error if the
// predicate is not supported.
+(NSString *)queryFilterFromPredicate:(NSPredicate *)predicate
                              orError:(NSError **)error;

@end
