/* Copyright 2017 Urban Airship and Contributors */

#import "UAActionArguments.h"

NS_ASSUME_NONNULL_BEGIN

/*
 * SDK-private extensions to UAActionArguments
 */
@interface UAActionArguments ()

///---------------------------------------------------------------------------------------
/// @name Action Arguments Internal Properties
///---------------------------------------------------------------------------------------

/**
 * The action argument's situation string.
 */
@property (nonatomic, readonly) NSString *situationString;

/**
 * The action argument's metadata.
 */
@property (nonatomic, copy, nullable) NSDictionary *metadata;

/**
 * The action argument's situation.
 */
@property (nonatomic, assign) UASituation situation;

/**
 * The action argument's value.
 */
@property (nonatomic, strong, nullable) id value;

@end

NS_ASSUME_NONNULL_END
