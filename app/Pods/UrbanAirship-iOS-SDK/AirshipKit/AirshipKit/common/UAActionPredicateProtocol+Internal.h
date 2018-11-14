/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

/**
 * An internal protocol that defines the minimal functionality of a valid action predicate.
 */
@protocol UAActionPredicateProtocol <NSObject>

///---------------------------------------------------------------------------------------
/// @name Action Predicate Protocol Core Methods
///---------------------------------------------------------------------------------------

@required

/**
 * Applies predicate to action arguments to define the action's runnable
 * scope.
 *
 * @param args Action arguments.
 *
 * @return `YES` if action should run in the scope outlined by the action arguments, `NO` otherwise.
 */
- (BOOL)applyActionArguments:(UAActionArguments *)args;

@end
