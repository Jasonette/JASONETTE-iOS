//
//  NBRegularExpressionCache.h
//  libPhoneNumber
//
//  Created by Paween Itthipalkul on 11/29/17.
//  Copyright © 2017 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NBRegularExpressionCache : NSObject

/**
 Returns a singleton instance of the regular expression cache.

 @return An instance of NBRegularExpressionCache
 */
+ (instancetype)sharedInstance;

/**
 Returns compiled regular expression for a given pattern.

 @param pattern Regular expression pattern.
 @param error If an error occurs, upon returns contains an NSError object that describes
              the problem. If you are not interested in possible errors, pass in NULL.
 @return A regular expression.
 */
- (nullable NSRegularExpression *)regularExpressionForPattern:(NSString *)pattern
                                                        error:(NSError * _Nullable *)error;

@end

NS_ASSUME_NONNULL_END
