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

@interface JasonLogger : NSObject
+ (void) setupWithLogLevel:(DTLogLevel) level;

@end

NS_ASSUME_NONNULL_END
