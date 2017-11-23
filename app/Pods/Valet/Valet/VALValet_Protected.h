//
//  VALValet_Protected.h
//  Valet
//
//  Created by Dan Federman on 3/16/15.
//  Copyright 2015 Square, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Valet/VALValet.h>


extern NSString * __nonnull VALStringForAccessibility(VALAccessibility accessibility);
extern void VALAtomicSecItemLock(__nonnull dispatch_block_t block);


@interface VALValet ()

/// Ensures the atomicity for set and remove operations by limiting ourselves to one instance per configuration.
/// @return An existing valet object with the same configuration as the valet provided if one exists, or the passed in valet.
+ (nonnull id)sharedValetForValet:(nonnull VALValet *)valet;

/// Creates a base query given the injected properties. Do not override.
+ (nullable NSMutableDictionary *)mutableBaseQueryWithIdentifier:(nonnull NSString *)identifier accessibility:(VALAccessibility)accessibility initializer:(nonnull SEL)initializer;

/// Creates a base query for shared access group Valets given the injected properties. Do not override.
+ (nullable NSMutableDictionary *)mutableBaseQueryWithSharedAccessGroupIdentifier:(nonnull NSString *)sharedAccessGroupIdentifier accessibility:(VALAccessibility)accessibility initializer:(nonnull SEL)initializer;

/// Stores the root query to be used in all SecItem queries.
@property (nonnull, copy, readonly) NSDictionary *baseQuery;

- (BOOL)setObject:(nonnull NSData *)value forKey:(nonnull NSString *)key options:(nullable NSDictionary *)options;
- (nullable NSData *)objectForKey:(nonnull NSString *)key options:(nullable NSDictionary *)options status:(nullable inout OSStatus *)status;
- (BOOL)setString:(nonnull NSString *)string forKey:(nonnull NSString *)key options:(nullable NSDictionary *)options;
- (nullable NSString *)stringForKey:(nonnull NSString *)key options:(nullable NSDictionary *)options status:(nullable inout OSStatus *)status;
- (OSStatus)containsObjectForKey:(nonnull NSString *)key options:(nullable NSDictionary *)options;
- (nonnull NSSet *)allKeysWithOptions:(nullable NSDictionary *)options;
- (BOOL)removeObjectForKey:(nonnull NSString *)key options:(nullable NSDictionary *)options;
- (BOOL)removeAllObjectsWithOptions:(nullable NSDictionary *)options;

@end
