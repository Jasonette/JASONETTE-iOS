/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Defines analytics identifiers to be associated with
 * the device.
 */
@interface UAAssociatedIdentifiers : NSObject

/**
 * Maximum number of associated IDs that can be set.
 */
extern NSUInteger const UAAssociatedIdentifiersMaxCount;

/**
 * Character limit for associated IDs or keys.
 */
extern NSUInteger const UAAssociatedIdentifiersMaxCharacterCount;

///---------------------------------------------------------------------------------------
/// @name Associated Identifiers Properties
///---------------------------------------------------------------------------------------

/**
 * The advertising ID.
 */
@property (nonatomic, copy, nullable) NSString *advertisingID;

/**
 * The application's vendor ID.
 */
@property (nonatomic, copy, nullable) NSString *vendorID;

/**
 * Indicates whether the user has limited ad tracking.
 */
@property (nonatomic, assign) BOOL advertisingTrackingEnabled;

/**
 * A map of all the associated identifiers.
 */
@property (nonatomic, readonly) NSDictionary *allIDs;

///---------------------------------------------------------------------------------------
/// @name Associated Identifiers Factories
///---------------------------------------------------------------------------------------

/**
 * Factory method to create an empty identifiers object.
 * @return The created associated identifiers.
 */
+ (instancetype)identifiers;


/**
 * Factory method to create an associated identifiers instance with a dictionary
 * of custom identifiers (containing strings only).
 * @return The created associated identifiers.
 */
+ (instancetype)identifiersWithDictionary:(NSDictionary<NSString *, NSString *> *)identifiers;

///---------------------------------------------------------------------------------------
/// @name Associated Identifiers Mapping
///---------------------------------------------------------------------------------------

/**
 * Sets an identifier mapping.
 * @param identifier The value of the identifier, or `nil` to remove the identifier.
 * @parm key The key for the identifier
 */
- (void)setIdentifier:(nullable NSString *)identifier forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
