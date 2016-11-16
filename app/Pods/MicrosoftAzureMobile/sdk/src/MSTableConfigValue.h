// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MSConfigKeyTypes) {
    MSConfigKeyDeltaToken = 0
};

/// The *MSTableConfigValue* class represents internal configuration values used by the
/// sync operations to maintain state.
@interface MSTableConfigValue : NSObject

///@name Properties
///@{

/// Unique identifier for the config value
@property (nonatomic, copy) NSString *id;

/// The name of the table the config value is for
@property (nonatomic, copy) NSString *table;

/// The type of key
@property (nonatomic) MSConfigKeyTypes keyType;

/// The key
@property (nonatomic, copy) NSString *key;

/// The value
@property (nonatomic, copy) NSString *value;

///@}

/// @name Initializing the MSTableConfigValue Object
/// @{

/// Initializes the table config value from a serialized representation of a MSTableConfigValue.
- (id) initWithSerializedItem:(NSDictionary *)item;

///@}

/// @name Serializing the MSTableConfigValue Object
/// @{

/// Returns an NSDictionary with two keys, id and properties, where properties contains a serialized version
/// of the error
- (NSDictionary *) serialize;

/// @}
@end
