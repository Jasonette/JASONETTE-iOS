//
//  DTAlertView.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 11/22/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTAlertView.h"
#import "DTLog.h"

#if !TARGET_OS_TV  && __IPHONE_OS_VERSION_MIN_REQUIRED < 80000
@interface DTAlertView() <UIAlertViewDelegate>

@end

@implementation DTAlertView
{
	NSMutableDictionary *_actionsPerIndex;

	DTAlertViewBlock _cancelBlock;
}

- (void)dealloc
{
	[super setDelegate:nil];
	self.alertViewDelegate = nil;
}

// designated initializer
- (id)init
{
    self = [super init];
    if (self)
    {
        _actionsPerIndex = [[NSMutableDictionary alloc] init];
        [super setDelegate:self];
    }
    return self;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message
{
    return [self initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
	self = [self init];
	if (self)
	{
        self.title = title;
        self.message = message;
        
        if (otherButtonTitles != nil) {
            [self addButtonWithTitle:otherButtonTitles];
            va_list args;
            va_start(args, otherButtonTitles);
            NSString *title = nil;
            while( (title = va_arg(args, NSString *)) ) {
                [self addButtonWithTitle:title];
            }
            va_end(args);
        }
        if (cancelButtonTitle) {
            [self addCancelButtonWithTitle:cancelButtonTitle block:nil];
        }
        
        self.alertViewDelegate = delegate;
	}
	return self;
}

- (NSInteger)addButtonWithTitle:(NSString *)title block:(DTAlertViewBlock)block
{
	NSInteger retIndex = [self addButtonWithTitle:title];

	if (block)
	{
		NSNumber *key = [NSNumber numberWithInteger:retIndex];
		[_actionsPerIndex setObject:[block copy] forKey:key];
	}

	return retIndex;
}

- (NSInteger)addCancelButtonWithTitle:(NSString *)title block:(DTAlertViewBlock)block
{
	NSInteger retIndex = [self addButtonWithTitle:title block:block];
	[self setCancelButtonIndex:retIndex];

	return retIndex;
}

- (void)setCancelBlock:(DTAlertViewBlock)block
{
	_cancelBlock = block;
}

# pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSNumber *key = [NSNumber numberWithInteger:buttonIndex];
    
	DTAlertViewBlock block = [_actionsPerIndex objectForKey:key];
	if (block)
	{
		block();
	}

	if ([self.alertViewDelegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)])
	{
		[self.alertViewDelegate alertView:self clickedButtonAtIndex:buttonIndex];
	}
}

- (void)alertViewCancel:(UIAlertView *)alertView
{
	if (_cancelBlock)
	{
		_cancelBlock();
	}

	if ([self.alertViewDelegate respondsToSelector:@selector(alertViewCancel:)])
	{
		[self.alertViewDelegate alertViewCancel:self];
	}
}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
	if ([self.alertViewDelegate respondsToSelector:@selector(willPresentAlertView:)])
	{
		[self.alertViewDelegate willPresentAlertView:self];
	}
}

- (void)didPresentAlertView:(UIAlertView *)alertView
{
	if ([self.alertViewDelegate respondsToSelector:@selector(didPresentAlertView:)])
	{
		[self.alertViewDelegate didPresentAlertView:self];
	}
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if ([self.alertViewDelegate respondsToSelector:@selector(alertView:willDismissWithButtonIndex:)])
	{
		[self.alertViewDelegate alertView:self willDismissWithButtonIndex:buttonIndex];
	}
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if ([self.alertViewDelegate respondsToSelector:@selector(alertView:didDismissWithButtonIndex:)])
	{
		[self.alertViewDelegate alertView:self didDismissWithButtonIndex:buttonIndex];
	}
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
	if ([self.alertViewDelegate respondsToSelector:@selector(alertViewShouldEnableFirstOtherButton:)])
	{
		return [self.alertViewDelegate alertViewShouldEnableFirstOtherButton:self];
	}

	return YES;
}


#pragma mark - Properties


- (void)setDelegate:(id <UIAlertViewDelegate>)delegate
{
	if (delegate)
	{
		DTLogWarning(@"Calling setDelegate is not supported! Use setAlertViewDelegate instead");
	}
}

@end
#endif
