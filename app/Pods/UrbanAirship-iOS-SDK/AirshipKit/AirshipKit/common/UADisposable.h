/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A block to be executed when a `UADisposable` is disposed.
 */
typedef void (^UADisposalBlock)(void);

/**
 * A convenience class for creating self-referencing cancellation tokens.
 *
 * @note: It is left up to the creator to determine what is disposed of and
 * under what circumstances.  This includes threading and memory management concerns.
 */
@interface UADisposable : NSObject

///---------------------------------------------------------------------------------------
/// @name Disposable Creation
///---------------------------------------------------------------------------------------

/**
 * Create a new disposable.
 *
 * @param disposalBlock A `UADisposalBlock` to be executed upon disposal.
 */
+ (instancetype)disposableWithBlock:(UADisposalBlock)disposalBlock;

///---------------------------------------------------------------------------------------
/// @name Disposable Remove
///---------------------------------------------------------------------------------------

/**
 * Dispose of associated resources.
 */
- (void)dispose;

@end

NS_ASSUME_NONNULL_END
