/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAActionArguments.h"

/**
 * Model object representing a binding between an in-app
 * message button, a localized title and action name/argument pairs.
 */
@interface UAInAppMessageButtonActionBinding : NSObject

///---------------------------------------------------------------------------------------
/// @name In App Message Button Action Binding Properties
///---------------------------------------------------------------------------------------

/**
 * The title of the button.
 */
@property(nonatomic, copy, nullable) NSString *title;

/**
 * The button's identifier.
 */
@property(nonatomic, copy, nullable) NSString *identifier;
/**
 * A dictionary mapping action names to action values, to
 * be run when the button is pressed.
 */
@property(nonatomic, copy, nullable) NSDictionary *actions;

/**
 * The action's situation.
 */
@property (nonatomic, assign) UASituation situation;

@end
