//
//  JasonOptionHelper.h
//  Jasonette
//
//  Created by Camilo Castro <camilo@ninjas.cl> on 18-02-17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 *  @brief Provides Helper Methods for Interacting with the Options Dictionary
 *  @discussion
 *
 *  Example Usage (Inside an JasonAction class):
 *
 *  // self.options is provided as subclass property
 *  JasonOptionHelper * options = [[JasonOptionHelper alloc]
 *                                      initWithOptions:self.options];
 *
 *  if ([options hasParam:@"date"])
 *  {
 *      NSString * dateIn = [options getString:@"date"];
 *
 *      NSString * formatIn = [options
 *                              getStringWithKeyNames:@[
 *                              @"format",
 *                              @"format_in",
 *                              @"formatIn"]];
 *  }
 */
@interface JasonOptionHelper : NSObject

/*!
 *  @brief Original Options Dictionary used in the Initializer
 */
@property (nonatomic, nonnull) NSDictionary * options;

/*!
 *  @brief Designated Initializer
 *
 *  @param options Dictionary with the params
 *
 *  @return JasonOptionHelper instance
 */
- (nonnull instancetype) initWithOptions:(nonnull NSDictionary *) options;

/*!
 *  @brief Check if an array of Keys exists in the Option Dictionary
 *
 *  @param params Array with the Key Names
 *
 *  @return YES if all the keys provided exists. NO otherwise.
 */
- (BOOL) hasParams:(nonnull NSArray<NSString *> *) params;

/*!
 *  @brief Check if the Key exists in the Option Dictionary
 *
 *  @param params Single Key Name
 *
 *  @return YES if the key provided exists. NO otherwise.
 */
- (BOOL) hasParam:(nonnull NSString *) param;

/*!
 *  @brief Get a generic object inside the options dictionary
 *
 *  @param key identifier for the key inside the dictionary
 *
 *  @return generic object or nil
 */
- (nullable id) get: (nonnull NSString *) key;

/*!
 *  @brief Get a generic object inside the options dictionary
 *  that could be named with multiple keys. Like keyOne or key_one.
 *
 *  @param keys array of identifiers for the key inside the dictionary
 *
 *  @return generic object or nil
 */
- (nullable id) getWithKeys: (nonnull NSArray <NSString *> *) keys;

/*!
 *  @brief Get a string object inside the options dictionary
 *
 *  @param key identifier for the key inside the dictionary
 *
 *  @return string object or nil
 */
- (nullable NSString *) getString:(nonnull NSString *) key;

/*!
 *  @brief Get a string object inside the options dictionary.
 *  If the string contains no chars or only whitespace and newline chars it will return nil.
 *
 *  @param key identifier for the key inside the dictionary
 *
 *  @return string object or nil
 */
- (nullable NSString *) getStringWithEmptyAsNil:(nonnull NSString *) key;

/*!
 *  @brief Get a string object inside the options dictionary
 *  that could be named with multiple keys. Like keyOne or key_one.
 *
 *  @param keys array of identifiers for the key inside the dictionary
 *
 *  @return string object or nil
 */
- (nullable NSString *) getStringWithKeyNames:(nonnull NSArray<NSString *> *) keys;

/*!
 *  @brief Get a string object inside the options dictionary
 *  that could be named with multiple keys. Like keyOne or key_one.
 *  If the string contains no chars or only whitespace and newline chars it will return nil.
 *
 *  @param keys array of identifiers for the key inside the dictionary
 *
 *  @return string object or nil.
 */
- (nullable NSString *) getStringWithKeyNamesWithEmptyAsNil:(nonnull NSArray<NSString *> *) keys;

/*!
 *  @brief Get a dictionary object inside the options dictionary
 *
 *  @param key identifier for the key inside the dictionary
 *
 *  @return dictionary object or nil
 */
- (nullable NSDictionary *) getDict: (nonnull NSString *) key;

/*!
 *  @brief Get a dictionary object inside the options dictionary
 *  that could be named with multiple keys. Like keyOne or key_one.
 *
 *  @param keys array of identifiers for the key inside the dictionary
 *
 *  @return dictionary object or nil
 */
- (nullable NSDictionary *) getDictWithKeyNames:(nonnull NSArray<NSString *> *) keys;


/*!
 *  @brief Get a number object inside the options dictionary
 *  that could be named with multiple keys. Like keyOne or key_one.
 *
 *  @param key identifier for the key inside the dictionary
 *
 *  @return number object or nil
 */
- (nullable NSNumber *) getNumber: (nonnull NSString *) key;

/*!
 *  @brief Get a number object inside the options dictionary
 *  that could be named with multiple keys.Like keyOne or key_one.
 *
 *  @param keys array of identifiers for the key inside the dictionary
 *
 *  @return number object or nil
 */
- (nullable NSNumber *) getNumberWithKeyNames:(nonnull NSArray<NSString *> *) keys;

/*!
 *  @brief Get a boolean inside the options dictionary.
 *
 *  @param key identifier for the key inside the dictionary
 *
 *  @return YES or NO
 */
- (BOOL) getBoolean: (nonnull NSString *) key;

/*!
 *  @brief Get a boolean inside the options dictionary
 *  that could be named with multiple keys.Like keyOne or key_one.
 *
 *  @param keys array of identifiers for the key inside the dictionary
 *
 *  @return YES or NO
 */
- (BOOL) getBooleanWithKeyNames:(nonnull NSArray<NSString *> *) keys;

@end
