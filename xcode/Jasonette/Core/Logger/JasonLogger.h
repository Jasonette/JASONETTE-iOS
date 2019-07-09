//
//  JasonLogger.h
//  Jasonette
//
//  Created by Jasonelle Team on 04-07-19.
//  Copyright © 2019 Jasonette. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DTFoundation/DTLog.h>

NS_ASSUME_NONNULL_BEGIN

/*! This acts as a wrapper to DTLog.h
 */
@interface JasonLogger : NSObject

+ (void)setupWithLogLevel:(DTLogLevel)level;

+ (void)setLogLevel:(DTLogLevel)level;
+ (void)setHandler:(nonnull DTLogBlock)handler;

+ (void)setupWithLogLevelDebug;
+ (void)setupWithLogLevelInfo;
+ (void)setupWithLogLevelWarning;
+ (void)setupWithLogLevelError;

@end

NS_ASSUME_NONNULL_END
