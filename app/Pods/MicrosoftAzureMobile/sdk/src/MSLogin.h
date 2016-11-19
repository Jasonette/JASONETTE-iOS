// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif
#import "MSBlockDefinitions.h"

@class MSClient;
@class MSLoginController;

NS_ASSUME_NONNULL_BEGIN

#pragma mark * MSLogin Public Interface


// The |MSLogin| class provides the login functionality for an |MSClient|
// instance.
@interface MSLogin : NSObject


#pragma mark * Public Readonly Properties


// The client associated with this |MSLogin|.
@property (nonatomic, weak, readonly, nullable) MSClient* client;


#pragma  mark * Public Initializer Methods


// Initializes a new instance of the |MSLogin|.
-(id)initWithClient:(MSClient *)client;


#pragma  mark * Public Login Methods

#if TARGET_OS_IPHONE
// Logs in the current end user with the given provider by presenting the
// MSLoginController with the given |controller|.
-(void)loginWithProvider:(NSString *)provider
              parameters:(nullable NSDictionary *)parameters
              controller:(UIViewController *)controller
                animated:(BOOL)animated
              completion:(nullable MSClientLoginBlock)completion;

// Returns an |MSLoginController| that can be used to log in the current
// end user with the given provider.
-(MSLoginController *)loginViewControllerWithProvider:(NSString *)provider
                                           parameters:(nullable NSDictionary *)parameters
                                           completion:(nullable MSClientLoginBlock)completion;

#endif

// Logs in the current end user with the given provider and the given token for
// the provider.
-(void)loginWithProvider:(NSString *)provider
                   token:(NSDictionary *)token
              completion:(nullable MSClientLoginBlock)completion;

// Refreshes access token with the identity provider for the logged in user.
-(void)refreshUserWithCompletion:(nullable MSClientLoginBlock)completion;

@end

NS_ASSUME_NONNULL_END
