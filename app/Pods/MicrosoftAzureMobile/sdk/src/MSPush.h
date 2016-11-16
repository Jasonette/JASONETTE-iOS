// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "MSBlockDefinitions.h"

@class MSClient;

#pragma  mark * MSClient Public Interface

@interface MSPush : NSObject

#pragma  mark * Public Initializer Methods

@property (nonatomic, strong, readonly, nonnull) MSClient *client;

///@name Initializing the MSPush Object
///@{

/// Initialize the *MSPush* instance with given *MSClient*
- (nonnull instancetype)initWithClient:(nonnull MSClient *)client;

/// @}

#pragma  mark * Public Native Registration Methods

/// @name Working with Registrations
/// @{

/// Gets the installation Id used to register the device with Notification Hubs.
@property (nonatomic, readonly, nonnull) NSString *installationId;

/// Register for notifications with given a deviceToken.
-(void)registerDeviceToken:(nonnull NSData *)deviceToken completion:(nullable MSCompletionBlock)completion;

/// Register for notifications with given deviceToken and a template.
-(void)registerDeviceToken:(nonnull NSData *)deviceToken template:(nullable NSDictionary *)template completion:(nullable MSCompletionBlock)completion;

/// Unregister device from all notifications.
-(void)unregisterWithCompletion:(nullable MSCompletionBlock)completion;

/// @}

@end
